//
//  XcodebuildRunner.swift
//  CucumberSwiftMutation
//

import Foundation

/// Builds an Xcode project or workspace with `xcodebuild build-for-testing`, with code coverage on, and tests it
/// with `xcodebuild test-without-building`. A scheme and a destination say what to build and where to run it.
///
/// CucumberSwift's settings reach the tests as `TEST_RUNNER_`-prefixed variables in `xcodebuild`'s environment, which it
/// passes to the test process without the prefix. A `TEST_RUNNER_` build setting on the command line (`TEST_RUNNER_X=y`)
/// doesn't reach the tests: Xcode 26.4 ran them without it. The test count comes from each run's result bundle, so a
/// run in which Xcode ran no test is a run of 0 tests, whatever Xcode printed.
///
/// A run of some scenarios sets `CUCUMBER_SCENARIOS`, as every runner does, so CucumberSwift runs only those. With the
/// names of the test targets, it also turns on a test per scenario (`CUCUMBER_ONE_TEST_PER_SCENARIO`) and selects the
/// tests with `-only-testing`, which keeps Xcode from starting a test bundle that has none of them: with a test per step,
/// the default, the test classes exist only while the bundle runs, and `-only-testing` selects none of them.
public final class XcodebuildRunner: TestRunner, @unchecked Sendable {
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    /// What to build and test.
    public struct Target: Equatable, Sendable {
        /// The `.xcodeproj` or `.xcworkspace`, relative to the project folder.
        public var container: String
        public var scheme: String
        /// The `-destination` value, such as `platform=macOS`.
        public var destination: String
        /// The test targets that hold the scenarios, such as `VotingTests`, for `-only-testing`.
        public var testTargets: [String]
        /// More arguments for every `xcodebuild`, such as `-skipPackagePluginValidation`.
        public var arguments: [String]

        var isWorkspace: Bool { container.hasSuffix(".xcworkspace") }

        public init(container: String, scheme: String, destination: String, testTargets: [String] = [], arguments: [String] = []) {
            self.container = container
            self.scheme = scheme
            self.destination = destination
            self.testTargets = testTargets
            self.arguments = arguments
        }
    }

    private let target: Target
    private let xcodebuild: String
    private let xcrun: String
    private let commands: CommandRunning
    /// The tool's environment. Its `CUCUMBER_*` variables reach the tests, as they do with SwiftPM, where the tests
    /// inherit the tool's environment.
    private let environment: [String: String]
    private let lock = NSLock()
    private var runs = 0

    /// `totalTestCount` of the summary that `xcresulttool get test-results summary` prints.
    static func testCount(inSummary json: String) -> Int {
        guard let data = json.data(using: .utf8),
              let summary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let total = summary["totalTestCount"] as? Int else { return 0 }
        return total
    }

    public init(
        target: Target,
        xcodebuild: String = "/usr/bin/xcodebuild",
        xcrun: String = "/usr/bin/xcrun",
        commands: CommandRunning = ProcessRunner(),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.environment = environment
        self.target = target
        self.xcodebuild = xcodebuild
        self.xcrun = xcrun
        self.commands = commands
    }

    public func prepare(copy: URL) throws {
        guard FileManager.default.fileExists(atPath: copy.appendingPathComponent(target.container).path) else {
            throw Failure(description: "\(copy.path) has no \(target.container)")
        }
        _ = try makeFolder(runnerFolder(for: copy))
    }

    /// The arguments every `xcodebuild` action gets: what to build, where, and the folder for the build products,
    /// which every mutant's build reuses, so that Xcode rebuilds only the target the mutant changed.
    private func common(in copy: URL) -> [String] {
        let container = target.isWorkspace ? "-workspace" : "-project"
        return [
            container, target.container,
            "-scheme", target.scheme,
            "-destination", target.destination,
            "-derivedDataPath", runnerFolder(for: copy).appendingPathComponent("DerivedData").path,
            "-skipMacroValidation", "-skipPackagePluginValidation"
        ] + target.arguments
    }

    public func build(in copy: URL, timeout: TimeInterval?) -> BuildResult {
        let arguments = ["build-for-testing"] + common(in: copy) + ["-enableCodeCoverage", "YES", "CODE_SIGNING_ALLOWED=NO"]
        let result = commands.run(xcodebuild, arguments, in: copy, environment: [:], timeout: timeout)
        return BuildResult(succeeded: result.succeeded, duration: result.duration, log: write(result.output, named: "build", in: copy))
    }

    public func test(in copy: URL, request: TestRequest) -> TestRun {
        let folder = runnerFolder(for: copy)
        let number = nextRun()
        var settings = environment.filter { $0.key.hasPrefix("CUCUMBER_") }
        settings.merge(request.settings) { _, new in new }
        let coverage = request.measuresCoverage ? folder.appendingPathComponent("coverage-\(number)") : nil
        if let coverage {
            settings["CUCUMBER_COVERAGE"] = "YES"
            settings["CUCUMBER_COVERAGE_PATH"] = coverage.path
        }
        settings.merge(request.scenarioSettings) { _, new in new }
        var identifiers: [String]?
        if let scenarios = request.scenarios, !target.testTargets.isEmpty {
            do {
                let selection = try onlyTesting(scenarios, in: copy)
                identifiers = selection.identifiers
                if selection.testPerScenario { settings["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES" }
            } catch {
                return TestRun(status: 1, log: write("error: \(error)\n", named: "test-\(number)", in: copy))
            }
        }
        // Each test bundle runs in a process of its own, and the processes write one report, the last replacing the
        // others. So a project with several test targets gets an `xcodebuild` run for each, and their reports are merged.
        let groups = testTargetGroups(for: request.scenarios, in: copy)
        var runs = [(result: CommandResult, report: URL?, tests: Int)]()
        for (index, group) in groups.enumerated() {
            let name = groups.count > 1 ? "\(number)-\(index + 1)" : "\(number)"
            var runSettings = settings
            var report: URL?
            if request.writesReport {
                report = folder.appendingPathComponent("reports/report-\(name).json")
                runSettings["CUCUMBER_REPORT_PATH"] = report?.path
            }
            let bundle = folder.appendingPathComponent("results/test-\(name).xcresult")
            var arguments = ["test-without-building"] + common(in: copy)
            arguments += ["-resultBundlePath", bundle.path, "-enableCodeCoverage", "YES", "CODE_SIGNING_ALLOWED=NO"]
            // A failing test, which is how a mutant dies, makes xcodebuild collect diagnostics, such as log archives, for about
            // 20 seconds longer than a passing run takes. The run needs the result bundle and the report, not those.
            arguments += ["-collect-test-diagnostics", "never"]
            arguments += onlyTestingArguments(for: group, identifiers: identifiers, selectsTargets: !target.testTargets.isEmpty)
            // The prefixed variables are how xcodebuild gives the tests a setting.
            var prefixed = [String: String]()
            for (key, value) in runSettings { prefixed["TEST_RUNNER_\(key)"] = value }
            let result = commands.run(xcodebuild, arguments, in: copy, environment: prefixed, timeout: request.timeout)
            runs.append((result, report, testsRun(inBundle: bundle, in: copy)))
        }
        let reports = runs.compactMap(\.report).filter { FileManager.default.fileExists(atPath: $0.path) }
        return TestRun(
            status: runs.map(\.result.status).first { $0 != 0 } ?? 0,
            timedOut: runs.contains { $0.result.timedOut },
            duration: runs.map(\.result.duration).reduce(0, +),
            testsRun: runs.map(\.tests).reduce(0, +),
            log: write(combinedOutput(of: zip(groups, runs.map(\.result)).map { ($0.joined(separator: ", "), $1) }), named: "test-\(number)", in: copy),
            cucumberReport: reports.count > 1 ? mergedReport(reports, named: "report-\(number).json", in: folder) : reports.first,
            coverageFolder: coverage.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        )
    }

    /// The test targets to run, a group for each `xcodebuild` run: one run for all of them, or one for each of several
    /// targets. A target that holds none of the scenarios is left out: its run would start `xcodebuild` to run no test,
    /// which takes seconds.
    private func testTargetGroups(for scenarios: [ScenarioID]?, in copy: URL) -> [[String]] {
        guard target.testTargets.count > 1 else { return [target.testTargets] }
        let targets = scenarios.map { testTargets(holding: $0, in: copy) } ?? target.testTargets
        return targets.map { [$0] }
    }

    /// The test targets that can run one of `scenarios`: the ones whose built bundle holds the scenario's feature file, in
    /// the order of the target's test targets. A target whose bundle isn't found is kept, because it may hold one, and
    /// so is every target when none of them holds any, so that a run never skips all of them.
    private func testTargets(holding scenarios: [ScenarioID], in copy: URL) -> [String] {
        let bundles = builtBundles(in: copy)
        let holding = target.testTargets.filter { name in
            guard let bundle = bundles[name] else { return true }
            return scenarios.contains { scenario in
                [bundle, bundle.appendingPathComponent("Contents/Resources")].contains { root in
                    FileManager.default.fileExists(atPath: root.appendingPathComponent(scenario.feature).path)
                }
            }
        }
        return holding.isEmpty ? target.testTargets : holding
    }

    /// The `.xctest` bundles that `build-for-testing` made, by the target's name. A test target can be inside a host app,
    /// so the whole products folder is searched, without looking inside a bundle.
    private func builtBundles(in copy: URL) -> [String: URL] {
        let products = runnerFolder(for: copy).appendingPathComponent("DerivedData/Build/Products")
        guard let enumerator = FileManager.default.enumerator(at: products, includingPropertiesForKeys: nil) else { return [:] }
        var bundles = [String: URL]()
        for case let url as URL in enumerator where url.pathExtension == "xctest" {
            enumerator.skipDescendants()
            bundles[url.deletingPathExtension().lastPathComponent] = url
        }
        return bundles
    }

    /// What the runs printed: one run's output as it is, and several runs' each under the name of its test target.
    private func combinedOutput(of results: [(testTarget: String, result: CommandResult)]) -> String {
        guard results.count > 1 else { return results.first?.result.output ?? "" }
        let sections = results.map { "== test target \($0.testTarget) ==\n\($0.result.output)" }
        return sections.joined(separator: "\n")
    }

    /// The Cucumber reports of several runs as one report: each is a JSON array of features, so the merge is one array.
    private func mergedReport(_ reports: [URL], named name: String, in folder: URL) -> URL? {
        var features = [Any]()
        for report in reports {
            if let data = try? Data(contentsOf: report), let array = try? JSONSerialization.jsonObject(with: data) as? [Any] { features += array }
        }
        let merged = folder.appendingPathComponent("reports/\(name)")
        guard let data = try? JSONSerialization.data(withJSONObject: features) else { return nil }
        return (try? data.write(to: merged)) == nil ? nil : merged
    }

    /// The `-only-testing` arguments of a run of the test targets in `group`: each of `identifiers` in each target, because a
    /// scenario doesn't say which target holds it, and `xcodebuild` ignores an identifier that a target doesn't have. With no
    /// identifiers, a run of a named target selects it, so that `--test-target` limits the run to the targets it names, and
    /// a run with no test target named selects nothing.
    private func onlyTestingArguments(for group: [String], identifiers: [String]?, selectsTargets: Bool) -> [String] {
        guard let identifiers else { return selectsTargets ? group.flatMap { ["-only-testing", $0] } : [] }
        var seen = Set<String>()
        return group.flatMap { testTarget in
            identifiers.filter { seen.insert("\(testTarget)/\($0)").inserted }.flatMap { ["-only-testing", "\(testTarget)/\($0)"] }
        }
    }

    /// The identifiers, below their test target, of the tests that run `scenarios`. A scenario of the XCTest runner is the
    /// test `CucumberScenarioTest/<feature › scenario>`, with a test per scenario on. A scenario of the Swift Testing runner is
    /// its generated test, `CucumberFeatures/<feature>/<scenario>(_:)`. Also whether a scenario needs the test per scenario.
    private func onlyTesting(_ scenarios: [ScenarioID], in copy: URL) throws -> (identifiers: [String], testPerScenario: Bool) {
        var names = ScenarioTestNames(root: copy, readable: ScenarioTestNames.readableTestNames(in: environment))
        var identifiers = [String]()
        var testPerScenario = false
        for scenario in scenarios {
            switch try names.runner(for: scenario) {
                case .xctest:
                    testPerScenario = true
                    identifiers += try names.testNames(for: scenario).map { "\(ScenarioTestNames.testClass)/\($0)" }
                case .swiftTesting:
                    identifiers.append(try names.swiftTestingIdentifier(for: scenario))
            }
        }
        return (identifiers, testPerScenario)
    }

    /// How many tests the result bundle says ran, or 0 when there is no bundle or it can't be read.
    func testsRun(inBundle bundle: URL, in copy: URL) -> Int {
        guard FileManager.default.fileExists(atPath: bundle.path) else { return 0 }
        let result = commands.run(
            xcrun,
            ["xcresulttool", "get", "test-results", "summary", "--path", bundle.path, "--format", "json"],
            in: copy,
            environment: [:],
            timeout: 120
        )
        return Self.testCount(inSummary: result.output)
    }

    private func nextRun() -> Int {
        lock.lock()
        defer { lock.unlock() }
        runs += 1
        return runs
    }

    private func write(_ output: String, named name: String, in copy: URL) -> URL? {
        guard let folder = try? makeFolder(runnerFolder(for: copy).appendingPathComponent("logs")) else { return nil }
        let url = folder.appendingPathComponent("\(name).log")
        return (try? output.write(to: url, atomically: true, encoding: .utf8)) == nil ? nil : url
    }
}
