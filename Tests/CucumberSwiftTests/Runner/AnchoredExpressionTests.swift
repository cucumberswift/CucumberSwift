//
//  AnchoredExpressionTests.swift
//  CucumberSwiftTests
//
//  Regression coverage for issue #125, reported and diagnosed by @marton78 in #122.
//
//  `Given("^some step$") { _, _ in }` looks like a regular expression, but a wildcard closure
//  type-checks against both overloads and `@_disfavoredOverload` on the regex-`String` initializer
//  hands it to `CucumberExpression`. Before CucumberSwiftExpressions 1.0.0, a `CucumberExpression`
//  escaped `^` and `$` into literal characters, so the definition attached to nothing. From 1.0.0 a
//  string that starts with `^`, ends with `$`, or is written between slashes is treated as a
//  regular expression, matching the reference Cucumber implementation.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class AnchoredExpressionTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    private func parseFeature(withStep step: String) {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given \(step)
        """)
    }

    // The case from #122: an anchored string with a wildcard closure. It still binds to the
    // CucumberExpression overload, but that expression is now a regular expression and matches.
    func testAnchoredStringWithWildcardClosureAttaches() {
        parseFeature(withStep: "the app is at the Main Menu")

        var ran = false
        Given("^the app is at the Main Menu$") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertTrue(ran, "an anchored string must be treated as a regular expression and match")
        XCTAssertTrue(Cucumber.shared.currentStep?.canExecute ?? false)
    }

    func testLeadingAnchorAloneAttaches() {
        parseFeature(withStep: "the app is at the Main Menu")

        var ran = false
        Given("^the app is at the Main Menu") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertTrue(ran, "a leading ^ alone makes the string a regular expression")
    }

    func testTrailingAnchorAloneAttaches() {
        parseFeature(withStep: "the app is at the Main Menu")

        var ran = false
        Given("the app is at the Main Menu$") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertTrue(ran, "a trailing $ alone makes the string a regular expression")
    }

    func testSlashDelimitedStringAttaches() {
        parseFeature(withStep: "the app is at the Main Menu")

        var ran = false
        Given("/the app is at the Main Menu/") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertTrue(ran, "a string between slashes is treated as a regular expression")
    }

    // Positive control: plain Cucumber expressions are unaffected.
    func testUnanchoredExpressionAttaches() {
        parseFeature(withStep: "the app is at the Main Menu")

        var ran = false
        Given("the app is at the Main Menu") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertTrue(ran)
        XCTAssertTrue(Cucumber.shared.currentStep?.canExecute ?? false)
    }

    // The compatibility break in 6.0.0. A trailing `$` used to be a literal character; it is now a
    // regular expression anchor, so this definition no longer matches the step text `I owe 5$`.
    // Because `I owe 5$` is a valid regular expression, nothing traps — it silently stops matching.
    func testTrailingLiteralDollarIsNowAnAnchor() {
        parseFeature(withStep: "I owe 5$")

        var ran = false
        Given("I owe 5$") { _, _ in ran = true }

        Cucumber.shared.executeFeatures()

        XCTAssertFalse(ran, "a trailing $ is an anchor from 6.0.0, not a literal character")
    }
}
