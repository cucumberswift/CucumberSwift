//
//  XcodebuildRunner.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
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

    /// Whether one of `files`, relative to a bundle, is the feature file of one of `scenarios`.
    private static func holds(_ files: [String], oneOf scenarios: [ScenarioID]) -> Bool {
        let features = scenarios.map(\.feature)
        return files.contains { file in features.contains { file == $0 || file.hasSuffix("/" + $0) } }
    }

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
        return BuildResult(succeeded: result.succeeded, duration: result.duration, log: write(result.output, named: "build", in: copy), started: result.started)
    }

    public func test(in copy: URL, request: TestRequest) -> TestRun {
        let folder = runnerFolder(for: copy)
        let number = nextRun()
        var settings = environment.filter { $0.key.hasPrefix("CUCUMBER_") }.merging(request.settings) { _, new in new }
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
                // The names can't be resolved, as when two test targets have the same feature file. That isn't a failed
                // test, so the run neither fails nor counts a mutant as killed: CUCUMBER_SCENARIOS selects the scenarios
                // alone, in every test target. Nothing is lost but the saved time of -only-testing.
                _ = write("note: -only-testing isn't used: \(error)\n", named: "selection-\(number)", in: copy)
            }
        }
        // One run for every test target: each test bundle's process adds its scenarios to the one report of the run.
        let report = request.writesReport ? folder.appendingPathComponent("reports/report-\(number).json") : nil
        if let report { settings["CUCUMBER_REPORT_PATH"] = report.path }
        let bundle = folder.appendingPathComponent("results/test-\(number).xcresult")
        var arguments = ["test-without-building"] + common(in: copy)
        arguments += ["-resultBundlePath", bundle.path, "-enableCodeCoverage", "YES", "CODE_SIGNING_ALLOWED=NO"]
        // A failing test, which is how a mutant dies, makes xcodebuild collect diagnostics, such as log archives, for about
        // 20 seconds longer than a passing run takes. The run needs the result bundle and the report, not those.
        arguments += ["-collect-test-diagnostics", "never"]
        arguments += onlyTestingArguments(identifiers: identifiers, targets: testTargets(for: request.scenarios, in: copy))
        // The prefixed variables are how xcodebuild gives the tests a setting.
        var prefixed = [String: String]()
        for (key, value) in settings { prefixed["TEST_RUNNER_\(key)"] = value }
        let result = commands.run(xcodebuild, arguments, in: copy, environment: prefixed, timeout: request.timeout)
        var run = TestRun(
            status: result.status,
            timedOut: result.timedOut,
            duration: result.duration,
            testsRun: testsRun(inBundle: bundle, in: copy),
            log: write(result.output, named: "test-\(number)", in: copy),
            cucumberReport: report.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil },
            coverageFolder: coverage.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        )
        run.started = result.started
        return run
    }

    /// The test targets that one run starts: all of them for a run of every scenario or a project with one test target,
    /// else only the ones that can run one of `scenarios`. A target that holds none is left out: its bundle would start
    /// and run no test, which takes seconds.
    private func testTargets(for scenarios: [ScenarioID]?, in copy: URL) -> [String] {
        guard target.testTargets.count > 1, let scenarios else { return target.testTargets }
        return testTargets(holding: scenarios, in: copy)
    }

    /// The test targets that can run one of `scenarios`: the ones whose built bundle holds the scenario's feature file
    /// anywhere inside it, in the order of the target's test targets. A feature file can be in the bundle itself, in
    /// `Contents/Resources` of a macOS bundle, or in a resource bundle inside it, as SwiftPM makes for a target's resources.
    /// A target whose bundle isn't found is kept, because it may hold one, and so is every target when none of them holds
    /// any, so that a run never skips all of them.
    private func testTargets(holding scenarios: [ScenarioID], in copy: URL) -> [String] {
        let bundles = builtBundles(in: copy)
        let holding = target.testTargets.filter { name in
            guard let bundle = bundles[name] else { return true }
            return Self.holds(featureFiles(in: bundle), oneOf: scenarios)
        }
        return holding.isEmpty ? target.testTargets : holding
    }

    /// The paths of the feature files anywhere inside `bundle`, relative to it.
    private func featureFiles(in bundle: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(at: bundle, includingPropertiesForKeys: nil) else { return [] }
        let base = bundle.resolvingSymlinksInPath().path.count + 1
        let urls = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "feature" }
        return urls.map { String($0.resolvingSymlinksInPath().path.dropFirst(base)) }
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

    /// The `-only-testing` arguments of a run of the test `targets`: each of `identifiers` in each target, because a scenario doesn't say which
    /// target holds it, and `xcodebuild` ignores an identifier that a target doesn't have. With no identifiers, a run of named
    /// test targets selects them, so that `--test-target` limits the run to the targets it names, and a run with no test
    /// target named selects nothing.
    private func onlyTestingArguments(identifiers: [String]?, targets: [String]) -> [String] {
        guard let identifiers else { return targets.flatMap { ["-only-testing", $0] } }
        var seen = Set<String>()
        return targets.flatMap { testTarget in
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
#endif
