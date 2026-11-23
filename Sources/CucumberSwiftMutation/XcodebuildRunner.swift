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
/// names of the test targets, the run also starts only the test targets whose built bundle holds one of the scenarios'
/// feature files, which keeps Xcode from starting a test bundle that would run none of them. A Swift DSL scenario has no
/// feature file, so the run learns which test target holds it from the coverage of the run that measured it, the one
/// before any mutant, and starts every test target for a DSL scenario whose target it hasn't learned.
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

        /// A trailing slash, as tab completion adds, does not change that the container is a workspace.
        var isWorkspace: Bool { container.hasSuffix(".xcworkspace") || container.hasSuffix(".xcworkspace/") }

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
    /// The test targets whose process ran each feature, by the feature's path, as the manifests of the coverage runs say.
    private var targetsOfFeatures = [String: Set<String>]()

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
        // One run for every test target: each test bundle's process adds its scenarios to the one report of the run.
        let report = request.writesReport ? folder.appendingPathComponent("reports/report-\(number).json") : nil
        if let report { settings["CUCUMBER_REPORT_PATH"] = report.path }
        let bundle = folder.appendingPathComponent("results/test-\(number).xcresult")
        var arguments = ["test-without-building"] + common(in: copy)
        arguments += ["-resultBundlePath", bundle.path, "-enableCodeCoverage", "YES", "CODE_SIGNING_ALLOWED=NO"]
        // A failing test, which is how a mutant dies, makes xcodebuild collect diagnostics, such as log archives, for about
        // 20 seconds longer than a passing run takes. The run needs the result bundle and the report, not those.
        arguments += ["-collect-test-diagnostics", "never"]
        arguments += onlyTestingArguments(targets: testTargets(for: request.scenarios, in: copy))
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
        if let coverage = run.coverageFolder { learnTargets(ofFeaturesIn: coverage) }
        return run
    }

    /// Notes which test target ran each feature of the coverage runs under `folder`: each run's manifest names the test
    /// bundle's binary, such as `.../VotingTests.xctest/Contents/MacOS/VotingTests`, and the features that its scenarios ran.
    private func learnTargets(ofFeaturesIn folder: URL) {
        let runs = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        var learned = [String: Set<String>]()
        for run in runs where run.lastPathComponent.hasPrefix("run-") {
            guard let data = try? Data(contentsOf: run.appendingPathComponent("manifest.json")),
                  let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            let bundles = (manifest["binaries"] as? [[String: Any]] ?? []).compactMap { binary -> String? in
                (binary["path"] as? String)?.components(separatedBy: "/").first { $0.hasSuffix(".xctest") }
                    .map { String($0.dropLast(".xctest".count)) }
            }
            // A run whose process loaded no test bundle says nothing about the target that ran a feature.
            guard !bundles.isEmpty else { continue }
            for feature in (manifest["features"] as? [[String: Any]] ?? []).compactMap({ $0["feature"] as? String }) {
                learned[ScenarioID.feature(ofURI: feature), default: []].formUnion(bundles)
            }
        }
        lock.lock()
        defer { lock.unlock() }
        targetsOfFeatures.merge(learned) { $0.union($1) }
    }

    private func learnedTargets(ofFeature feature: String) -> Set<String>? {
        lock.lock()
        defer { lock.unlock() }
        return targetsOfFeatures[feature]
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
    /// any, so that a run never skips all of them. A Swift DSL scenario has no feature file: its feature is the Swift file
    /// that declares it, which no bundle holds. Its target is the one whose process ran it in the run that measured the
    /// coverage, and every target is kept when that run didn't tell, or named a bundle that is no test target's.
    private func testTargets(holding scenarios: [ScenarioID], in copy: URL) -> [String] {
        let files = scenarios.filter { $0.feature.hasSuffix(".feature") }
        var learned = Set<String>()
        for scenario in scenarios where !scenario.feature.hasSuffix(".feature") {
            guard let targets = learnedTargets(ofFeature: scenario.feature) else { return target.testTargets }
            learned.formUnion(targets)
        }
        // A bundle is named for its product, which can differ from the name of its test target: a name that is no test
        // target's can't say which target to leave out.
        if !learned.isSubset(of: target.testTargets) { return target.testTargets }
        let bundles = builtBundles(in: copy)
        let holding = target.testTargets.filter { name in
            if learned.contains(name) { return true }
            guard !files.isEmpty else { return false }
            guard let bundle = bundles[name] else { return true }
            return Self.holds(featureFiles(in: bundle), oneOf: files)
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

    /// The `-only-testing` arguments of a run of the test `targets`: each one, so that `--test-target` limits the run to the
    /// targets it names. A run with no test target named selects nothing, so it tests every target of the scheme.
    private func onlyTestingArguments(targets: [String]) -> [String] {
        targets.flatMap { ["-only-testing", $0] }
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
