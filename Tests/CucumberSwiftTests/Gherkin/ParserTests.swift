//
//  TestParser.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/16/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

// swiftlint:disable type_body_length type_contents_order
class ParserTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    let featureFile: String =
    """
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Scenario: Some determinable business situation
         Given some precondition
           And some other precondition
         When some action by the actor
           And some other action
           And yet another action
         Then some testable outcome is achieved

       Scenario: Some other determinable business situation
         Given some precondition
           And some other precondition
         When some action by the actor
         Then some testable outcome is achieved
    """

    let featureFileWithBackground: String =
    """
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Background:
         Given a global administrator named "Greg"
           And a blog named "Greg's anti-tax rants"
           And a customer named "Dr. Bill"
           And a blog named "Expensive Therapy" owned by "Dr. Bill"

       Scenario: Some determinable business situation
         Given some precondition
           And some other precondition
         When some action by the actor
           And some other action
           And yet another action
         Then some testable outcome is achieved

       Scenario: Some other determinable business situation
         Given some precondition
           And some other precondition
         When some action by the actor
         Then some testable outcome is achieved
    """

    func testSpeed() {
        let features = repeatElement(featureFile, count: 100)
                        .joined(separator: "\n")
        self.measure {
            _ = Cucumber(withString: features)
        }
    }

    func testBackgroundSteps() {
        let cucumber = Cucumber(withString: featureFileWithBackground)
        let feature = cucumber.features.first
        let firstScenario = cucumber.features.first?.scenarios.first
        XCTAssertEqual(feature?.scenarios.count, 2)
        XCTAssertEqual(firstScenario?.steps.count, 10)
        if (firstScenario?.steps.count ?? 0) == 10 {
            let steps = firstScenario?.steps
            XCTAssertEqual(steps?[0].keyword, .given)
            XCTAssertEqual(steps?[0].match, "a global administrator named \"Greg\"")
        }
    }

    func testGherkinIsParcedIntoCorrectFeaturesScenariosAndSteps() {
        let cucumber = Cucumber(withString: featureFile)
        let feature = cucumber.features.first
        let firstScenario = cucumber.features.first?.scenarios.first
        let lastScenario = cucumber.features.first?.scenarios.last

        XCTAssertEqual(cucumber.features.count, 1)
        XCTAssertEqual(feature?.title, "Some terse yet descriptive text of what is desired")
        // swiftlint:disable:next line_length
        XCTAssertEqual(feature?.desc, "Textual description of the business value of this feature\nBusiness rules that govern the scope of the feature\nAny additional information that will make the feature easier to understand\n")
        XCTAssertEqual(feature?.scenarios.count, 2)
        XCTAssert(firstScenario?.feature === feature)
        XCTAssert(lastScenario?.feature === feature)
        XCTAssertEqual(firstScenario?.title, "Some determinable business situation")
        XCTAssertEqual(firstScenario?.steps.count, 6)
        firstScenario?.steps.forEach { XCTAssert($0.scenario === firstScenario) }
        lastScenario?.steps.forEach { XCTAssert($0.scenario === lastScenario) }
        if (firstScenario?.steps.count ?? 0) == 6 {
            let steps = firstScenario?.steps
            XCTAssertEqual(steps?[0].keyword, .given)
            XCTAssertEqual(steps?[0].match, "some precondition")
            XCTAssertEqual(steps?[1].keyword, [.given, .and])
            XCTAssertEqual(steps?[1].match, "some other precondition")
            XCTAssertEqual(steps?[2].keyword, .when)
            XCTAssertEqual(steps?[2].match, "some action by the actor")
            XCTAssertEqual(steps?[3].keyword, [.when, .and])
            XCTAssertEqual(steps?[3].match, "some other action")
            XCTAssertEqual(steps?[4].keyword, [.when, .and])
            XCTAssertEqual(steps?[4].match, "yet another action")
            XCTAssertEqual(steps?[5].keyword, .then)
            XCTAssertEqual(steps?[5].match, "some testable outcome is achieved")
        }

        XCTAssertEqual(lastScenario?.steps.count, 4)
        if (lastScenario?.steps.count ?? 0) == 4 {
            let steps = lastScenario?.steps
            XCTAssertEqual(steps?[0].keyword, .given)
            XCTAssertEqual(steps?[0].match, "some precondition")
            XCTAssertEqual(steps?[1].keyword, [.given, .and])
            XCTAssertEqual(steps?[1].match, "some other precondition")
            XCTAssertEqual(steps?[2].keyword, .when)
            XCTAssertEqual(steps?[2].match, "some action by the actor")
            XCTAssertEqual(steps?[3].keyword, .then)
            XCTAssertEqual(steps?[3].match, "some testable outcome is achieved")
        }
    }

    func testWithNonAlphanumericScenario() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation2: (with subtext)
         Given a user with 2 ideas
            And a PO with 1
    """)
        let feature = cucumber.features.first
        let scenario = feature?.scenarios.first
        XCTAssertEqual(scenario?.title, "Some determinable business situation2: (with subtext)")
    }

    func testWithIntegerType() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a user with 2 ideas
            And a PO with 1
    """)
        let feature = cucumber.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        let secondStep = scenario?.steps.last
        XCTAssertEqual(firstStep?.keyword, .given)
        XCTAssertEqual(firstStep?.match, "a user with 2 ideas")
        XCTAssertEqual(secondStep?.keyword, [.given, .and])
        XCTAssertEqual(secondStep?.match, "a PO with 1")
    }

    func testWithDoubleType() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a user with 2.5 ideas
            And a PO with 0.5
    """)
        let feature = cucumber.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        let secondStep = scenario?.steps.last
        XCTAssertEqual(firstStep?.keyword, .given)
        XCTAssertEqual(firstStep?.match, "a user with 2.5 ideas")
        XCTAssertEqual(secondStep?.keyword, [.given, .and])
        XCTAssertEqual(secondStep?.match, "a PO with 0.5")
    }

    func testItDoesNotGetFooledByThingsThatLookLikeDoublesButAreNot() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a user with 2.5 ideas
            And a birthday with 08.01.1992
         When a requirement is to handle 08 without changing it
         Then it works
    """)
        let feature = cucumber.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 4)
        XCTAssertEqual(firstStep?.keyword, .given)
        XCTAssertEqual(firstStep?.match, "a user with 2.5 ideas")
        if (scenario?.steps.count ?? 0) == 4 {
            XCTAssertEqual(scenario?.steps[1].keyword, [.given, .and])
            XCTAssertEqual(scenario?.steps[1].match, "a birthday with 08.01.1992")
            XCTAssertEqual(scenario?.steps[2].keyword, .when)
            XCTAssertEqual(scenario?.steps[2].match, "a requirement is to handle 08 without changing it")
            XCTAssertEqual(scenario?.steps[3].keyword, .then)
            XCTAssertEqual(scenario?.steps[3].match, "it works")
        }
        cucumber.executeFeatures()
    }

    func testAndKeywordTiesCorrectlyToGiven() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
            And a different step
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.given, .and])
    }

    func testAndKeywordTiesCorrectlyToWhen() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
         When differentThing
             And andThing
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.when, .and])
    }

    func testAndKeywordTiesCorrectlyToThen() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
         When differentThing
         Then lastThing
             And andThing
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.then, .and])
    }

    func testButKeywordTiesCorrectlyToGiven() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
                But a different step
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.given, .but])
    }

    func testButKeywordTiesCorrectlyToWhen() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
         When differentThing
             But andThing
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.when, .but])
    }

    func testButKeywordTiesCorrectlyToThen() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Some determinable business situation
         Given a step
         When differentThing
         Then lastThing
             But andThing
    """)
        let lastStep = cucumber.features.first?.scenarios.first?.steps.last
        XCTAssertEqual(lastStep?.keyword, [.then, .but])
    }

    func testScenarioDescriptionIsParsed() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario: Scenario with description
         This is a description line.
         Another line.

         Given a step
         When action happens
         Then result is observed
    """)
        let scenario = cucumber.features.first?.scenarios.first
        XCTAssertEqual(scenario?.title, "Scenario with description")
        XCTAssertEqual(scenario?.desc, "This is a description line.\nAnother line.\n")
        // sanity: steps still parsed correctly
        XCTAssertEqual(scenario?.steps.count, 3)
        XCTAssertEqual(scenario?.steps.first?.keyword, .given)
        XCTAssertEqual(scenario?.steps.first?.match, "a step")
    }

    func testScenarioOutlineDescriptionIsParsed() {
        let cucumber = Cucumber(withString: """
    Feature: Some feature
       Scenario Outline: Outline with description
         This is outline description.
         Another line.

         Given there are <start> cucumbers
         When I eat <eat> cucumbers
         Then I should have <left> cucumbers

       Examples:
         | start | eat | left |
         | 12    | 5   | 7    |
         | 20    | 5   | 15   |
    """)
        let feature = cucumber.features.first
        let scenarios = feature?.scenarios ?? []
        XCTAssertEqual(scenarios.count, 2)

        // Titles expanded with example index
        XCTAssertEqual(scenarios[safe: 0]?.title, "Outline with description (example 1)")
        XCTAssertEqual(scenarios[safe: 1]?.title, "Outline with description (example 2)")

        // Description propagated from Scenario Outline to each expanded Scenario
        XCTAssertEqual(scenarios[safe: 0]?.desc, "This is outline description.\nAnother line.\n")
        XCTAssertEqual(scenarios[safe: 1]?.desc, "This is outline description.\nAnother line.\n")

        // Sanity: steps are parsed and values are substituted
        XCTAssertEqual(scenarios[safe: 0]?.steps.count, 3)
        XCTAssertEqual(scenarios[safe: 0]?.steps.first?.keyword, .given)
        XCTAssertEqual(scenarios[safe: 0]?.steps.first?.match, "there are 12 cucumbers")
        XCTAssertEqual(scenarios[safe: 0]?.steps.last?.keyword, .then)
        XCTAssertEqual(scenarios[safe: 0]?.steps.last?.match, "I should have 7 cucumbers")

        XCTAssertEqual(scenarios[safe: 1]?.steps.first?.match, "there are 20 cucumbers")
        XCTAssertEqual(scenarios[safe: 1]?.steps.last?.match, "I should have 15 cucumbers")
    }
}
// swiftlint:enable type_body_length type_contents_order
