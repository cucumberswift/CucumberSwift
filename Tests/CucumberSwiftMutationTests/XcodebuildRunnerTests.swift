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

    func testTheToolsCucumberVariablesReachTheTestsAndTheRequestWins() throws {
        let commands = commands(total: 2)
        let environment = ["CUCUMBER_TAGS": "@smoke", "CUCUMBER_COVERAGE": "YES", "PATH": "/usr/bin", "HOME": "/h"]
        let runner = XcodebuildRunner(target: target, commands: commands, environment: environment)
        _ = runner.test(in: try makeCopy(), request: TestRequest(settings: ["CUCUMBER_COVERAGE": "NO"]))
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_TAGS"], "@smoke")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_COVERAGE"], "NO", "A setting of the request replaces the tool's")
        XCTAssertNil(call.environment["TEST_RUNNER_PATH"], "Only CUCUMBER_ variables are passed on")
        XCTAssertNil(call.environment["TEST_RUNNER_HOME"])
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
        scoped.testTargets = ["VotingTests"]
        let runner = XcodebuildRunner(target: scoped, commands: commands)
        _ = runner.test(in: copy, request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")]))
        let call = try XCTUnwrap(commands.calls.first)
        let index = try XCTUnwrap(call.arguments.firstIndex(of: "-only-testing"))
        XCTAssertEqual(call.arguments[index + 1], "VotingTests/CucumberScenarioTest/Voting \u{203A} An adult can vote")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"], "YES", "-only-testing finds no test of a test per step")
    }

    func testRunsASwiftTestingScenarioByItsGeneratedTestAndLeavesTheTestPerStepOff() throws {
        let copy = try makeCopy()
        let tests = copy.appendingPathComponent("SwiftTests")
        try FileManager.default.createDirectory(at: tests.appendingPathComponent("Features"), withIntermediateDirectories: true)
        try "import CucumberSwiftTesting\n".write(to: tests.appendingPathComponent("StepDefinitions.swift"), atomically: true, encoding: .utf8)
        try """
        Feature: Retiring

          Scenario: A senior can retire
            Given a person aged 70
            Then the person can retire
        """.write(to: tests.appendingPathComponent("Features/Retiring.feature"), atomically: true, encoding: .utf8)
        let commands = commands(total: 3)
        var scoped = target
        scoped.testTargets = ["VotingSwiftTests"]
        _ = XcodebuildRunner(target: scoped, commands: commands)
            .test(in: copy, request: TestRequest(scenarios: [ScenarioID(feature: "Features/Retiring.feature", line: 3, name: "")]))
        let call = try XCTUnwrap(commands.calls.first)
        let index = try XCTUnwrap(call.arguments.firstIndex(of: "-only-testing"))
        XCTAssertEqual(call.arguments[index + 1], "VotingSwiftTests/CucumberFeatures/Retiring/ASeniorCanRetire(_:)")
        XCTAssertNil(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"], "Only an XCTest scenario needs it")
    }

    func testAScenarioIsSelectedInEveryTestTargetBecauseItDoesntSayWhichHoldsIt() throws {
        let copy = try makeCopy()
        try FileManager.default.createDirectory(at: copy.appendingPathComponent("Features"), withIntermediateDirectories: true)
        try "Feature: Voting\n\n  Scenario: An adult can vote\n    Given a person aged 30\n"
            .write(to: copy.appendingPathComponent("Features/Voting.feature"), atomically: true, encoding: .utf8)
        let commands = commands(total: 1)
        var scoped = target
        scoped.testTargets = ["A", "B"]
        _ = XcodebuildRunner(target: scoped, commands: commands)
            .test(in: copy, request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "")]))
        let selected = commands.calls.compactMap { call in
            call.arguments.firstIndex(of: "-only-testing").map { call.arguments[$0 + 1] }
        }
        let test = "CucumberScenarioTest/Voting \u{203A} An adult can vote"
        XCTAssertEqual(selected, ["A/\(test)", "B/\(test)"], "One run for each test target")
    }

    func testSeveralTestTargetsRunOneAtATimeWithAReportEach() throws {
        let commands = RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: self.summary(2)) }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            if let path = call.environment["TEST_RUNNER_CUCUMBER_REPORT_PATH"] {
                let name = call.arguments.contains("A") ? "Feature A" : "Feature B"
                try? FileManager.default.createDirectory(atPath: URL(fileURLWithPath: path).deletingLastPathComponent().path, withIntermediateDirectories: true)
                try? "[{\"name\": \"\(name)\", \"elements\": []}]".write(toFile: path, atomically: true, encoding: .utf8)
            }
            return .finished(0, output: "** TEST SUCCEEDED **")
        }
        var scoped = target
        scoped.testTargets = ["A", "B"]
        let run = XcodebuildRunner(target: scoped, commands: commands).test(in: try makeCopy(), request: TestRequest(writesReport: true))
        let tests = commands.calls.filter { $0.arguments.first == "test-without-building" }
        XCTAssertEqual(tests.count, 2)
        XCTAssertEqual(tests.map { value(after: "-only-testing", in: $0.arguments) }, ["A", "B"], "Each run selects its own target")
        XCTAssertEqual(Set(tests.compactMap { $0.environment["TEST_RUNNER_CUCUMBER_REPORT_PATH"] }).count, 2, "A report of its own, so one doesn't replace the other")
        XCTAssertEqual(run.testsRun, 4, "The tests of both result bundles")
        let merged = try JSONSerialization.jsonObject(with: Data(contentsOf: XCTUnwrap(run.cucumberReport))) as? [[String: Any]]
        XCTAssertEqual(merged?.compactMap { $0["name"] as? String }, ["Feature A", "Feature B"])
    }

    func testOneNamedTestTargetLimitsTheRunToThatTarget() throws {
        let named = commands(total: 3)
        var scoped = target
        scoped.testTargets = ["A"]
        _ = XcodebuildRunner(target: scoped, commands: named).test(in: try makeCopy(), request: TestRequest())
        let call = try XCTUnwrap(named.calls.first { $0.arguments.first == "test-without-building" })
        XCTAssertEqual(call.arguments.firstIndex(of: "-only-testing").map { call.arguments[$0 + 1] }, "A")
        let none = commands(total: 3)
        _ = XcodebuildRunner(target: target, commands: none).test(in: try makeCopy(), request: TestRequest())
        XCTAssertFalse(try XCTUnwrap(none.calls.first).arguments.contains("-only-testing"), "No test target named: every test of the scheme")
    }

    func testOneFailedTestTargetFailsTheRun() throws {
        let commands = RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: self.summary(1)) }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            return .finished(call.arguments.contains("B") ? 65 : 0, output: "")
        }
        var scoped = target
        scoped.testTargets = ["A", "B"]
        let run = XcodebuildRunner(target: scoped, commands: commands).test(in: try makeCopy(), request: TestRequest())
        XCTAssertEqual(run.status, 65)
        XCTAssertFalse(run.succeeded)
    }

    func testARunOfAllTheScenariosKeepsTheTestPerStep() throws {
        let commands = commands(total: 1)
        _ = XcodebuildRunner(target: target, commands: commands).test(in: try makeCopy(), request: TestRequest())
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertFalse(call.arguments.contains("-only-testing"))
        XCTAssertNil(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"])
    }

    func testScenariosWithoutTheTestTargetsRunThroughCucumberScenariosAlone() throws {
        let commands = commands(total: 1)
        let run = XcodebuildRunner(target: target, commands: commands).test(
            in: try makeCopy(), request: TestRequest(scenarios: [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "")]))
        XCTAssertEqual(run.status, 0)
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertFalse(call.arguments.contains("-only-testing"), "Without test targets there is no name to select")
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_SCENARIOS"], "Features/Voting.feature:3")
    }

    func testReadsTheTestCountOfASummary() {
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: summary(12)), 12)
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: "not json"), 0)
        XCTAssertEqual(XcodebuildRunner.testCount(inSummary: "{}"), 0)
    }
}
