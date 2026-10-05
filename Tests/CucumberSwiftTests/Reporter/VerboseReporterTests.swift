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
    private var originalVerbose = false

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalVerbose = Cucumber.verboseOutput
        Cucumber.verboseOutput = false
    }

    override func tearDownWithError() throws {
        Cucumber.verboseOutput = originalVerbose
        Cucumber.implementationVerbose = false
        try super.tearDownWithError()
    }

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

    // A step's keyword is written in its own feature file's language, not the last parsed file's (#290).
    func testWritesEachStepsKeywordInItsFeatureFilesLanguage() throws {
        var lines = [String]()
        let reporter = VerboseReporter { lines.append($0) }
        let cucumber = Cucumber(withString: """
        Feature: Basket
            Scenario: Eating cukes
                Given I have 3 cukes
        """)
        cucumber.parseIntoFeatures("""
        # language: es
        Característica: Pepinos
            Escenario: Comer pepinos
                Cuando como 2 pepinos
        """)
        let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }

        steps.forEach { reporter.didStart(step: $0, at: Date()) }

        XCTAssertEqual(lines, [
            "[CucumberSwift]     Given I have 3 cukes",
            "[CucumberSwift]     Cuando como 2 pepinos"
        ])
    }

    // A step is written with the form of its keyword the feature file uses, not the language's last one (#332).
    func testWritesEachStepsKeywordAsWritten() throws {
        defer { Scope.language = .default }
        var lines = [String]()
        let reporter = VerboseReporter { lines.append($0) }
        let cucumber = Cucumber(withString: """
        # language: es
        Característica: Una cesta de pepinos
            Escenario: Llenar la cesta
                Dado tengo 4 pepinos en mi "cesta"
                Y como 1 pepino
        """)
        let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }

        steps.forEach { reporter.didStart(step: $0, at: Date()) }

        XCTAssertEqual(lines, [
            "[CucumberSwift]     Dado tengo 4 pepinos en mi \"cesta\"",
            "[CucumberSwift]     Y como 1 pepino"
        ])
    }

    func testStaysQuietUntilEnabled() throws {
        var enabled = false
        var lines = [String]()
        let reporter = VerboseReporter(isEnabled: { enabled }, write: { lines.append($0) })

        reporter.testSuiteStarted(at: Date())
        XCTAssertTrue(lines.isEmpty)
        enabled = true // as `setupSteps()` does, after the reporter exists
        reporter.testSuiteFinished(at: Date())
        XCTAssertEqual(lines, ["[CucumberSwift] Test suite finished"])
    }

    func testCucumberIsVerboseOnlyWhenAsked() {
        let cucumber = Cucumber()
        cucumber.environment = [:]
        XCTAssertFalse(cucumber.isVerbose)

        cucumber.environment = [VerboseReporter.environmentKey: "1"]
        XCTAssertTrue(cucumber.isVerbose)

        cucumber.environment = [:]
        Cucumber.verboseOutput = true
        XCTAssertTrue(cucumber.isVerbose)

        Cucumber.verboseOutput = false
        Cucumber.implementationVerbose = true
        XCTAssertTrue(cucumber.isVerbose)
        cucumber.reporters = []
    }

    func testCucumberAlwaysHasTheReporterSoALateSettingTakesEffect() {
        let cucumber = Cucumber()
        XCTAssertTrue(cucumber.reporters.contains { $0 is VerboseReporter })
        cucumber.reporters = []
    }
}
