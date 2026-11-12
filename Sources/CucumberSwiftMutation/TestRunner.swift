//
//  TestRunner.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// What one test run is asked to do.
public struct TestRequest: Sendable {
    /// CucumberSwift's settings for the run, such as `CUCUMBERSWIFT_MUTANT`. Never the tool's own environment:
    /// each runner passes them its own way.
    public var settings: [String: String]
    /// Measure which scenario runs which code. The runner picks the folder that CucumberSwift writes its `run-*` folders
    /// to, and returns it in `TestRun.coverageFolder`.
    public var measuresCoverage: Bool
    /// Write the Cucumber JSON report. The runner picks the file, and returns it in `TestRun.cucumberReport`.
    public var writesReport: Bool
    /// Run only these scenarios. `nil` runs every one.
    public var scenarios: [ScenarioID]?
    /// Stop the run after this many seconds and report it as timed out.
    public var timeout: TimeInterval?

    public init(
        settings: [String: String] = [:],
        measuresCoverage: Bool = false,
        writesReport: Bool = false,
        scenarios: [ScenarioID]? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.settings = settings
        self.measuresCoverage = measuresCoverage
        self.writesReport = writesReport
        self.scenarios = scenarios
        self.timeout = timeout
    }
}

/// How a test run ended.
public struct TestRun: Sendable {
    public var status: Int32
    public var timedOut: Bool
    public var duration: TimeInterval
    /// How many tests ran, as the runner counts them. 0 means the run proved nothing.
    public var testsRun: Int
    /// What the run printed.
    public var log: URL?
    public var cucumberReport: URL?
    public var coverageFolder: URL?
    /// The command that runs the tests started. A command that never started, because the run was cancelled or the tool
    /// couldn't be launched, tested nothing: its non-zero status is not a failing test.
    public var started = true

    public var succeeded: Bool { status == 0 && !timedOut }

    public init(
        status: Int32,
        timedOut: Bool = false,
        duration: TimeInterval = 0,
        testsRun: Int = 0,
        log: URL? = nil,
        cucumberReport: URL? = nil,
        coverageFolder: URL? = nil
    ) {
        self.status = status
        self.timedOut = timedOut
        self.duration = duration
        self.testsRun = testsRun
        self.log = log
        self.cucumberReport = cucumberReport
        self.coverageFolder = coverageFolder
    }
}

/// How a build ended.
public struct BuildResult: Sendable {
    public var succeeded: Bool
    public var duration: TimeInterval
    public var log: URL?
    /// The build command started. A command that never started, because the run was cancelled or the tool couldn't be
    /// launched, built nothing: its failure doesn't mean that a mutant doesn't build.
    public var started: Bool

    public init(succeeded: Bool, duration: TimeInterval = 0, log: URL? = nil, started: Bool = true) {
        self.succeeded = succeeded
        self.duration = duration
        self.log = log
        self.started = started
    }
}

/// Builds the temporary copy of a project and runs its tests, the way one build system does it. A mutation run
/// calls `prepare` once, `build` and `test` for every mutant, and `cleanUp` after every end of the run, whether it
/// finished, failed, was cancelled or was killed.
public protocol TestRunner: Sendable {
    /// Top-level names in the project folder that the copy leaves out, such as build folders.
    var excludedFromCopy: [String] { get }
    /// Checks the copy, and makes the folders the runner writes to. Throws a message for the user when the copy
    /// can't be built or tested.
    func prepare(copy: URL) throws
    /// Builds the copy and its tests, with code coverage, the runner's own way. It builds again after each mutant, so
    /// a runner keeps its build products between calls.
    func build(in copy: URL, timeout: TimeInterval?) -> BuildResult
    /// Runs the tests the last `build` made.
    func test(in copy: URL, request: TestRequest) -> TestRun
    /// Deletes what the runner made outside the copy. May be called more than once, and after a failure.
    func cleanUp(copy: URL)
}

extension TestRunner {
    public var excludedFromCopy: [String] { [] }
    public func cleanUp(copy _: URL) {
        // A runner that makes nothing outside the copy has nothing to clean up.
    }
}

/// What a runner writes next to the copy: logs, reports, coverage and build products. It is in the folder that
/// holds the copy, so the run's `WorkFolder` deletes it with the copy.
func runnerFolder(for copy: URL) -> URL {
    copy.deletingLastPathComponent().appendingPathComponent("runner")
}

/// Makes `folder` and returns it.
func makeFolder(_ folder: URL) throws -> URL {
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}
#endif
