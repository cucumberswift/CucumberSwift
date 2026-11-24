//
//  XcodebuildRunnerTargetTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

/// Which test targets the one `xcodebuild` run of some scenarios names: only the ones whose bundle holds one of them.
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

    /// The `.xctestrun` file of `build-for-testing`, which says which bundle each test target builds: the older format,
    /// with a dictionary for each target, or the newer one, with the targets of a test configuration.
    private func makeXCTestRun(_ bundles: [String: String], in copy: URL, newFormat: Bool = false) throws {
        let products = copy.deletingLastPathComponent().appendingPathComponent("runner/DerivedData/Build/Products")
        try FileManager.default.createDirectory(at: products, withIntermediateDirectories: true)
        let path = { (bundle: String) in "__TESTROOT__/Debug/\(bundle).xctest" }
        let plist: [String: Any] = newFormat
            ? ["TestConfigurations": [["TestTargets": bundles.map { ["BlueprintName": $0.key, "TestBundlePath": path($0.value)] }]]]
            : bundles.mapValues { ["TestBundlePath": path($0)] }
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: products.appendingPathComponent("Scheme_iphonesimulator.xctestrun"))
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

    /// The test targets that `-only-testing` names in the one `xcodebuild test-without-building` call, in order.
    private func testedTargets(_ commands: RecordingCommands, call number: Int = 1) -> [String] {
        let calls = commands.calls.filter { $0.arguments.first == "test-without-building" }
        XCTAssertEqual(calls.count, number, "All the test targets run in one xcodebuild run")
        var targets = [String]()
        for (index, argument) in (calls.last?.arguments ?? []).enumerated() where argument == "-only-testing" {
            let name = calls[calls.count - 1].arguments[index + 1].components(separatedBy: "/")[0]
            if !targets.contains(name) { targets.append(name) }
        }
        return targets
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

    /// A coverage run of every scenario, with a test bundle `bundle` whose process ran the features at `features`, as the
    /// manifest of its run folder says.
    private func measuringCommands(bundle: String?, features: [String]) -> RecordingCommands {
        measuringCommands(bundles: bundle.map { [$0] } ?? [], features: features)
    }

    private func measuringCommands(bundles: [String], features: [String]) -> RecordingCommands {
        measuringCommands(runs: [bundles], features: features)
    }

    /// Each coverage run of the commands names the bundles of the next of `runs`, the last one again once they are used.
    private func measuringCommands(runs: [[String]], features: [String]) -> RecordingCommands {
        var measured = 0
        return RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: "{\"totalTestCount\": 2}") }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            if let path = call.environment["TEST_RUNNER_CUCUMBER_COVERAGE_PATH"] {
                let bundles = runs[min(measured, runs.count - 1)]
                measured += 1
                let run = URL(fileURLWithPath: path).appendingPathComponent("run-1")
                try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                let manifest: [String: Any] = [
                    "binaries": bundles.map { ["path": "/x/Build/Products/Debug/\($0).xctest/Contents/MacOS/\($0)"] },
                    "features": features.map { ["feature": $0] }
                ]
                try? JSONSerialization.data(withJSONObject: manifest).write(to: run.appendingPathComponent("manifest.json"))
            }
            return .finished(0, output: "** TEST SUCCEEDED **")
        }
    }

    func testATargetThatRanACoveringSwiftDSLScenarioIsTheOneRun() throws {
        let copy = try makeCopy()
        // B's bundle holds no feature file of the scenario, and a DSL scenario has none: its feature is the Swift file that
        // declares it. The coverage run says which target ran it.
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Other.feature"], in: copy, macOS: false)
        try makeXCTestRun(["A": "A", "B": "B"], in: copy)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        let runner = { (commands: RecordingCommands) in XcodebuildRunner(target: self.target, commands: commands) }
        let unknown = commands()
        _ = runner(unknown).test(in: copy, request: TestRequest(scenarios: [voting, dsl]))
        XCTAssertEqual(testedTargets(unknown), ["A", "B"], "Nothing says which target holds the DSL scenario: every one runs")

        let measuring = measuringCommands(bundle: "B", features: [swiftFile])
        let learning = runner(measuring)
        _ = learning.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = learning.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(measuring, call: 2), ["B"], "Only B ran the DSL scenario in the coverage run")
        _ = learning.test(in: copy, request: TestRequest(scenarios: [voting, dsl]))
        XCTAssertEqual(testedTargets(measuring, call: 3), ["A", "B"], "A holds the feature file, B ran the DSL scenario")
    }

    func testARunWithNoTestBundleInItsManifestTeachesNoTarget() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Other.feature"], in: copy, macOS: false)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        let measuring = measuringCommands(bundle: nil, features: [swiftFile])
        let runner = XcodebuildRunner(target: target, commands: measuring)
        _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = runner.test(in: copy, request: TestRequest(scenarios: [voting, dsl]))
        XCTAssertEqual(testedTargets(measuring, call: 2), ["A", "B"], "No binary is no evidence: every target runs")
    }

    func testARunWithNoTestBundleAfterOneThatNamedItKeepsEveryTarget() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Other.feature"], in: copy, macOS: false)
        try makeXCTestRun(["A": "A", "B": "B"], in: copy)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        let measuring = measuringCommands(runs: [["A"], []], features: [swiftFile])
        let runner = XcodebuildRunner(target: target, commands: measuring)
        _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = runner.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(measuring, call: 2), ["A"], "Only A ran the scenario so far")
        _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = runner.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(measuring, call: 4), ["A", "B"], "A run that named no bundle may have been B's")
    }

    func testABundleNameIsATargetsOnlyAsTheXCTestRunFileSays() throws {
        let copy = try makeCopy()
        // A builds `Alpha.xctest` and B builds `A.xctest`: B's run names the bundle `A`, which is no sign of target A.
        try makeBundle("Alpha", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("A", features: ["Features/Other.feature"], in: copy, macOS: false)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        for newFormat in [false, true] {
            let tied = measuringCommands(bundle: "A", features: [swiftFile])
            try makeXCTestRun(["A": "Alpha", "B": "A"], in: copy, newFormat: newFormat)
            let runner = XcodebuildRunner(target: target, commands: tied)
            _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
            _ = runner.test(in: copy, request: TestRequest(scenarios: [dsl]))
            XCTAssertEqual(testedTargets(tied, call: 2), ["B"], "The file ties `A.xctest` to B (new format: \(newFormat))")
        }
    }

    func testSwappedProductsKeepTheTargetThatRanTheScenario() throws {
        // A builds `B.xctest` and B builds `A.xctest`: every target has a bundle of its own name, so only the
        // `.xctestrun` file tells that `A.xctest`, which B's run names, is B's.
        let copy = try makeCopy()
        try makeBundle("B", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("A", features: ["Features/Other.feature"], in: copy, macOS: false)
        try makeXCTestRun(["A": "B", "B": "A"], in: copy)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        let swapped = measuringCommands(bundle: "A", features: [swiftFile])
        let runner = XcodebuildRunner(target: target, commands: swapped)
        _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = runner.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(swapped, call: 2), ["B"], "Swapped products: `A.xctest` is B's, not A's")
    }

    func testEveryTargetRunsWhenNoXCTestRunFileTiesALearnedBundleToATarget() throws {
        let copy = try makeCopy()
        try makeBundle("A", features: ["Features/Voting.feature"], in: copy)
        try makeBundle("B", features: ["Features/Other.feature"], in: copy, macOS: false)
        let swiftFile = copy.appendingPathComponent("Tests/B/RetiringFeature.swift").path
        let dsl = ScenarioID(uri: swiftFile, line: 12, name: "A senior can retire")
        let withoutFile = measuringCommands(bundle: "B", features: [swiftFile])
        let runner = XcodebuildRunner(target: target, commands: withoutFile)
        _ = runner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = runner.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(withoutFile, call: 2), ["A", "B"], "No file: nothing ties `B` to a target")

        try makeXCTestRun(["A": "A", "B": "B"], in: copy)
        let unknown = measuringCommands(bundles: ["A", "Ghost"], features: [swiftFile])
        let unknownRunner = XcodebuildRunner(target: target, commands: unknown)
        _ = unknownRunner.test(in: copy, request: TestRequest(measuresCoverage: true))
        _ = unknownRunner.test(in: copy, request: TestRequest(scenarios: [dsl]))
        XCTAssertEqual(testedTargets(unknown, call: 2), ["A", "B"], "`Ghost` is in no target: A alone must not be chosen")
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
        XCTAssertEqual(call.arguments.filter { $0 == "-only-testing" }.count, 2, "Each test target, not a test")
    }
}
#endif
