//
//  ReportRunTests.swift
//  CucumberSwiftTests
//
//  Every process of a test run writes one Cucumber JSON report, and a new run replaces it (#546).
//

import Foundation
import XCTest
@testable import CucumberSwift

class ReportRunTests: XCTestCase {
    private var folder: URL!
    private var url: URL { folder.appendingPathComponent("report.json") }

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("ReportRunTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { [folder] in folder.map { try? FileManager.default.removeItem(at: $0) } }
    }

    private func feature(_ scenarios: [[String: Any]]) -> [String: Any] {
        ["name": "Checkout", "uri": "Checkout.feature", "line": 1, "keyword": "Feature", "elements": scenarios]
    }

    private func scenario(_ name: String, line: Int) -> [String: Any] {
        ["name": name, "line": line, "id": name.lowercased(), "keyword": "Scenario", "steps": [[String: Any]]()]
    }

    private func names(_ features: [[String: Any]]) -> [[String]] {
        features.map { ($0["elements"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String } }
    }

    /// A worker that joins the run, writes `name`'s scenario and exits, so it no longer holds the run lock.
    private func exitedWorker(runner: String = "XCTest",
                              bundle: String? = "Tests.xctest",
                              isParallel: Bool = false,
                              run: RunStarter? = nil,
                              wrote name: String) {
        let worker = ReportFile(url: url)
        worker.joinRun(runner: runner, bundle: bundle, isParallel: isParallel, run: run)
        worker.merge([feature([scenario(name, line: name.utf8.reduce(1) { $0 + Int($1) })])])
    }

    private func joined(runner: String = "XCTest",
                        bundle: String? = "Tests.xctest",
                        isParallel: Bool = false,
                        run: RunStarter? = nil,
                        staleAfter: TimeInterval = ReportFile.staleAfter) -> [[String: Any]] {
        let worker = ReportFile(url: url)
        worker.joinRun(runner: runner, bundle: bundle, isParallel: isParallel, run: run, staleAfter: staleAfter)
        return worker.read()
    }

    private func ageReport(by seconds: TimeInterval) throws {
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -seconds)], ofItemAtPath: url.path)
    }

    // MARK: Without a command that starts the run: Xcode, and a Simulator

    func testAnotherBundleOfTheSameRunKeepsTheReport() {
        exitedWorker(bundle: "Unit.xctest", wrote: "A")
        XCTAssertEqual(names(joined(runner: "Swift Testing", bundle: "Features.xctest")), [["A"]])
    }

    func testABundleThatRunsAgainStartsANewRunWithoutWaitingForTheReportToGoStale() {
        exitedWorker(bundle: "Unit.xctest", wrote: "A")
        exitedWorker(runner: "Swift Testing", bundle: "Features.xctest", wrote: "B")
        // A rerun of the scheme starts with the first bundle again, seconds after the run before.
        XCTAssertEqual(joined(bundle: "Unit.xctest").count, 0)
    }

    func testARerunOfOneBundleReplacesTheReportOfBothBundles() {
        exitedWorker(bundle: "Unit.xctest", wrote: "A")
        exitedWorker(runner: "Swift Testing", bundle: "Features.xctest", wrote: "B")
        XCTAssertEqual(joined(runner: "Swift Testing", bundle: "Features.xctest").count, 0)
    }

    func testTheSameBundleWithAnotherRunnerIsAnotherWorkerOfTheRun() {
        exitedWorker(runner: "XCTest", bundle: nil, wrote: "A")
        XCTAssertEqual(names(joined(runner: "Swift Testing", bundle: nil)), [["A"]])
    }

    func testTheWorkersOfOneBundleOfAParallelRunAreOneRunWhicheverWorkerStartsLater() {
        exitedWorker(isParallel: true, wrote: "A")
        XCTAssertEqual(names(joined(isParallel: true)), [["A"]])
    }

    func testAStaleReportIsEmptiedByAnyWorker() throws {
        exitedWorker(bundle: "Unit.xctest", wrote: "Old")
        try ageReport(by: ReportFile.staleAfter + 60)
        XCTAssertEqual(joined(bundle: "Other.xctest").count, 0)
    }

    /// A target of the same run that starts minutes after the one before it, as a UI target does while its
    /// Simulator boots, keeps the report.
    func testASlowTargetOfTheSameRunKeepsTheReport() throws {
        exitedWorker(bundle: "Unit.xctest", wrote: "A")
        try ageReport(by: ReportFile.staleAfter - 60)
        XCTAssertEqual(names(joined(runner: "XCTest", bundle: "UI.xctest")), [["A"]])
    }

    /// The cost of that: a parallel run in Xcode, or on a Simulator, that starts within the limit of the last
    /// run adds to its report, because its workers can't be told from the last run's.
    func testAParallelRunThatStartsWithinTheLimitAddsToTheLastRunsReport() throws {
        exitedWorker(isParallel: true, wrote: "A")
        try ageReport(by: ReportFile.staleAfter - 60)
        XCTAssertEqual(names(joined(isParallel: true)), [["A"]])
        try ageReport(by: ReportFile.staleAfter + 60)
        XCTAssertEqual(joined(isParallel: true).count, 0)
    }

    func testTheLimitIsTenMinutes() {
        XCTAssertEqual(ReportFile.staleAfter, 600)
    }

    func testTheRunRecordKeepsItsStarterAndItsBundles() {
        var record = RunRecord(starter: RunStarter(pid: 42, started: 7))
        record.keys = ["XCTest A.xctest", "Swift Testing B.xctest"]
        XCTAssertEqual(RunRecord(recorded: record.recorded), record)
        XCTAssertEqual(RunRecord(recorded: ""), RunRecord())
        XCTAssertEqual(RunRecord(recorded: "not a starter\nXCTest A.xctest").keys, ["XCTest A.xctest"])
        XCTAssertNil(RunRecord(recorded: "not a starter").starter)
    }

    func testTheBundleIsNamedByTheLastFolderOfItsPath() {
        XCTAssertEqual(RunRecord.key(runner: "XCTest", bundle: "Unit.xctest"), "XCTest Unit.xctest")
        XCTAssertEqual(RunRecord.key(runner: "XCTest", bundle: nil), "XCTest ")
    }

    // MARK: A crashed scenario

    /// A process killed while it runs a scenario leaves the scenario in the report, with the steps of the
    /// scenarios before it written whole.
    func testAScenarioThatNeverFinishesIsInTheReportAndTheOnesBeforeItAreWhole() throws {
        let recorder = CucumberJSONRecorder(reportURL: { self.url }, runner: "XCTest")
        let feature = NSObject(), done = NSObject(), crashing = NSObject(), step = NSObject()
        let owner = (key: ObjectIdentifier(feature), make: { CucumberJSONReport.Feature(uri: "Checkout.feature", title: "Checkout", description: "", line: 1, tags: []) })
        recorder.suiteStarted()
        recorder.featureStarted(owner.key, make: owner.make)
        recorder.scenarioStarted(ObjectIdentifier(done), feature: owner) { CucumberJSONReport.Scenario(title: "Done", line: 3, tags: []) }
        recorder.stepStarted(ObjectIdentifier(step), scenario: ObjectIdentifier(done)) { CucumberJSONReport.Step(name: "a step", keyword: "Given ", line: 4) }
        recorder.stepFinished(ObjectIdentifier(step), result: .passed, duration: Measurement(value: 1, unit: .nanoseconds))
        recorder.scenarioFinished()
        recorder.scenarioStarted(ObjectIdentifier(crashing), feature: owner) { CucumberJSONReport.Scenario(title: "Crashes", line: 6, tags: []) }
        // The process is killed here: nothing is written after the scenario starts.

        let report = ReportFile(url: url).read()
        XCTAssertEqual(names(report), [["Done", "Crashes"]])
        let steps = (report.first?["elements"] as? [[String: Any]])?.first?["steps"] as? [[String: Any]]
        XCTAssertEqual(steps?.count, 1)
    }
}

#if os(macOS)
/// A new run starts when the command that started the last run's processes has exited, and a run is the
/// same run while that command runs. `swift test` and `xcodebuild` start the test processes on a Mac; on a
/// Simulator, `launchd` does, which doesn't tell runs apart.
extension ReportRunTests {
    /// The process that started an earlier run's workers, which has exited: `swift test` or `xcodebuild` of
    /// the run before.
    private func exitedStarter() throws -> RunStarter {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try process.run()
        process.waitUntilExit()
        return RunStarter(pid: process.processIdentifier, started: 1)
    }

    private func runningStarter() throws -> RunStarter {
        try XCTUnwrap(RunStarter(process: getpid()))
    }

    func testTheFirstWorkerOfANewRunEmptiesAFreshReportWhenTheLastRunsStarterHasExited() throws {
        exitedWorker(run: try exitedStarter(), wrote: "Old")
        XCTAssertEqual(joined(bundle: "Other.xctest", run: try runningStarter()).count, 0)
    }

    func testTheNextTargetOfARunKeepsTheReportWhileTheRunsStarterRuns() throws {
        let starter = try runningStarter()
        // The XCTest process has exited, and the Swift Testing process of the same `swift test` starts.
        exitedWorker(bundle: nil, run: starter, wrote: "A")
        XCTAssertEqual(names(joined(runner: "Swift Testing", bundle: nil, run: starter)), [["A"]])
    }

    /// The first runner finished more than 10 minutes before the second starts, as when the first one's tests
    /// are followed by a long tear-down.
    func testTheNextTargetOfARunKeepsAnOldReportWhileTheRunsStarterRuns() throws {
        let starter = try runningStarter()
        exitedWorker(bundle: nil, run: starter, wrote: "A")
        try ageReport(by: 3_600)
        XCTAssertEqual(names(joined(runner: "Swift Testing", bundle: nil, run: starter)), [["A"]])
    }

    func testAReportNoRunWroteIsEmptiedByARunWithAStarterHoweverNewItIs() throws {
        // A report that an earlier run left without recording its command, such as one from Xcode.
        ReportFile(url: url).merge([feature([scenario("Old", line: 3)])])
        XCTAssertEqual(joined(bundle: nil, run: try runningStarter()).count, 0)
    }

    func testARunWhoseStarterStillRunsIsNotEmptiedByAWorkerOfAnotherCommand() throws {
        exitedWorker(bundle: "Unit.xctest", run: try runningStarter(), wrote: "A")
        XCTAssertEqual(names(joined(runner: "Swift Testing", bundle: "Features.xctest", run: nil)), [["A"]])
    }

    func testARunStarterIsKnownByItsProcessIDAndStartTime() throws {
        let starter = try runningStarter()
        XCTAssertFalse(starter.hasExited)
        XCTAssertEqual(RunStarter(recorded: starter.recorded), starter)
        // Another process that got the same ID later.
        XCTAssertTrue(RunStarter(pid: starter.pid, started: starter.started + 1).hasExited)
        XCTAssertTrue(try exitedStarter().hasExited)
        XCTAssertNil(RunStarter(recorded: ""))
    }

    /// Only `swift test` and `xcodebuild` start every test process of a run, and only that run's. Xcode starts
    /// each test process under a `debugserver` of its own, which exits with it. `swift-test` is a link to
    /// `swift-package`, whose name its process takes.
    func testOnlySwiftTestAndXcodebuildStartARun() throws {
        let folder = try XCTUnwrap(folder)
        for name in ["swift-package", "xcodebuild"] {
            // A process with the command's name: a copy of `sleep`, which runs until the test stops it.
            let command = folder.appendingPathComponent(name)
            try FileManager.default.copyItem(at: URL(fileURLWithPath: "/bin/sleep"), to: command)
            let process = Process()
            process.executableURL = command
            process.arguments = ["60"]
            try process.run()
            defer { process.terminate() }

            let starter = try XCTUnwrap(RunStarter.command(process.processIdentifier), name)
            XCTAssertEqual(starter, RunStarter(process: process.processIdentifier), name)
        }
        // The test process itself, which XCTest or a test host runs, starts no run.
        XCTAssertNil(RunStarter.command(getpid()))
    }
}
#endif
