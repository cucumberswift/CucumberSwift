//
//  SkippedStepTests.swift
//  CucumberSwiftTests
//
//  A step that throws XCTSkip skips the rest of its scenario, so Xcode shows those steps as skipped (#59),
//  and so does a step that fails (#87).
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class SkippedStepTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        Cucumber.shared.skippedScenarios.removeAll()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        Cucumber.shared.skippedScenarios.removeAll()
    }

    private func steps() -> [Step] {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             Then some outcome
           Scenario: Some other situation
             Given some precondition
        """)
        return Cucumber.shared.features.flatMap { $0.scenarios.flatMap(\.steps) }
    }

    func testAStepRunsWhileNoEarlierStepSkippedItsScenario() {
        XCTAssertNil(StepTestCase.skipReason(for: steps()[1]))
    }

    // A step that throws XCTSkip skips the rest of its scenario, and says why.
    func testAStepIsSkippedWithTheReasonAnEarlierStepSkippedItsScenarioFor() throws {
        let steps = steps()
        Cucumber.shared.skippedScenarios.append((try XCTUnwrap(steps.first?.scenario), "The card terminal is offline"))

        XCTAssertEqual(StepTestCase.skipReason(for: steps[1]), "Skipped: The card terminal is offline")
        XCTAssertNil(StepTestCase.skipReason(for: steps[2]))
    }

    func testAFailureSkipsTheStepsAfterItInItsScenarioOnly() throws {
        let steps = steps()
        Cucumber.shared.failedScenarios.append(try XCTUnwrap(steps.first?.scenario))

        XCTAssertEqual(StepTestCase.skipReason(for: steps[1]), StepTestCase.skippedAfterFailureMessage)
        XCTAssertNil(StepTestCase.skipReason(for: steps[2]))
    }
}
