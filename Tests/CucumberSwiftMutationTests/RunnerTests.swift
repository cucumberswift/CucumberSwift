//
//  RunnerTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

/// Runs nothing and records each command, as `FakeRunner` does for `swift`.
private final class RecordingCommands: CommandRunning, @unchecked Sendable {
    struct Call: Equatable {
        let executable: String
        let arguments: [String]
        let environment: [String: String]
        let timeout: TimeInterval?
    }

    private let lock = NSLock()
    private var recorded = [Call]()
    private let handler: (Call) -> CommandResult

    var calls: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    init(handler: @escaping (Call) -> CommandResult = { _ in .finished(0) }) {
        self.handler = handler
    }

    func run(_ executable: String, _ arguments: [String], in directory: URL, environment: [String: String], timeout: TimeInterval?) -> CommandResult {
        let call = Call(executable: executable, arguments: arguments, environment: environment, timeout: timeout)
        lock.lock()
        recorded.append(call)
        lock.unlock()
        return handler(call)
    }
}

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

    func testTheTimeoutAndTheTimedOutAnswerPassThrough() throws {
        let commands = RecordingCommands { _ in .finished(15, timedOut: true) }
        let run = SwiftPMRunner(commands: commands).test(in: try makeCopy(), request: TestRequest(timeout: 42))
        XCTAssertEqual(commands.calls.first?.timeout, 42)
        XCTAssertTrue(run.timedOut)
        XCTAssertFalse(run.succeeded)
    }
}

final class XcodebuildRunnerTests: TemporaryFolderTestCase {
    private let target = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS")

    private func makeCopy(container: String = "Voting.xcodeproj") throws -> URL {
        let copy = folder.appendingPathComponent("work/package")
        try FileManager.default.createDirectory(at: copy.appendingPathComponent(container), withIntermediateDirectories: true)
        return copy
    }

    private func summary(_ total: Int) -> String {
        "{\"totalTestCount\": \(total), \"passedTests\": \(total), \"failedTests\": 0, \"result\": \"Passed\"}"
    }

    /// An `xcodebuild` that writes the result bundle where it is told and an `xcresulttool` that says `total`.
    private func commands(total: Int, writesBundle: Bool = true, status: Int32 = 0) -> RecordingCommands {
        RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: self.summary(total)) }
            if writesBundle, let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            return .finished(status, output: "** TEST SUCCEEDED **")
        }
    }

    func testPrepareRefusesACopyWithoutTheProject() throws {
        let empty = folder.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertThrowsError(try XcodebuildRunner(target: target, commands: RecordingCommands()).prepare(copy: empty)) {
            XCTAssertTrue("\($0)".contains("Voting.xcodeproj"))
        }
    }

    func testBuildsForTestingWithCoverageIntoOneDerivedDataFolder() throws {
        let commands = RecordingCommands()
        let runner = XcodebuildRunner(target: target, commands: commands)
        let copy = try makeCopy()
        try runner.prepare(copy: copy)
        _ = runner.build(in: copy, timeout: 90)
        _ = runner.build(in: copy, timeout: nil)
        let calls = commands.calls
        XCTAssertEqual(calls.count, 2)
        let arguments = calls[0].arguments
        XCTAssertEqual(Array(arguments.prefix(7)), ["build-for-testing", "-project", "Voting.xcodeproj", "-scheme", "Voting", "-destination", "platform=macOS"])
        XCTAssertEqual(arguments[arguments.firstIndex(of: "-enableCodeCoverage")! + 1], "YES")
        XCTAssertEqual(calls[0].timeout, 90)
        let derivedData = arguments[arguments.firstIndex(of: "-derivedDataPath")! + 1]
        XCTAssertEqual(calls[1].arguments[calls[1].arguments.firstIndex(of: "-derivedDataPath")! + 1], derivedData, "Each build reuses the products")
        XCTAssertTrue(derivedData.contains("/runner/"), "In the folder that holds the copy, so it is deleted with it")
    }

    func testAWorkspaceIsBuiltWithDashWorkspace() throws {
        let commands = RecordingCommands()
        let workspace = XcodebuildRunner.Target(container: "App.xcworkspace", scheme: "App", destination: "platform=macOS", arguments: ["-quiet"])
        let runner = XcodebuildRunner(target: workspace, commands: commands)
        let copy = try makeCopy(container: "App.xcworkspace")
        _ = runner.build(in: copy, timeout: nil)
        let arguments = try XCTUnwrap(commands.calls.first?.arguments)
        XCTAssertTrue(arguments.starts(with: ["build-for-testing", "-workspace", "App.xcworkspace"]))
        XCTAssertTrue(arguments.contains("-quiet"))
        XCTAssertFalse(arguments.contains("-project"))
    }

    func testSettingsReachTheTestsAsPrefixedBuildSettingsAndNeverAsTheEnvironment() throws {
        let commands = commands(total: 6)
        let runner = XcodebuildRunner(target: target, commands: commands)
        let copy = try makeCopy()
        let run = runner.test(in: copy, request: TestRequest(settings: ["CUCUMBERSWIFT_MUTANT": "3", "CUCUMBER_COVERAGE": "NO"], writesReport: true))
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(call.arguments.first, "test-without-building")
        XCTAssertTrue(call.arguments.contains("TEST_RUNNER_CUCUMBERSWIFT_MUTANT=3"))
        XCTAssertTrue(call.arguments.contains("TEST_RUNNER_CUCUMBER_COVERAGE=NO"))
        XCTAssertTrue(call.arguments.contains { $0.hasPrefix("TEST_RUNNER_CUCUMBER_REPORT_PATH=") && $0.contains("/runner/reports/") })
        XCTAssertEqual(call.environment, [:], "The tool's environment is never how the tests get a setting")
        XCTAssertEqual(run.testsRun, 6)
        XCTAssertTrue(run.succeeded)
    }

    func testCountsTheTestsFromTheResultBundleAndNotFromWhatXcodePrinted() throws {
        // Xcode printed success, and ran nothing: the bundle says so.
        let commands = commands(total: 0)
        let run = XcodebuildRunner(target: target, commands: commands).test(in: try makeCopy(), request: TestRequest())
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(run.testsRun, 0)
        let summary = try XCTUnwrap(commands.calls.last)
        XCTAssertEqual(Array(summary.arguments.prefix(5)), ["xcresulttool", "get", "test-results", "summary", "--path"])
    }

    func testARunWithoutAResultBundleRanNoTests() throws {
        let commands = commands(total: 5, writesBundle: false)
        let run = XcodebuildRunner(target: target, commands: commands).test(in: try makeCopy(), request: TestRequest())
        XCTAssertEqual(run.testsRun, 0, "xcodebuild failed before it made a bundle")
        XCTAssertEqual(commands.calls.count, 1, "There is no bundle to ask xcresulttool about")
    }

    func testEachRunWritesItsOwnResultBundle() throws {
        let commands = commands(total: 1)
        let runner = XcodebuildRunner(target: target, commands: commands)
        let copy = try makeCopy()
        _ = runner.test(in: copy, request: TestRequest())
        _ = runner.test(in: copy, request: TestRequest())
        let bundles = commands.calls.compactMap { call in call.arguments.firstIndex(of: "-resultBundlePath").map { call.arguments[$0 + 1] } }
        XCTAssertEqual(Set(bundles).count, 2, "xcodebuild fails when the bundle's path exists")
    }

    func testRunsOnlyTheClassesOfTheScenarios() throws {
        let copy = try makeCopy()
        let features = copy.appendingPathComponent("Features")
        try FileManager.default.createDirectory(at: features, withIntermediateDirectories: true)
        try """
        Feature: Voting

          Scenario: An adult can vote
            Given a person aged 30
            Then the person can vote
        """.write(to: features.appendingPathComponent("Voting.feature"), atomically: true, encoding: .utf8)
        let commands = commands(total: 2)
        var scoped = target
        scoped.testTarget = "VotingTests"
        let runner = XcodebuildRunner(target: scoped, commands: commands)
        _ = runner.test(in: copy, request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")]))
        let arguments = try XCTUnwrap(commands.calls.first?.arguments)
        let index = try XCTUnwrap(arguments.firstIndex(of: "-only-testing"))
        XCTAssertEqual(arguments[index + 1], "VotingTests/Voting|AnAdultCanVote")
    }

    func testScenariosNeedTheTestTarget() throws {
        let commands = commands(total: 1)
        let run = XcodebuildRunner(target: target, commands: commands).test(
            in: try makeCopy(), request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")]))
        XCTAssertNotEqual(run.status, 0)
        XCTAssertTrue(commands.calls.isEmpty, "Nothing runs when the scenarios can't be named")
        XCTAssertTrue(try String(contentsOf: XCTUnwrap(run.log), encoding: .utf8).contains("--test-target"))
    }

    func testReadsTheTestCountOfASummary() {
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: summary(12)), 12)
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: "not json"), 0)
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: "{}"), 0)
    }
}

final class ScenarioTestNamesTests: TemporaryFolderTestCase {
    private func write(_ text: String, to path: String) throws {
        let url = folder.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private let voting = """
    Feature: Voting

      Scenario: An adult can vote
        Given a person aged 30
        Then the person can vote

      Scenario Outline: Ages
        Given a person aged <age>
        Then the person can vote: <vote>

        Examples:
          | age | vote  |
          | 5   | false |
          | 30  | true  |
    """

    func testNamesTheClassOfAScenarioByItsLine() throws {
        try write(voting, to: "Tests/Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")), ["Voting|AnAdultCanVote"])
    }

    func testAnOutlinesLineNamesEveryRowAndARowsLineNamesThatRow() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        let all = try names.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 7, name: ""))
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.allSatisfy { $0.hasPrefix("Voting|Ages") })
        let row = try names.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 14, name: ""))
        XCTAssertEqual(row, [all[1]])
    }

    func testReadableNamesAndTheConfiguredDelimiter() throws {
        try write(voting, to: "Features/Voting.feature")
        var readable = ScenarioTestNames(root: folder, readable: true)
        XCTAssertEqual(try readable.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")), ["Voting \u{203A} An adult can vote"])
        var custom = ScenarioTestNames(root: folder, delimiter: "_")
        XCTAssertEqual(try custom.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")), ["Voting_AnAdultCanVote"])
    }

    func testSeveralScenariosGiveEachClassOnce() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        let id = ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")
        XCTAssertEqual(try names.classNames(for: [id, id]), ["Voting|AnAdultCanVote"])
    }

    func testRefusesALineThatIsNoScenarioAFileThatIsMissingAndAPathThatFitsTwoFiles() throws {
        try write(voting, to: "A/Features/Voting.feature")
        try write(voting, to: "B/Features/Voting.feature")
        try write(voting, to: "B/Other/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.classNames(for: ScenarioID(feature: "Other/Voting.feature", line: 4, name: ""))) {
            XCTAssertTrue("\($0)".contains("no scenario at line 4"), "\($0)")
        }
        XCTAssertThrowsError(try names.classNames(for: ScenarioID(feature: "Features/Missing.feature", line: 3, name: ""))) {
            XCTAssertTrue("\($0)".contains("No feature file"), "\($0)")
        }
        XCTAssertThrowsError(try names.classNames(for: ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote"))) {
            XCTAssertTrue("\($0)".contains("2 feature files"), "\($0)")
        }
    }
}
