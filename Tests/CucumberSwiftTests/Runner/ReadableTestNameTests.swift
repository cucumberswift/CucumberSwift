//
//  ReadableTestNameTests.swift
//  CucumberSwiftTests
//
//  With readable test names, the default, generated tests are named with the Gherkin text as written, so Xcode's
//  test navigator reads like the feature file (#59).
//
import Foundation
import XCTest
@testable import CucumberSwift

class ReadableTestNameTests: XCTestCase {
    private static func generatedTestNames(readable: Bool) -> [String] {
        Cucumber.shared.reset()
        Cucumber.readableTestNames = readable
        defer {
            Cucumber.readableTestNames = nil
            Cucumber.shared.reset()
        }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Readable names \(readable)
           Scenario: Pay with a gift card
             Given a cart
             And a gift card
        """)
        let suite = XCTestSuite(name: "Readable names")
        CucumberTest.generateAlltests(suite)
        return suite.tests.filter { $0.name != "GeneratedSteps" }.flatMap { scenario in
            [scenario.name] + ((scenario as? XCTestSuite)?.tests.map(\.name) ?? [])
        }
    }

    /// The generated tests' names after parsing an English feature file and then a Spanish one (#290).
    private static func generatedTestNamesForTwoLanguages(readable: Bool) -> [String] {
        Cucumber.shared.reset()
        Cucumber.readableTestNames = readable
        defer {
            Cucumber.readableTestNames = nil
            Cucumber.shared.reset()
        }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Basket
          Scenario: Eating cukes
            Given I have 3 cukes
            When I eat 2 cukes
            And I wait
            Then I have 1 cuke
        """)
        Cucumber.shared.parseIntoFeatures("""
        # language: es
        Característica: Pepinos
          Escenario: Comer pepinos
            Cuando como 2 pepinos
            Entonces quedan 3 pepinos
        """)
        let suite = XCTestSuite(name: "Two languages")
        CucumberTest.generateAlltests(suite)
        return suite.tests.compactMap { $0 as? XCTestSuite }.flatMap { $0.tests.map(\.name) }
    }

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

    // Cucumber.readableTestNames, not just the helpers, decides how generated tests are named.
    func testTheSettingNamesTheGeneratedScenarioAndStepsAsWritten() throws {
        let delimiter = CucumberTest.featureScenarioDelimiter(configured: Cucumber.shared.bundle.infoDictionary?["FeatureScenarioDelimiter"] as? String,
                                                              readable: true)
        let names = Self.generatedTestNames(readable: true)
        XCTAssertEqual(names.first, "Readable names true\(delimiter)Pay with a gift card")
        XCTAssertTrue(names.contains { $0.hasSuffix(" 1 \u{203A} Given a cart]") }, "\(names)")
        XCTAssertTrue(names.contains { $0.hasSuffix(" 2 \u{203A} And a gift card]") }, "\(names)")
    }

    func testWithoutTheSettingTheGeneratedNamesAreCamelCased() {
        let names = Self.generatedTestNames(readable: false)
        XCTAssertTrue(names.contains { $0.hasSuffix(" Step000_GivenACart]") }, "\(names)")
        XCTAssertTrue(names.contains { $0.hasSuffix(" Step001_GivenAGiftCard]") }, "\(names)")
    }

    // A step is named in its own feature file's language, not in the language of the file parsed last (#290).
    func testEachStepIsNamedInItsOwnFeatureFilesLanguage() {
        let names = Self.generatedTestNamesForTwoLanguages(readable: true)
        let expectedNames = [
            "1 \u{203A} Given I have 3 cukes]", "2 \u{203A} When I eat 2 cukes]", "3 \u{203A} And I wait]", "4 \u{203A} Then I have 1 cuke]",
            "1 \u{203A} Cuando como 2 pepinos]", "2 \u{203A} Entonces quedan 3 pepinos]"
        ]
        for expected in expectedNames {
            XCTAssertTrue(names.contains { $0.hasSuffix(" \(expected)") }, "No test named \(expected) in \(names)")
        }
    }

    func testEachCamelCasedStepNameUsesItsOwnFeatureFilesLanguage() {
        let names = Self.generatedTestNamesForTwoLanguages(readable: false)
        let expectedNames = [
            "Step000_GivenIHave3Cukes]", "Step001_WhenIEat2Cukes]", "Step003_ThenIHave1Cuke]",
            "Step000_CuandoComo2Pepinos]", "Step001_EntoncesQuedan3Pepinos]"
        ]
        for expected in expectedNames {
            XCTAssertTrue(names.contains { $0.hasSuffix(" \(expected)") }, "No test named \(expected) in \(names)")
        }
    }

    func testReadableNamesAreTheDefault() {
        XCTAssertEqual(CucumberTest.generatedTestName("Pay with a gift card"), "Pay with a gift card")
    }
}
