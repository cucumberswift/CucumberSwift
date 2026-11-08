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

    /// A worker of `run` that wrote `features` and has exited, so it no longer holds the run lock.
    private func exitedWorker(of run: RunStarter?, wrote features: [[String: Any]]) {
        let worker = ReportFile(url: url)
        worker.joinRun(run: run)
        worker.merge(features)
    }

    func testAWorkerThatCantTellRunsApartKeepsAFreshReport() throws {
        exitedWorker(of: nil, wrote: [feature([scenario("A", line: 3)])])

        let next = ReportFile(url: url)
        next.joinRun(run: nil)
        XCTAssertEqual(names(next.read()), [["A"]])
    }

}

#if os(macOS)
/// A new run starts when the command that started the last run's processes has exited. `swift test` and
/// `xcodebuild` start the test processes on a Mac; on a Simulator, `launchd` does, which doesn't tell runs apart.
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

    func testTheFirstWorkerOfANewRunEmptiesAFreshReportWhenTheLastRunsStarterHasExited() throws {
        exitedWorker(of: try exitedStarter(), wrote: [feature([scenario("Old", line: 3)])])

        let first = ReportFile(url: url)
        first.joinRun(run: RunStarter(process: getpid()))
        XCTAssertEqual(first.read().count, 0)
    }

    func testTheNextTargetOfARunKeepsTheReportWhileTheRunsStarterRuns() throws {
        let starter = try XCTUnwrap(RunStarter(process: getpid()))
        // The XCTest process has exited, and the Swift Testing process of the same `swift test` starts.
        exitedWorker(of: starter, wrote: [feature([scenario("A", line: 3)])])
        let swiftTesting = ReportFile(url: url)
        swiftTesting.joinRun(run: starter)
        swiftTesting.merge([feature([scenario("B", line: 6)])])
        XCTAssertEqual(names(swiftTesting.read()), [["A", "B"]])
    }

    func testAStaleReportIsEmptiedEvenWhileTheRunsStarterRuns() throws {
        let starter = try XCTUnwrap(RunStarter(process: getpid()))
        exitedWorker(of: starter, wrote: [feature([scenario("Old", line: 3)])])
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -3_600)], ofItemAtPath: url.path)

        let first = ReportFile(url: url)
        first.joinRun(run: starter)
        XCTAssertEqual(first.read().count, 0)
    }

    func testARunStarterIsKnownByItsProcessIDAndStartTime() throws {
        let starter = try XCTUnwrap(RunStarter(process: getpid()))
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
