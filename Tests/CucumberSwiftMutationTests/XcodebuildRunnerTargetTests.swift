//
//  XcodebuildRunnerTargetTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

/// How a run of some scenarios selects them in `xcodebuild`, when the names of their tests can't be resolved.
final class XcodebuildRunnerTargetTests: TemporaryFolderTestCase {
    private let target = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS", testTargets: ["A", "B"])
    private let voting = ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")

    private func makeCopy() throws -> URL {
        let copy = folder.appendingPathComponent("work/package")
        try FileManager.default.createDirectory(at: copy.appendingPathComponent("Voting.xcodeproj"), withIntermediateDirectories: true)
        // The scenarios' feature files, which the runner reads to name the tests that run them.
        try FileManager.default.createDirectory(at: copy.appendingPathComponent("Features"), withIntermediateDirectories: true)
        for (name, scenario) in [("Voting", "An adult can vote"), ("Retiring", "A senior can retire")] {
            try "Feature: \(name)\n\n  Scenario: \(scenario)\n    Given a person aged 30\n"
                .write(to: copy.appendingPathComponent("Features/\(name).feature"), atomically: true, encoding: .utf8)
        }
        return copy
    }

    private func commands() -> RecordingCommands {
        RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: "{\"totalTestCount\": 2}") }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            return .finished(0, output: "** TEST SUCCEEDED **")
        }
    }

    func testScenariosWhoseTestNamesCantBeResolvedRunThroughCucumberScenariosAlone() throws {
        // The same feature file in two test targets is a path that names no single test: not a failed test.
        let copy = try makeCopy()
        try FileManager.default.createDirectory(at: copy.appendingPathComponent("A/Features"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: copy.appendingPathComponent("B/Features"), withIntermediateDirectories: true)
        for folder in ["A", "B"] {
            try "Feature: Voting\n\n  Scenario: An adult can vote\n    Given a person aged 30\n"
                .write(to: copy.appendingPathComponent("\(folder)/Features/Voting.feature"), atomically: true, encoding: .utf8)
        }
        let commands = commands()
        let run = XcodebuildRunner(target: target, commands: commands).test(
            in: copy, request: TestRequest(scenarios: [voting]))
        XCTAssertEqual(run.status, 0, "The run starts instead of returning a failure that counts as a killed mutant")
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(call.environment["TEST_RUNNER_CUCUMBER_SCENARIOS"], "Features/Voting.feature:3")
        XCTAssertNil(call.environment["TEST_RUNNER_CUCUMBER_ONE_TEST_PER_SCENARIO"])
        XCTAssertEqual(call.arguments.filter { $0 == "-only-testing" }.count, 2, "Each test target, not a test")
    }
}
