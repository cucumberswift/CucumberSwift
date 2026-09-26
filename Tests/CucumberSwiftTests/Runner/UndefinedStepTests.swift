//
//  UndefinedStepTests.swift
//  CucumberSwiftTests
//
//  Regression coverage for the silent no-op step bug: a step registered with an anchored
//  regex string (`^...$`) and a wildcard `{ _, _ in }` closure resolves to the
//  `CucumberExpression` overload instead of the deprecated regex-`String` overload, so the
//  anchored pattern never matches the literal Gherkin step text and the closure never
//  attaches. `Step.canExecute` stays `false`, but the step's own XCTest method used to
//  report "passed" regardless.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class UndefinedStepTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        CustomReporterTests.mockObserver.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        CustomReporterTests.mockObserver.reset()
    }

    func testAnchoredRegexStringWithWildcardClosureNeverAttaches() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given the app is at the Main Menu
        """)

        var ran = false
        Given("^the app is at the Main Menu$") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertFalse(ran, "the closure should never attach for the anchored-regex/wildcard-closure overload trap")
    }

    func testUndefinedStepPassesByDefault() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given the app is at the Main Menu
        """)

        Given("^the app is at the Main Menu$") { _, _ in }

        var reportedResult: Reporter.Result?
        CustomReporterTests.mockObserver.didFinishStep = { step, result, _ in
            reportedResult = result
        }

        Cucumber.shared.executeFeatures()

        XCTAssertFalse(Cucumber.shared.currentStep?.canExecute ?? true)
        XCTAssertEqual(reportedResult, .pending)
    }

    // `executeFeatures()` invokes each generated test case's `invokeTest()` directly instead of
    // going through XCTest's own `-[XCTestCase run]`, so it never sets up a `testRun` for those
    // fake test cases. Recording a real XCTIssue against one (as `strictPendingSteps` does) is
    // then misattributed to *this* enclosing test by XCTest's own exception handling, the same
    // limitation `CustomReporterTests.testReporterIsToldAboutFailingSteps` et al. document with
    // `XCTSkip`. This was verified manually instead: `xcodebuild test` against a real
    // `defaultTestSuite` run (i.e. the actual, non-shortcut execution path CucumberSwift
    // consumers exercise) shows `GivenTheAppIsAtTheMainMenu` failing with the message from
    // `Step.undefinedStepIssue()` when `strictPendingSteps` is enabled, and passing silently
    // (today's default) when it isn't.
    func testUndefinedStepFailsLoudlyWhenStrictPendingStepsIsEnabled() throws {
        throw XCTSkip("Recording a failure against a step's generated test case can't be observed from within another running test - see comment above. Verified manually via xcodebuild test instead.")
    }
}
