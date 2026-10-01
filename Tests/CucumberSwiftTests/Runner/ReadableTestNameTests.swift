//
//  ReadableTestNameTests.swift
//  CucumberSwiftTests
//
//  With `readableTestNames`, generated tests are named with the Gherkin text as written, so Xcode's
//  test navigator reads like the feature file (#59).
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class ReadableTestNameTests: XCTestCase {
    func testByDefaultANameIsCamelCased() {
        XCTAssertEqual(CucumberTest.generatedTestName("Sign in (email: bob@x.com)", readable: false), "SignInEmailBobXCom")
    }

    func testAReadableNameKeepsTheTextAsWritten() {
        XCTAssertEqual(CucumberTest.generatedTestName("Sign in (email: bob)", readable: true), "Sign in (email: bob)")
    }

    // XCTest separates a test's class from its method with "/".
    func testAReadableNameHasNoSlash() {
        XCTAssertEqual(CucumberTest.generatedTestName("Pay 1/2 now", readable: true), "Pay 1-2 now")
    }

    // Xcode would show only "com)" for a class named "Sign in (email: bob@x.com)".
    func testAReadableNameHasNoFullStop() {
        XCTAssertEqual(CucumberTest.generatedTestName("Sign in (email: bob@x.com)", readable: true), "Sign in (email: bob@x\u{2024}com)")
    }

    func testAReadableNameHasNoNewlinesOrSurroundingSpaces() {
        XCTAssertEqual(CucumberTest.generatedTestName("  Given a doc string\n", readable: true), "Given a doc string")
    }

    func testByDefaultAStepIsNamedWithItsZeroPaddedIndex() {
        XCTAssertEqual(Step.methodName(for: "Then the total is 99", at: 2, of: 3, readable: false), "Step002_ThenTheTotalIs99")
    }

    func testAReadableStepNameStartsWithItsPosition() {
        XCTAssertEqual(Step.methodName(for: "Then the total is 99", at: 2, of: 3, readable: true), "3 \u{203A} Then the total is 99")
    }

    // XCTest may sort a class's tests by name (#209), so step 10 must not sort before step 2.
    func testReadableStepNamesSortInFeatureFileOrder() {
        let names = (0..<12).map { Step.methodName(for: "Given step \($0)", at: $0, of: 12, readable: true) }
        XCTAssertEqual(names.first, "01 \u{203A} Given step 0")
        XCTAssertEqual(names.sorted(), names)
    }

    func testAReadableScenarioNameSeparatesItsFeatureWithAnAngleQuote() {
        XCTAssertEqual(CucumberTest.featureScenarioDelimiter(configured: nil, readable: true), " \u{203A} ")
        XCTAssertEqual(CucumberTest.featureScenarioDelimiter(configured: nil, readable: false), "|")
    }

    func testAConfiguredDelimiterWinsOverTheReadableOne() {
        XCTAssertEqual(CucumberTest.featureScenarioDelimiter(configured: "_", readable: true), "_")
    }

    // A step written with And or But keeps that keyword in its name, rather than the one it continues.
    func testAStepKeepsTheKeywordItWasWrittenWith() throws {
        Cucumber.shared.reset()
        defer { Cucumber.shared.reset() }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Cart
           Scenario: Add products
             Given an empty cart
             And a product
             Then the cart has 1 item
             But the cart has no discount
        """)
        let steps = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first?.steps)
        XCTAssertEqual(steps.map(\.writtenKeyword), ["Given", "And", "Then", "But"])
        XCTAssertEqual(steps[1].keyword, [.given, .and])
    }

    func testTheSettingIsOffWhenTheStepImplementationDoesNotSayOtherwise() {
        XCTAssertEqual(CucumberTest.generatedTestName("Pay with a gift card"), "PayWithAGiftCard")
    }
}
