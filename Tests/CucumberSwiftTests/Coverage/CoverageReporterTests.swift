//
//  CoverageReporterTests.swift
//  CucumberSwiftTests
//
//  The runner's coverage reporter reads whether coverage is on when the first scenario starts, and writes
//  each scenario's profile and the manifest (#502). The tests that write profiles need this bundle built
//  with code coverage, as our CI's iOS job builds it, and are skipped otherwise.
//

import Foundation
import XCTest
@testable import CucumberSwift

@MainActor
final class CoverageReporterTests: XCTestCase {
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CoverageReporterTests-\(UUID().uuidString)")
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    /// Runs one scenario through the reporter, and returns the line CucumberSwift gives the scenario.
    @discardableResult
    private func run(_ reporter: CoverageReporter) throws -> Int {
        let cucumber = Cucumber(withString: """
        Feature: Greeting
            @friendly
            Scenario: Say hello
                Given a friendly user
        """)
        let feature = try XCTUnwrap(cucumber.features.first)
        let scenario = try XCTUnwrap(feature.scenarios.first)
        let duration = Measurement(value: 1, unit: UnitDuration.seconds)
        reporter.testSuiteStarted(at: Date())
        reporter.didStart(feature: feature, at: Date())
        reporter.didStart(scenario: scenario, at: Date())
        reporter.didFinish(scenario: scenario, result: .passed, duration: duration)
        reporter.didFinish(feature: feature, result: .passed, duration: duration)
        reporter.testSuiteFinished(at: Date())
        return Int(scenario.location.line)
    }

    /// A function with two branches, for a step to run one of.
    private static func branch(of value: Int) -> Int {
        if value < 10 {
            return 1
        }
        return 2
    }

    func testTheReporterLeavesTheBackgroundsStepsOutOfTheRedundantSteps() throws {
        try XCTSkipIf(ProfileCounters.loaded().binaries.isEmpty, "This bundle wasn't built with code coverage.")
        let path = folder.path
        let reporter = CoverageReporter(isEnabled: { true }, coveragePath: { path }, settings: {
            var settings = CoverageSettings()
            settings.sources = ["CoverageReporterTests.swift"]
            return settings
        })
        let cucumber = Cucumber(withString: """
        Feature: Greeting
            Background:
                Given a greeting
            Scenario: Waving once
                When I wave
            Scenario: Waving twice
                When I wave again
        """)
        let feature = try XCTUnwrap(cucumber.features.first)
        let duration = Measurement(value: 1, unit: UnitDuration.seconds)
        var stepLines = [Int]()
        for scenario in feature.scenarios {
            reporter.didStart(scenario: scenario, at: Date())
            for (index, step) in scenario.steps.enumerated() {
                reporter.didStart(step: step, at: Date())
                // The Background's step runs one branch, and each scenario's own step the other.
                _ = Self.branch(of: index < scenario.backgroundStepCount ? 20 : 1)
                reporter.didFinish(step: step, result: .passed, duration: duration)
                if index >= scenario.backgroundStepCount { stepLines.append(Int(step.location.line)) }
            }
            reporter.didFinish(scenario: scenario, result: .passed, duration: duration)
        }
        reporter.didFinish(feature: feature, result: .passed, duration: duration)

        let scores = try XCTUnwrap(reporter.recorder?.manifest.features.first?.scores)
        // Only the scenarios' own steps are compared, and each repeats the other's.
        XCTAssertEqual(scores.redundantSteps.map(\.line), stepLines)
        XCTAssertEqual(scores.redundantSteps.map(\.similarTo), stepLines.reversed())
    }

    func testWithCoverageOffNothingIsWritten() throws {
        let path = folder.path
        let reporter = CoverageReporter(isEnabled: { false }, coveragePath: { path })
        try run(reporter)
        XCTAssertNil(reporter.recorder)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }

    func testWithCoverageOnTheScenarioAndTheManifestAreWritten() throws {
        try XCTSkipIf(ProfileCounters.loaded().binaries.isEmpty, "This bundle wasn't built with code coverage.")
        let path = folder.path
        let reporter = CoverageReporter(isEnabled: { true }, coveragePath: { path })
        let line = try run(reporter)

        let recorder = try XCTUnwrap(reporter.recorder)
        XCTAssertTrue(FileManager.default.fileExists(atPath: recorder.folder.appendingPathComponent("manifest.json").path))
        let scenario = try XCTUnwrap(recorder.manifest.scenarios.first)
        XCTAssertEqual(scenario.featureName, "Greeting")
        XCTAssertEqual(scenario.name, "Say hello")
        XCTAssertEqual(scenario.line, line)
        XCTAssertEqual(scenario.tags, ["friendly"])
        XCTAssertFalse(scenario.profiles.isEmpty)
    }

    func testAProblemIsPrintedWhenTheRunEnds() throws {
        let path = folder.path
        var printed = [String]()
        let reporter = CoverageReporter(isEnabled: { true },
                                        coveragePath: { path },
                                        counters: { ProfileCounters(binaries: []) },
                                        output: { printed.append($0) })
        try run(reporter)
        let recorder = try XCTUnwrap(reporter.recorder)
        let problem = try XCTUnwrap(recorder.manifest.problem)
        XCTAssertEqual(printed, ["CucumberSwift coverage: \(problem)", "CucumberSwift coverage: 0 scenarios in \(recorder.folder.path)"])
        XCTAssertEqual(recorder.manifest.scenarios, [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: recorder.folder.appendingPathComponent("manifest.json").path))
    }

    func testARunWhoseFolderIsGoneEndsWithoutAManifest() throws {
        let path = folder.path
        let reporter = CoverageReporter(isEnabled: { true }, coveragePath: { path }, counters: { ProfileCounters(binaries: []) })
        let cucumber = Cucumber(withString: "Feature: F\n  Scenario: S\n    Given a step")
        let feature = try XCTUnwrap(cucumber.features.first)
        let scenario = try XCTUnwrap(feature.scenarios.first)
        reporter.didStart(scenario: scenario, at: Date())
        let recorder = try XCTUnwrap(reporter.recorder)
        try FileManager.default.removeItem(at: recorder.folder)
        reporter.testSuiteFinished(at: Date())
        XCTAssertFalse(FileManager.default.fileExists(atPath: recorder.folder.appendingPathComponent("manifest.json").path))
    }

    func testAnOutlinesExamplesShareAGroupThatNoOtherScenarioHas() throws {
        let cucumber = Cucumber(withString: """
        Feature: Classifying
            Background:
                Given a calculator
            Scenario: Zero
                When I classify 0
            Scenario Outline: Small numbers
                When I classify <number>
                Examples:
                    | number |
                    | 1      |
                    | 2      |
        """)
        let scenarios = try XCTUnwrap(cucumber.features.first).scenarios
        XCTAssertEqual(scenarios.count, 3)
        let groups = scenarios.map(CoverageReporter.group(of:))
        XCTAssertEqual(groups[1], groups[2])
        XCTAssertNotEqual(groups[0], groups[1])
        XCTAssertNotEqual(scenarios[1].location.line, scenarios[2].location.line)
    }

    func testScenariosWithOnlyTheBackgroundsStepsAreGroupsOfTheirOwn() throws {
        let cucumber = Cucumber(withString: """
        Feature: Starting
            Background:
                Given a calculator
            Scenario: Once
            Scenario: Twice
        """)
        let groups = try XCTUnwrap(cucumber.features.first).scenarios.map(CoverageReporter.group(of:))
        XCTAssertEqual(groups, ["line 4", "line 5"])
    }

    func testAScenarioInARuleKnowsTheRuleAndOneOutsideDoesNot() throws {
        let cucumber = Cucumber(withString: """
        Feature: Arithmetic
            Scenario: Adding
                Given a calculator
            @numbers
            Rule: Classifying
                Scenario: Small numbers
                    Given a calculator
                Scenario Outline: More numbers
                    When I classify <number>
                    Examples:
                        | number |
                        | 1      |
        """)
        let scenarios = try XCTUnwrap(cucumber.features.first).scenarios
        XCTAssertEqual(scenarios.count, 3)
        XCTAssertNil(scenarios[0].rule)
        // The Rule's line is its keyword's, not its tag's.
        XCTAssertEqual(scenarios[1].rule, ScenarioRule(title: "Classifying", line: 5))
        XCTAssertEqual(scenarios[2].rule, ScenarioRule(title: "Classifying", line: 5))
    }

    func testAScenarioKnowsHowManyOfItsStepsAreItsBackgrounds() throws {
        let cucumber = Cucumber(withString: """
        Feature: Arithmetic
            Background:
                Given a calculator
            Scenario: Adding
                When I add 2 and 3
            Rule: Classifying
                Background:
                    Given a clear display
                Scenario Outline: Naming
                    When I classify <number>
                    Examples:
                        | number |
                        | 1      |
                        | 2      |
        """)
        let scenarios = try XCTUnwrap(cucumber.features.first).scenarios
        XCTAssertEqual(scenarios.map(\.backgroundStepCount), [1, 2, 2])
        XCTAssertEqual(scenarios.map(\.steps.count), [2, 3, 3])
    }
}
