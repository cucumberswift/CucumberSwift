//
//  SkippedStepTests.swift
//  CucumberSwiftTests
//
//  A step that throws XCTSkip skips the rest of its scenario, so Xcode shows those steps as skipped (#59),
//  and so does a step that fails (#87).
//
import Foundation
import XCTest
@testable import CucumberSwift

class SkippedStepTests: XCTestCase {
    private static func resetCucumber() {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        StepTestCase.skippedScenarios.removeAll()
    }

    override func setUpWithError() throws {
        Self.resetCucumber()
        addTeardownBlock { Self.resetCucumber() }
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
        StepTestCase.skippedScenarios.append((try XCTUnwrap(steps.first?.scenario), "The card terminal is offline"))

        XCTAssertEqual(StepTestCase.skipReason(for: steps[1]), "Skipped: The card terminal is offline")
        XCTAssertNil(StepTestCase.skipReason(for: steps[2]))
    }

    // A step that records a failure and then throws XCTSkip must still be reported as failed.
    func testAFailedStepThatThenSkipsStaysFailed() throws {
        let steps = steps()
        steps[0].result = .failed("XCTAssertEqual failed")
        steps[0].recordSkip(XCTSkip("Not today"))

        XCTAssertEqual(steps[0].result, .failed)
        XCTAssertEqual(StepTestCase.skipReason(for: steps[1]), "Skipped: Not today")
    }

    func testAStepThatSkipsIsReportedAsSkipped() {
        let steps = steps()
        steps[0].recordSkip(XCTSkip("Not today"))

        XCTAssertEqual(steps[0].result, .skipped)
    }

    func testAFailureSkipsTheStepsAfterItInItsScenarioOnly() throws {
        let steps = steps()
        Cucumber.shared.failedScenarios.append(try XCTUnwrap(steps.first?.scenario))

        XCTAssertEqual(StepTestCase.skipReason(for: steps[1]), StepTestCase.skippedAfterFailureMessage)
        XCTAssertNil(StepTestCase.skipReason(for: steps[2]))
    }
}
