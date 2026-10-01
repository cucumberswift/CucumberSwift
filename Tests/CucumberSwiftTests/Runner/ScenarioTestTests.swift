//
//  ScenarioTestTests.swift
//  CucumberSwiftTests
//
//  With `Cucumber.oneTestPerScenario`, each scenario is one test of CucumberScenarioTest, named after its
//  feature and scenario, so Xcode's test navigator can ask XCTest for it by name (#59).
//

import Foundation
import XCTest
@testable import CucumberSwift

class ScenarioTestTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        // The features under test are parsed here, so loading the bundle's own must not replace them.
        let featuresLoaded = CucumberTest.featuresLoaded
        CucumberTest.featuresLoaded = true
        addTeardownBlock {
            Cucumber.shared.reset()
            Cucumber.oneTestPerScenario = nil
            CucumberTest.featuresLoaded = featuresLoaded
        }
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
                       ["Checkout\(delimiter)Pay with a gift card", "Checkout\(delimiter)Pay with a saved card"])
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

    func testWithOneTestPerScenarioTheSuiteHasATestPerScenario() throws {
        Cucumber.oneTestPerScenario = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Generated suite
           Scenario: First
             Given a cart
           Scenario: Second
             Given a cart
        """)
        let testClass = try XCTUnwrap(CucumberTest.scenarioTestClass)

        let suite = XCTestSuite(name: "Generated suite")
        CucumberTest.generateAlltests(suite)
        let scenarioTests = suite.tests.filter { type(of: $0) == testClass }

        XCTAssertEqual(scenarioTests.count, 2)
        XCTAssertTrue(scenarioTests.first?.name.contains("First") ?? false, "\(scenarioTests.map(\.name))")
    }

    // Xcode's test navigator runs one scenario by asking XCTest for its test by name, before anything
    // has added it. Asking the Objective-C class goes through its +resolveInstanceMethod:.
    func testAScenarioTestIsFoundByName() throws {
        Cucumber.oneTestPerScenario = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Found by name
           Scenario: First
             Given a cart
           Scenario: Second
             Given a cart
        """)
        let names = CucumberTest.scenarioTests().map(\.name)
        let testClass = try XCTUnwrap(CucumberTest.scenarioTestClass)

        XCTAssertTrue(CucumberTest.resolveScenarioTest(named: names[0] + "AndReturnError:"))
        XCTAssertTrue(testClass.instancesRespond(to: NSSelectorFromString(names[1] + "AndReturnError:")))
    }

    func testNoScenarioTestIsFoundWithoutOneTestPerScenario() {
        Cucumber.oneTestPerScenario = false
        Cucumber.shared.parseIntoFeatures("""
        Feature: Not found
           Scenario: First
             Given a cart
        """)
        let name = CucumberTest.scenarioTests().map(\.name)[0]

        XCTAssertFalse(CucumberTest.resolveScenarioTest(named: name + "AndReturnError:"))
    }

    func testNoScenarioTestIsFoundForAnUnknownNameOrAnotherSelector() {
        Cucumber.oneTestPerScenario = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Unknown
           Scenario: First
             Given a cart
        """)
        let name = CucumberTest.scenarioTests().map(\.name)[0]

        XCTAssertFalse(CucumberTest.resolveScenarioTest(named: "Unknown scenarioAndReturnError:"))
        XCTAssertFalse(CucumberTest.resolveScenarioTest(named: name))
    }

    // Outside a scenario's run, a failure is recorded where it happened.
    func testAnIssueOutsideAScenarioRunKeepsItsLocation() {
        let issue = XCTIssue(type: .assertionFailure,
                             compactDescription: "failed",
                             detailedDescription: nil,
                             sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: "Steps.swift", lineNumber: 7)),
                             associatedError: nil,
                             attachments: [])

        XCTAssertEqual(CucumberTestSupport.locateIssue(issue).sourceCodeContext.location?.lineNumber, 7)
    }

    // XCTest calls a scenario's test method, which returns false with the skip when a step skipped it.
    // Called here directly, on this running test.
    func testAScenarioTestMethodReportsSuccessOrItsSkip() throws {
        Cucumber.oneTestPerScenario = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Method body
           Scenario: Passes
             Given a cart
           Scenario: Skips
             Given the card terminal is offline
        """)
        Given("a cart") { _, _ in }
        Given("the card terminal is offline") { _, _ in throw XCTSkip("Offline") }
        let testClass = try XCTUnwrap(CucumberTest.scenarioTestClass)
        typealias Body = @convention(c) (AnyObject, Selector, AutoreleasingUnsafeMutablePointer<NSError?>?) -> Bool
        let selectors = try CucumberTest.scenarioTests().map {
            try XCTUnwrap(CucumberTest.addScenarioMethod(named: $0.name, running: $0.scenario))
        }
        let bodies = selectors.map { unsafeBitCast(class_getMethodImplementation(testClass, $0), to: Body.self) }

        var error: NSError?
        XCTAssertTrue(bodies[0](self, selectors[0], &error))
        XCTAssertNil(error)
        XCTAssertFalse(bodies[1](self, selectors[1], &error))
        XCTAssertNotNil(error)
        continueAfterFailure = true
    }
}
