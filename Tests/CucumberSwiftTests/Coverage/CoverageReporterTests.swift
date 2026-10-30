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
        let reporter = CoverageReporter(isEnabled: { true }, coveragePath: { path }, counters: { ProfileCounters(binaries: []) })
        try run(reporter)
        let recorder = try XCTUnwrap(reporter.recorder)
        XCTAssertNotNil(recorder.manifest.problem)
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
}
