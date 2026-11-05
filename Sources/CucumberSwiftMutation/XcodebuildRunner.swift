//
//  XcodebuildRunner.swift
//  CucumberSwiftMutation
//

import Foundation

/// Builds an Xcode project or workspace with `xcodebuild build-for-testing`, with code coverage on, and tests it
/// with `xcodebuild test-without-building`. A scheme and a destination say what to build and where to run it.
///
/// CucumberSwift's settings reach the tests as `TEST_RUNNER_`-prefixed build settings, which `xcodebuild` passes to the
/// test process without the prefix. The test count comes from each run's result bundle, so a run in which Xcode ran
/// no test is a run of 0 tests, whatever Xcode printed.
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

        public init(container: String, scheme: String, destination: String, testTarget: String? = nil, arguments: [String] = []) {
            self.container = container
            self.scheme = scheme
            self.destination = destination
            self.testTarget = testTarget
            self.arguments = arguments
        }

        var isWorkspace: Bool { container.hasSuffix(".xcworkspace") }
    }

    private let target: Target
    private let xcodebuild: String
    private let xcrun: String
    private let commands: CommandRunning
    private let lock = NSLock()
    private var runs = 0

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
            let folder = folder.appendingPathComponent("coverage/run-\(number)")
            settings["CUCUMBER_COVERAGE"] = "YES"
            settings["CUCUMBER_COVERAGE_PATH"] = folder.path
            coverage = folder
        }
        let bundle = folder.appendingPathComponent("results/test-\(number).xcresult")
        var arguments = ["test-without-building"] + common(in: copy) + ["-resultBundlePath", bundle.path, "-enableCodeCoverage", "YES"]
        do {
            arguments += try onlyTesting(request.scenarios, in: copy)
        } catch {
            return TestRun(status: 1, log: write("error: \(error)\n", named: "test-\(number)", in: copy))
        }
        arguments += ["CODE_SIGNING_ALLOWED=NO"]
        // Build settings, in a fixed order so that a run is the same command every time.
        for key in settings.keys.sorted() { arguments.append("TEST_RUNNER_\(key)=\(settings[key] ?? "")") }
        let result = commands.run(xcodebuild, arguments, in: copy, environment: [:], timeout: request.timeout)
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

    /// `-only-testing:<target>/<class>` for each class that runs one of `scenarios`. Without a test target the
    /// class alone isn't a valid identifier, so scenarios need `Target.testTarget`.
    private func onlyTesting(_ scenarios: [ScenarioID]?, in copy: URL) throws -> [String] {
        guard let scenarios else { return [] }
        guard let testTarget = target.testTarget else {
            throw Failure(description: "Running only some scenarios needs the test target's name: pass --test-target")
        }
        var names = ScenarioTestNames(root: copy)
        return try names.classNames(for: scenarios).flatMap { ["-only-testing", "\(testTarget)/\($0)"] }
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

    /// `totalTestCount` of the summary that `xcresulttool get test-results summary` prints.
    static func testCount(inSummary json: String) -> Int {
        guard let data = json.data(using: .utf8),
              let summary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let total = summary["totalTestCount"] as? Int else { return 0 }
        return total
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
