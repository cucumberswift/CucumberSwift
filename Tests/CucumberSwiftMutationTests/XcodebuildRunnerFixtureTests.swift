//
//  XcodebuildRunnerFixtureTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

/// Runs one scenario at a time through `xcodebuild`, with the test names that `ScenarioTestNames` makes, on the generated
/// project of `Fixtures/MutationTestingTuist`. Our GitHub Actions CI workflow runs it from
/// `.github/scripts/mutation-xcode-fixture.sh`, which generates the project and sets `MUTATION_XCODE_FIXTURE` to its
/// folder. Without that variable the tests are skipped, because they build a project with `xcodebuild`. The tests run on
/// the destination that `MUTATION_XCODE_DESTINATION` names, `platform=macOS` when it isn't set.
final class XcodebuildRunnerFixtureTests: TemporaryFolderTestCase {
    private var copy: URL!
    private var runner: XcodebuildRunner!

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let path = ProcessInfo.processInfo.environment["MUTATION_XCODE_FIXTURE"], !path.isEmpty else {
            throw XCTSkip("MUTATION_XCODE_FIXTURE names the generated project of Fixtures/MutationTestingTuist")
        }
        // The runner writes next to the copy, so the copy goes in a folder of its own, without the build products.
        copy = folder.appendingPathComponent("package")
        try FileManager.default.createDirectory(at: copy, withIntermediateDirectories: true)
        let source = URL(fileURLWithPath: path)
        for name in try FileManager.default.contentsOfDirectory(atPath: path) where !ProjectFingerprint.ignoredFolders.contains(name) {
            try FileManager.default.copyItem(at: source.appendingPathComponent(name), to: copy.appendingPathComponent(name))
        }
        let target = XcodebuildRunner.Target(
            container: "MutationTestingTuist.xcodeproj",
            scheme: "MutationTestingTuist",
            destination: ProcessInfo.processInfo.environment["MUTATION_XCODE_DESTINATION"].flatMap { $0.isEmpty ? nil : $0 } ?? "platform=macOS",
            testTargets: ["VotingTests", "VotingSwiftTests"]
        )
        runner = XcodebuildRunner(target: target)
        try runner.prepare(copy: copy)
        XCTAssertTrue(runner.build(in: copy, timeout: nil).succeeded)
    }

    /// What the run printed, for a failure's message.
    private func output(of run: TestRun) -> String {
        run.log.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    }

    /// The names of the scenarios in the Cucumber report at `report`.
    private func scenarios(in report: URL?) throws -> [String] {
        let data = try Data(contentsOf: XCTUnwrap(report))
        let features = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        return features.flatMap { ($0["elements"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String } }
    }

    func testRunsOnlyAnXCTestScenario() throws {
        let scenario = ScenarioID(feature: "Features/Driving.feature", line: 7, name: "An adult without a licence cannot drive")
        let run = runner.test(in: copy, request: TestRequest(writesReport: true, scenarios: [scenario]))
        XCTAssertTrue(run.succeeded, output(of: run))
        XCTAssertEqual(run.testsRun, 1, "A test for the scenario, not a test for each step")
        XCTAssertEqual(try scenarios(in: run.cucumberReport), ["An adult without a licence cannot drive"])
    }

    func testRunsOnlyASwiftTestingScenario() throws {
        let scenario = ScenarioID(feature: "Features/Retiring.feature", line: 7, name: "A worker cannot retire")
        let run = runner.test(in: copy, request: TestRequest(writesReport: true, scenarios: [scenario]))
        XCTAssertTrue(run.succeeded, output(of: run))
        XCTAssertEqual(run.testsRun, 1)
        XCTAssertEqual(try scenarios(in: run.cucumberReport), ["A worker cannot retire"])
    }

    func testRunsScenariosOfBothRunnersTogether() throws {
        let scenarios = [
            ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote"),
            ScenarioID(feature: "Features/Retiring.feature", line: 3, name: "A senior can retire")
        ]
        let run = runner.test(in: copy, request: TestRequest(writesReport: true, scenarios: scenarios))
        XCTAssertTrue(run.succeeded, output(of: run))
        XCTAssertEqual(run.testsRun, 2)
    }
}
