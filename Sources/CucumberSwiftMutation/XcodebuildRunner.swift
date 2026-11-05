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
/// A run of some scenarios turns on a test per scenario (`CUCUMBER_ONE_TEST_PER_SCENARIO`) and selects the tests with
/// `-only-testing`: with a test per step, the default, the test classes exist only while the bundle runs, and
/// `-only-testing` selects none of them.
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
        /// The test target the scheme runs, such as `VotingTests`, for `-only-testing`. `nil` for the scheme's own.
        public var testTarget: String?
        /// More arguments for every `xcodebuild`, such as `-skipPackagePluginValidation`.
        public var arguments: [String]

        var isWorkspace: Bool { container.hasSuffix(".xcworkspace") }

        public init(container: String, scheme: String, destination: String, testTarget: String? = nil, arguments: [String] = []) {
            self.container = container
            self.scheme = scheme
            self.destination = destination
            self.testTarget = testTarget
            self.arguments = arguments
        }
    }

    private let target: Target
    private let xcodebuild: String
    private let xcrun: String
    private let commands: CommandRunning
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
        commands: CommandRunning = ProcessRunner()
    ) {
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
        var settings = request.settings
        var report: URL?
        var coverage: URL?
        if request.writesReport {
            let file = folder.appendingPathComponent("reports/report-\(number).json")
            settings["CUCUMBER_REPORT_PATH"] = file.path
            report = file
        }
        if request.measuresCoverage {
            let folder = folder.appendingPathComponent("coverage-\(number)")
            settings["CUCUMBER_COVERAGE"] = "YES"
            settings["CUCUMBER_COVERAGE_PATH"] = folder.path
            coverage = folder
        }
        let bundle = folder.appendingPathComponent("results/test-\(number).xcresult")
        var arguments = ["test-without-building"] + common(in: copy) + ["-resultBundlePath", bundle.path, "-enableCodeCoverage", "YES", "CODE_SIGNING_ALLOWED=NO"]
        if let scenarios = request.scenarios {
            do {
                arguments += try onlyTesting(scenarios, in: copy)
            } catch {
                return TestRun(status: 1, log: write("error: \(error)\n", named: "test-\(number)", in: copy))
            }
            settings["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES"
        }
        // The prefixed variables are how xcodebuild gives the tests a setting.
        var environment = [String: String]()
        for (key, value) in settings { environment["TEST_RUNNER_\(key)"] = value }
        let result = commands.run(xcodebuild, arguments, in: copy, environment: environment, timeout: request.timeout)
        let log = write(result.output, named: "test-\(number)", in: copy)
        return TestRun(
            status: result.status,
            timedOut: result.timedOut,
            duration: result.duration,
            testsRun: testsRun(inBundle: bundle, in: copy),
            log: log,
            cucumberReport: report.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil },
            coverageFolder: coverage.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        )
    }

    /// `-only-testing <target>/CucumberScenarioTest/<test>` for the test of each of `scenarios`. A test needs its test
    /// target, so scenarios need `Target.testTarget`.
    private func onlyTesting(_ scenarios: [ScenarioID], in copy: URL) throws -> [String] {
        guard let testTarget = target.testTarget else {
            throw Failure(description: "Running only some scenarios needs the test target's name: pass --test-target")
        }
        var names = ScenarioTestNames(root: copy, readable: ScenarioTestNames.readableTestNames(in: ProcessInfo.processInfo.environment))
        return try names.testNames(for: scenarios).flatMap { ["-only-testing", "\(testTarget)/\(ScenarioTestNames.testClass)/\($0)"] }
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
