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
    /// The command that started an earlier run's workers, which has exited: no process has its ID.
    private var exitedStarter: RunStarter { RunStarter(pid: 2_000_000_000, started: 1) }

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

    /// Xcode can start a bundle while another bundle's process still runs. That bundle is part of the run too,
    /// so running it again alone replaces the report.
    func testABundleThatJoinsWhileAnotherBundleRunsIsRecordedInTheRun() {
        do {
            let first = ReportFile(url: url)
            first.joinRun(runner: "XCTest", bundle: "Unit.xctest", run: nil)
            first.merge([feature([scenario("A", line: 1)])])
            let second = ReportFile(url: url)
            second.joinRun(runner: "Swift Testing", bundle: "Features.xctest", run: nil)
            second.merge([feature([scenario("B", line: 2)])])
        }
        XCTAssertEqual(joined(runner: "Swift Testing", bundle: "Features.xctest").count, 0)
    }

    /// Workers that join one run at the same moment are all recorded in it, and none empties the report.
    func testWorkersThatJoinTheSameRunAtOnceAreAllRecordedAndKeepTheReport() throws {
        let starter = try runningStarter()
        exitedWorker(bundle: "First.xctest", run: starter, wrote: "A")
        let workers = (0..<8).map { _ in ReportFile(url: url) }
        DispatchQueue.concurrentPerform(iterations: workers.count) { index in
            workers[index].joinRun(runner: "XCTest", bundle: "Bundle\(index).xctest", run: starter)
        }
        let record = RunRecord(recorded: (try? String(contentsOfFile: url.path + ".run", encoding: .utf8)) ?? "")
        XCTAssertEqual(record.keys, Set((0..<8).map { "XCTest Bundle\($0).xctest" } + ["XCTest First.xctest"]))
        XCTAssertEqual(names(workers[0].read()), [["A"]])
    }

    /// The test holds the run lock exclusively, as a first worker does while it decides on a new run. A worker
    /// that joins then waits, and records its key only after the first worker has stored its record, so the
    /// first worker's reset can't discard it.
    func testAWorkerThatJoinsWhileAFirstWorkerDecidesRecordsItsKeyAfterTheDecision() throws {
        let runPath = url.path + ".run"
        let firstWorker = open(runPath, O_CREAT | O_RDWR, 0o644)
        XCTAssertGreaterThanOrEqual(firstWorker, 0)
        defer { close(firstWorker) }
        XCTAssertEqual(flock(firstWorker, LOCK_EX), 0)
        let joined = expectation(description: "the second worker joined")
        let second = ReportFile(url: url)
        DispatchQueue.global().async {
            second.joinRun(runner: "XCTest", bundle: "Second.xctest", run: nil)
            joined.fulfill()
        }
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertEqual(try String(contentsOfFile: runPath, encoding: .utf8), "", "the second worker recorded its key during the decision")
        var record = RunRecord()
        record.keys.insert("XCTest First.xctest")
        let bytes = Array(record.recorded.utf8)
        XCTAssertEqual(pwrite(firstWorker, bytes, bytes.count, 0), bytes.count)
        XCTAssertEqual(flock(firstWorker, LOCK_SH), 0)
        wait(for: [joined], timeout: 10)
        let recorded = RunRecord(recorded: try String(contentsOfFile: runPath, encoding: .utf8))
        XCTAssertEqual(recorded.keys, ["XCTest First.xctest", "XCTest Second.xctest"])
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

    /// A limit that the setting gives decides: a report 5 minutes old is kept with a limit of 10 minutes and
    /// emptied with a limit of a minute, and one 20 minutes old is kept with a limit of 30.
    func testALimitThatIsGivenDecidesWhetherTheReportIsStale() throws {
        exitedWorker(bundle: "Unit.xctest", wrote: "A")
        try ageReport(by: 300)
        XCTAssertEqual(names(joined(bundle: "Other.xctest", staleAfter: 600)), [["A"]])
        try ageReport(by: 1_200)
        XCTAssertEqual(names(joined(bundle: "Third.xctest", staleAfter: 1_800)), [["A"]])
        try ageReport(by: 300)
        XCTAssertEqual(joined(bundle: "Fourth.xctest", staleAfter: 60).count, 0)
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

    // MARK: With a command that starts the run: swift test and xcodebuild

    private func runningStarter() throws -> RunStarter {
        try XCTUnwrap(RunStarter(process: getpid()))
    }

    func testTheFirstWorkerOfANewRunEmptiesAFreshReportWhenTheLastRunsStarterHasExited() throws {
        exitedWorker(run: exitedStarter, wrote: "Old")
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
        XCTAssertTrue(exitedStarter.hasExited)
        XCTAssertNil(RunStarter(process: exitedStarter.pid))
        XCTAssertNil(RunStarter(recorded: ""))
    }

    /// Only a process with the name of `swift test` or `xcodebuild` is a run's starter. This process isn't, and
    /// is one when its own name is given.
    func testOnlyAProcessNamedAsACommandStartsARun() {
        XCTAssertNil(RunStarter.command(getpid()))
        let name = String(ProcessInfo.processInfo.processName.prefix(16))
        XCTAssertEqual(RunStarter.command(getpid(), in: [name]), RunStarter(process: getpid()))
        XCTAssertNil(RunStarter.command(exitedStarter.pid, in: [name]))
        XCTAssertEqual(RunStarter.commands, ["swift-package", "swift-test", "xcodebuild"])
    }

    // MARK: A crashed scenario

    /// A process killed while it runs a scenario leaves the scenario in the report, with the steps of the
    /// scenarios before it written whole.
    func testAScenarioThatNeverFinishesIsInTheReportAndTheOnesBeforeItAreWhole() throws {
        let recorder = CucumberJSONRecorder(reportURL: { self.url }, runner: "XCTest")
        let feature = NSObject()
        let done = NSObject()
        let crashing = NSObject()
        let step = NSObject()
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
/// `swift test` and `xcodebuild` start the test processes on a Mac; on a Simulator, `launchd` does, which
/// doesn't tell runs apart. `swift-test` is a link to `swift-package`, whose name its process takes, and Xcode
/// starts each test process under a `debugserver` of its own.
extension ReportRunTests {
    func testAProcessNamedLikeSwiftTestOrXcodebuildIsARunStarter() throws {
        let folder = try XCTUnwrap(folder)
        let bin = URL(fileURLWithPath: NSOpenStepRootDirectory(), isDirectory: true).appendingPathComponent("bin", isDirectory: true)
        for name in ["swift-package", "xcodebuild"] {
            // A process with the command's name: a copy of `sleep`, which runs until the test stops it.
            let command = folder.appendingPathComponent(name)
            try FileManager.default.copyItem(at: bin.appendingPathComponent("sleep"), to: command)
            let process = Process()
            process.executableURL = command
            process.arguments = ["60"]
            try process.run()
            defer { process.terminate() }

            let starter = try XCTUnwrap(RunStarter.command(process.processIdentifier), name)
            XCTAssertEqual(starter, RunStarter(process: process.processIdentifier), name)
        }
    }
}
#endif
