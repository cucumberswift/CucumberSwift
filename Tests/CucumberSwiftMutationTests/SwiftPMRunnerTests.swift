//
//  SwiftPMRunnerTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class SwiftPMRunnerTests: TemporaryFolderTestCase {
    private func makeCopy() throws -> URL {
        let copy = folder.appendingPathComponent("work/package")
        try FileManager.default.createDirectory(at: copy, withIntermediateDirectories: true)
        try "// swift-tools-version:5.9\n".write(to: copy.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        return copy
    }

    func testPrepareRefusesACopyWithoutAPackage() throws {
        let empty = folder.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertThrowsError(try SwiftPMRunner(commands: RecordingCommands()).prepare(copy: empty))
    }

    func testBuildsTestsWithCoverageAndKeepsTheLog() throws {
        let commands = RecordingCommands { _ in .finished(0, output: "Build complete!") }
        let runner = SwiftPMRunner(swift: "/s/swift", arguments: ["--disable-sandbox"], commands: commands)
        let copy = try makeCopy()
        try runner.prepare(copy: copy)
        let build = runner.build(in: copy, timeout: nil)
        XCTAssertTrue(build.succeeded)
        XCTAssertEqual(commands.calls.first?.arguments, ["build", "--build-tests", "--disable-sandbox", "-Xswiftc", "-profile-generate", "-Xswiftc", "-profile-coverage-mapping"])
        XCTAssertEqual(try String(contentsOf: XCTUnwrap(build.log), encoding: .utf8), "Build complete!")
    }

    func testSettingsAreTheEnvironmentOfTheTestRunAndTheRunnerPicksTheFolders() throws {
        let commands = RecordingCommands { _ in .finished(0, output: "Executed 4 tests, with 0 failures") }
        let runner = SwiftPMRunner(commands: commands)
        let copy = try makeCopy()
        try runner.prepare(copy: copy)
        let run = runner.test(in: copy, request: TestRequest(settings: ["CUCUMBERSWIFT_MUTANT": "7"], measuresCoverage: true, writesReport: true))
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(call.arguments, ["test", "--skip-build"])
        XCTAssertEqual(call.environment["CUCUMBERSWIFT_MUTANT"], "7")
        XCTAssertEqual(call.environment["CUCUMBER_COVERAGE"], "YES")
        let report = try XCTUnwrap(call.environment["CUCUMBER_REPORT_PATH"])
        let coverage = try XCTUnwrap(call.environment["CUCUMBER_COVERAGE_PATH"])
        for path in [report, coverage] {
            XCTAssertTrue(path.hasPrefix(folder.path) || path.hasPrefix("/private" + folder.path), "\(path) is next to the copy")
        }
        XCTAssertEqual(run.testsRun, 4)
        XCTAssertNil(run.cucumberReport, "The tests wrote no report")
        XCTAssertNil(run.coverageFolder, "The tests wrote no coverage")
    }

    func testReturnsTheReportAndCoverageTheTestsWrote() throws {
        let commands = RecordingCommands { call in
            for key in ["CUCUMBER_REPORT_PATH", "CUCUMBER_COVERAGE_PATH"] {
                guard let path = call.environment[key] else { continue }
                let url = URL(fileURLWithPath: path)
                let folder = key == "CUCUMBER_REPORT_PATH" ? url.deletingLastPathComponent() : url
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                if key == "CUCUMBER_REPORT_PATH" { try? "[]".write(to: url, atomically: true, encoding: .utf8) }
            }
            return .finished(0, output: "Executed 1 test")
        }
        let runner = SwiftPMRunner(commands: commands)
        let copy = try makeCopy()
        let run = runner.test(in: copy, request: TestRequest(measuresCoverage: true, writesReport: true))
        XCTAssertEqual(try String(contentsOf: XCTUnwrap(run.cucumberReport), encoding: .utf8), "[]")
        XCTAssertNotNil(run.coverageFolder)
    }

    func testEachRunGetsItsOwnFiles() throws {
        let commands = RecordingCommands()
        let runner = SwiftPMRunner(commands: commands)
        let copy = try makeCopy()
        _ = runner.test(in: copy, request: TestRequest(writesReport: true))
        _ = runner.test(in: copy, request: TestRequest(writesReport: true))
        XCTAssertEqual(Set(commands.calls.compactMap { $0.environment["CUCUMBER_REPORT_PATH"] }).count, 2)
    }

    func testACommandThatNeverStartedIsNotAFailingTest() throws {
        let commands = RecordingCommands { _ in CommandResult(status: 130, output: "Cancelled", timedOut: false, duration: 0, started: false) }
        let run = SwiftPMRunner(commands: commands).test(in: try makeCopy(), request: TestRequest())
        XCTAssertFalse(run.started)
        XCTAssertTrue(SwiftPMRunner(commands: RecordingCommands()).test(in: try makeCopy(), request: TestRequest()).started)
    }

    func testTheTimeoutAndTheTimedOutAnswerPassThrough() throws {
        let commands = RecordingCommands { _ in .finished(15, timedOut: true) }
        let run = SwiftPMRunner(commands: commands).test(in: try makeCopy(), request: TestRequest(timeout: 42))
        XCTAssertEqual(commands.calls.first?.timeout, 42)
        XCTAssertTrue(run.timedOut)
        XCTAssertFalse(run.succeeded)
    }
}
