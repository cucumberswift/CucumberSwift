//
//  XcodebuildRunnerTargetTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

/// Which test targets a run of some scenarios starts `xcodebuild` for: only the ones whose bundle holds one of them.
final class XcodebuildRunnerTargetTests: TemporaryFolderTestCase {
    private let target = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS", testTargets: ["A", "B"])
    private let voting = ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")
    private let retiring = ScenarioID(feature: "Features/Retiring.feature", line: 3, name: "A senior can retire")

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

    /// A built bundle of `name` with the feature files in `features`, laid out as macOS (`Contents/Resources`) or iOS does.
    private func makeBundle(_ name: String, features: [String], in copy: URL, macOS: Bool = true) throws {
        let products = copy.deletingLastPathComponent().appendingPathComponent("runner/DerivedData/Build/Products/Debug")
        let resources = products.appendingPathComponent("\(name).xctest").appendingPathComponent(macOS ? "Contents/Resources" : "")
        for feature in features {
            let file = resources.appendingPathComponent(feature)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "Feature: F\n".write(to: file, atomically: true, encoding: .utf8)
        }
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

    /// The test targets that `-only-testing` names in each `xcodebuild test-without-building` call.
    private func testedTargets(_ commands: RecordingCommands) -> [String] {
        commands.calls.filter { $0.arguments.first == "test-without-building" }.compactMap { call in
            call.arguments.firstIndex(of: "-only-testing").map { call.arguments[$0 + 1].components(separatedBy: "/")[0] }
        }
    }

    func testATestTargetWithNoneOfTheScenariosIsNotRun() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Retiring.feature"], in: copy, macOS: false)
        let commands = commands()
        let run = XcodebuildRunner(target: target, commands: commands).test(in: copy, request: TestRequest(scenarios: [voting]))
        XCTAssertEqual(testedTargets(commands), ["A"], "B's bundle has no scenario of the request")
        XCTAssertEqual(run.testsRun, 2, "Only A's result bundle")
        XCTAssertEqual(commands.calls.filter { $0.arguments.first == "test-without-building" }.count, 1)
    }

    func testEachTargetThatHoldsAScenarioIsRun() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Retiring.feature"], in: copy, macOS: false)
        let commands = commands()
        _ = XcodebuildRunner(target: target, commands: commands).test(in: copy, request: TestRequest(scenarios: [voting, retiring]))
        XCTAssertEqual(testedTargets(commands), ["A", "B"])
    }

    func testEveryTargetIsRunWhenItsBundleIsNotFoundOrNoneHoldsAScenario() throws {
        let copy = try makeCopy()
        let unbuilt = commands()
        _ = XcodebuildRunner(target: target, commands: unbuilt).test(in: copy, request: TestRequest(scenarios: [voting]))
        XCTAssertEqual(testedTargets(unbuilt), ["A", "B"], "No bundle is found: nothing says a target can be skipped")
        try makeBundle("A", features: ["Features/Other.feature"], in: copy)
        try makeBundle("B", features: ["Features/Other.feature"], in: copy)
        let none = commands()
        _ = XcodebuildRunner(target: target, commands: none).test(in: copy, request: TestRequest(scenarios: [voting]))
        XCTAssertEqual(testedTargets(none), ["A", "B"], "A run never skips every target")
    }

    func testAFeatureInAResourceBundleInsideATestBundleKeepsItsTarget() throws {
        let copy = try makeCopy()
        // A is found by a feature file next to its tests, and B by one in the resource bundle that SwiftPM makes.
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Pkg_B.bundle/Features/Retiring.feature"], in: copy, macOS: false)
        let both = commands()
        _ = XcodebuildRunner(target: target, commands: both).test(in: copy, request: TestRequest(scenarios: [voting, retiring]))
        XCTAssertEqual(testedTargets(both), ["A", "B"], "B's feature is only in its nested bundle")
        let onlyB = commands()
        _ = XcodebuildRunner(target: target, commands: onlyB).test(in: copy, request: TestRequest(scenarios: [retiring]))
        XCTAssertEqual(testedTargets(onlyB), ["B"])
    }

    func testARunOfEveryScenarioStartsEveryTarget() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Retiring.feature"], in: copy)
        let commands = commands()
        _ = XcodebuildRunner(target: target, commands: commands).test(in: copy, request: TestRequest())
        XCTAssertEqual(testedTargets(commands), ["A", "B"])
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
        XCTAssertEqual(call.arguments.filter { $0 == "-only-testing" }.count, 1, "Only the test target, not a test")
    }
}
