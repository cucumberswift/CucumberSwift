//
//  VerboseReporterTests.swift
//  CucumberSwift
//
//  Copyright © 2026 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

@testable import CucumberSwift

@MainActor
final class VerboseReporterTests: XCTestCase {
    func testIsEnabledOnlyForOneOrTrue() {
        let key = VerboseReporter.environmentKey
        XCTAssertTrue(VerboseReporter.isEnabled(in: [key: "1"]))
        XCTAssertTrue(VerboseReporter.isEnabled(in: [key: "true"]))
        XCTAssertTrue(VerboseReporter.isEnabled(in: [key: " TRUE "]))
        XCTAssertFalse(VerboseReporter.isEnabled(in: [key: "0"]))
        XCTAssertFalse(VerboseReporter.isEnabled(in: [key: "false"]))
        XCTAssertFalse(VerboseReporter.isEnabled(in: [key: ""]))
        XCTAssertFalse(VerboseReporter.isEnabled(in: [:]))
    }

    func testWritesFeatureScenarioAndStepWithResults() throws {
        var lines = [String]()
        let reporter = VerboseReporter { lines.append($0) }
        let cucumber = Cucumber(withString: """
        Feature: Greeting
            Scenario: Say hello
                Given a friendly user
        """)
        let feature = try XCTUnwrap(cucumber.features.first)
        let scenario = try XCTUnwrap(feature.scenarios.first)
        let step = try XCTUnwrap(scenario.steps.first)
        let duration = Measurement(value: 1.5, unit: UnitDuration.seconds)

        reporter.didStart(feature: feature, at: Date())
        reporter.didStart(scenario: scenario, at: Date())
        reporter.didStart(step: step, at: Date())
        reporter.didFinish(step: step, result: .failed("boom"), duration: duration)
        reporter.didFinish(scenario: scenario, result: .passed, duration: duration)
        reporter.didFinish(feature: feature, result: .skipped, duration: duration)

        XCTAssertEqual(lines, [
            "[CucumberSwift] Feature: Greeting",
            "[CucumberSwift]   Scenario: Say hello",
            "[CucumberSwift]     Given a friendly user",
            "[CucumberSwift]       -> failed: boom (1.500s)",
            "[CucumberSwift]   Scenario \"Say hello\" passed (1.500s)",
            "[CucumberSwift] Feature \"Greeting\" skipped (1.500s)"
        ])
    }

    func testCucumberInstallsTheReporterOnlyWhenAsked() {
        let quiet = Cucumber()
        quiet.environment = [:]
        XCTAssertFalse(quiet.reporters.contains { $0 is VerboseReporter })

        let verbose = Cucumber()
        verbose.environment = [VerboseReporter.environmentKey: "1"]
        XCTAssertTrue(verbose.reporters.contains { $0 is VerboseReporter })
        verbose.reporters = [] // the instance stays registered with XCTest, so keep it from printing
    }
}
