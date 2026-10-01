//
//  ScenarioTestTests.swift
//  CucumberSwiftTests
//
//  With `oneTestPerScenario`, each scenario is one test of CucumberScenarioTest, named after its
//  feature and scenario, so Xcode's test navigator can ask XCTest for it by name (#59).
//

import Foundation
import XCTest
@testable import CucumberSwift

class ScenarioTestTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        addTeardownBlock { Cucumber.shared.reset() }
    }

    func testEachScenarioIsNamedAfterItsFeatureAndItself() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay with a gift card
             Given a cart
           Scenario: Pay with a saved card
             Given a cart
        """)
        let delimiter = CucumberTest.readFeatureScenarioDelimiter()
        XCTAssertEqual(CucumberTest.scenarioTests().map(\.name),
                       ["Checkout\(delimiter)PayWithAGiftCard", "Checkout\(delimiter)PayWithASavedCard"])
    }

    // Two scenarios with one name would be one test, so the second gets a number.
    func testAScenarioWhoseNameRepeatsAnotherGetsANumber() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given a cart
           Scenario: Pay
             Given a cart
        """)
        let delimiter = CucumberTest.readFeatureScenarioDelimiter()
        XCTAssertEqual(CucumberTest.scenarioTests().map(\.name), ["Checkout\(delimiter)Pay", "Checkout\(delimiter)Pay 2"])
    }

    func testTheNamesFollowTheFeatureFilesOrder() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Zebra
             Given a cart
           Scenario: Apple
             Given a cart
        """)
        XCTAssertEqual(CucumberTest.scenarioTests().map { $0.scenario.title }, ["Zebra", "Apple"])
    }

    func testByDefaultEachStepIsATest() {
        XCTAssertFalse(CucumberTest.oneTestPerScenario(environment: nil, implementor: nil))
    }

    func testTheEnvironmentVariableOverridesTheStepImplementation() {
        XCTAssertTrue(CucumberTest.oneTestPerScenario(environment: "YES", implementor: false))
        XCTAssertTrue(CucumberTest.oneTestPerScenario(environment: "true", implementor: nil))
        XCTAssertTrue(CucumberTest.oneTestPerScenario(environment: "1", implementor: false))
        XCTAssertFalse(CucumberTest.oneTestPerScenario(environment: "NO", implementor: true))
        XCTAssertFalse(CucumberTest.oneTestPerScenario(environment: "0", implementor: true))
    }

    func testWithoutTheEnvironmentVariableTheStepImplementationDecides() {
        XCTAssertTrue(CucumberTest.oneTestPerScenario(environment: nil, implementor: true))
        XCTAssertTrue(CucumberTest.oneTestPerScenario(environment: "maybe", implementor: true))
    }

    // CucumberScenarioTest.m and CucumberTestSupport find each other by name, so a typo in either
    // compiles and only breaks running one scenario.
    func testTheObjectiveCScenarioTestClassIsFound() {
        XCTAssertNotNil(CucumberTest.scenarioTestClass)
    }

    func testTheSupportClassAnswersWhatTheScenarioTestClassAsks() throws {
        let support: AnyObject = try XCTUnwrap(NSClassFromString("CucumberTestSupport"))
        XCTAssertTrue(support.responds(to: NSSelectorFromString("resolveScenarioTestNamed:")))
        XCTAssertTrue(support.responds(to: NSSelectorFromString("locateIssue:")))
    }
}
