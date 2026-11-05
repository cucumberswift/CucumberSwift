//
//  XcodebuildRunnerTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class XcodebuildRunnerTests: TemporaryFolderTestCase {
    private let target = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS")

    private func makeCopy(container: String = "Voting.xcodeproj") throws -> URL {
        let copy = folder.appendingPathComponent("work/package")
        try FileManager.default.createDirectory(at: copy.appendingPathComponent(container), withIntermediateDirectories: true)
        return copy
    }

    /// The argument after `flag`.
    private func value(after flag: String, in arguments: [String]) -> String? {
        arguments.firstIndex(of: flag).flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
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
        XCTAssertEqual(value(after: "-enableCodeCoverage", in: arguments), "YES")
        XCTAssertEqual(calls[0].timeout, 90)
        let derivedData = try XCTUnwrap(value(after: "-derivedDataPath", in: arguments))
        XCTAssertEqual(value(after: "-derivedDataPath", in: calls[1].arguments), derivedData, "Each build reuses the products")
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

    func testSettingsReachTheTestsAsPrefixedVariablesInXcodebuildsEnvironment() throws {
        let commands = commands(total: 6)
        let runner = XcodebuildRunner(target: target, commands: commands)
        let copy = try makeCopy()
        let run = runner.test(in: copy, request: TestRequest(settings: ["CUCUMBERSWIFT_MUTANT": "3", "CUCUMBER_COVERAGE": "NO"], writesReport: true))
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(call.arguments.first, "test-without-building")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBERSWIFT_MUTANT"], "3")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_COVERAGE"], "NO")
        XCTAssertTrue(call.environment["TEST_RUNNER_CUCUMBER_REPORT_PATH"]?.contains("/runner/reports/") == true)
        XCTAssertNil(call.environment["CUCUMBERSWIFT_MUTANT"], "Unprefixed, the variable would reach xcodebuild and not the tests")
        XCTAssertFalse(call.arguments.contains { $0.hasPrefix("TEST_RUNNER_") }, "A TEST_RUNNER_ build setting never reaches the tests")
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

    func testRunsOnlyTheTestsOfTheScenariosWithATestForEachScenario() throws {
        let copy = try makeCopy()
        let features = copy.appendingPathComponent("Features")
        try FileManager.default.createDirectory(at: features, withIntermediateDirectories: true)
        try """
        Feature: Voting

          Scenario: An adult can vote
            Given a person aged 30
            Then the person can vote
        """.write(to: features.appendingPathComponent("Voting.feature"), atomically: true, encoding: .utf8)
        let commands = commands(total: 1)
        var scoped = target
        scoped.testTarget = "VotingTests"
        let runner = XcodebuildRunner(target: scoped, commands: commands)
        _ = runner.test(in: copy, request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")]))
        let call = try XCTUnwrap(commands.calls.first)
        let index = try XCTUnwrap(call.arguments.firstIndex(of: "-only-testing"))
        XCTAssertEqual(call.arguments[index + 1], "VotingTests/CucumberScenarioTest/Voting \u{203A} An adult can vote")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"], "YES", "-only-testing finds no test of a test per step")
    }

    func testARunOfAllTheScenariosKeepsTheTestPerStep() throws {
        let commands = commands(total: 1)
        _ = XcodebuildRunner(target: target, commands: commands).test(in: try makeCopy(), request: TestRequest())
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertFalse(call.arguments.contains("-only-testing"))
        XCTAssertNil(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"])
    }

    func testScenariosNeedTheTestTarget() throws {
        let commands = commands(total: 1)
        let run = XcodebuildRunner(target: target, commands: commands).test(
            in: try makeCopy(), request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "")]))
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
