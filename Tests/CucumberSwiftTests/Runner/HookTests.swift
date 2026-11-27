//
//  HookTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 4/24/21.
//  Copyright © 2021 Tyler Thompson. All rights reserved.
//
// swiftlint:disable type_body_length file_length function_body_length

import Foundation
import XCTest

@testable import CucumberSwift

class HookTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        Cucumber.overrideReverseOrderForAfterHooks = false
    }

    func testBeforeFeatureHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["BeforeFeature", "Given"])
    }

    func testAfterFeatureHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["Given", "AfterFeature"])
    }

    func testBeforeScenarioHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeScenario_Some determinable business situation",
            "Given some precondition",
            "BeforeScenario_Some other determinable business situation",
            "Given some other precondition"
        ])
    }

    func testAfterScenarioHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "Given some precondition",
            "AfterScenario_Some determinable business situation",
            "Given some other precondition",
            "AfterScenario_Some other determinable business situation",
            "AfterFeature"
        ])
    }

    func testBeforeStepHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeScenario_Some determinable business situation",
            "BeforeStep_some precondition",
            "Given some precondition",
            "BeforeScenario_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "Given some other precondition"
        ])
    }

    func testAfterStepHookTriggersAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "Given some precondition",
            "AfterStep_some precondition",
            "AfterScenario_Some determinable business situation",
            "Given some other precondition",
            "AfterStep_some other precondition",
            "AfterScenario_Some other determinable business situation",
            "AfterFeature"
        ])
    }

    func testBeforeAndAfterHooksTriggerAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeScenario_Some determinable business situation",
            "BeforeStep_some precondition",
            "Given some precondition",
            "AfterStep_some precondition",
            "AfterScenario_Some determinable business situation",
            "BeforeScenario_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "Given some other precondition",
            "AfterStep_some other precondition",
            "AfterScenario_Some other determinable business situation",
            "AfterFeature"
        ])
    }

    func testMultipleBeforeAndAfterHooksTriggerAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeFeature { feature in
            executionOrder.append("BeforeFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature { feature in
            executionOrder.append("AfterFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario2_\(scenario.title)")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario2_\(scenario.title)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep2_\(step.match)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep2_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeFeature2",
            "BeforeScenario_Some determinable business situation",
            "BeforeScenario2_Some determinable business situation",
            "BeforeStep_some precondition",
            "BeforeStep2_some precondition",
            "Given some precondition",
            "AfterStep_some precondition",
            "AfterStep2_some precondition",
            "AfterScenario_Some determinable business situation",
            "AfterScenario2_Some determinable business situation",
            "BeforeScenario_Some other determinable business situation",
            "BeforeScenario2_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "BeforeStep2_some other precondition",
            "Given some other precondition",
            "AfterStep_some other precondition",
            "AfterStep2_some other precondition",
            "AfterScenario_Some other determinable business situation",
            "AfterScenario2_Some other determinable business situation",
            "AfterFeature",
            "AfterFeature2"
        ])
    }

    func testMultipleBeforeAndAfterHooksTriggerAppropriately_Reversed() {
        Cucumber.overrideReverseOrderForAfterHooks = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeFeature { feature in
            executionOrder.append("BeforeFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature { feature in
            executionOrder.append("AfterFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        BeforeScenario { scenario in
            executionOrder.append("BeforeScenario2_\(scenario.title)")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        AfterScenario { scenario in
            executionOrder.append("AfterScenario2_\(scenario.title)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        BeforeStep { step in
            executionOrder.append("BeforeStep2_\(step.match)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        AfterStep { step in
            executionOrder.append("AfterStep2_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeFeature2",
            "BeforeScenario_Some determinable business situation",
            "BeforeScenario2_Some determinable business situation",
            "BeforeStep_some precondition",
            "BeforeStep2_some precondition",
            "Given some precondition",
            "AfterStep2_some precondition",
            "AfterStep_some precondition",
            "AfterScenario2_Some determinable business situation",
            "AfterScenario_Some determinable business situation",
            "BeforeScenario_Some other determinable business situation",
            "BeforeScenario2_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "BeforeStep2_some other precondition",
            "Given some other precondition",
            "AfterStep2_some other precondition",
            "AfterStep_some other precondition",
            "AfterScenario2_Some other determinable business situation",
            "AfterScenario_Some other determinable business situation",
            "AfterFeature2",
            "AfterFeature"
        ])
    }

    func testMultipleBeforeAndAfterHooks_ThatDefineTheirOwnOrder_TriggerAppropriately() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()

        BeforeFeature(priority: .max) { feature in
            executionOrder.append("BeforeFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeFeature(priority: 1) { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature(priority: .max) { feature in
            executionOrder.append("AfterFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature(priority: 1) { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario(priority: .max) { scenario in
            executionOrder.append("BeforeScenario2_\(scenario.title)")
        }

        BeforeScenario(priority: 1) { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        AfterScenario(priority: .max) { scenario in
            executionOrder.append("AfterScenario2_\(scenario.title)")
        }

        AfterScenario(priority: 1) { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        BeforeStep(priority: .max) { step in
            executionOrder.append("BeforeStep2_\(step.match)")
        }

        BeforeStep(priority: 1) { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        AfterStep(priority: .max) { step in
            executionOrder.append("AfterStep2_\(step.match)")
        }

        AfterStep(priority: 1) { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeFeature2",
            "BeforeScenario_Some determinable business situation",
            "BeforeScenario2_Some determinable business situation",
            "BeforeStep_some precondition",
            "BeforeStep2_some precondition",
            "Given some precondition",
            "AfterStep_some precondition",
            "AfterStep2_some precondition",
            "AfterScenario_Some determinable business situation",
            "AfterScenario2_Some determinable business situation",
            "BeforeScenario_Some other determinable business situation",
            "BeforeScenario2_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "BeforeStep2_some other precondition",
            "Given some other precondition",
            "AfterStep_some other precondition",
            "AfterStep2_some other precondition",
            "AfterScenario_Some other determinable business situation",
            "AfterScenario2_Some other determinable business situation",
            "AfterFeature",
            "AfterFeature2"
        ])
    }

    func testMultipleBeforeAndAfterHooks_ThatDefineTheirOwnOrder_TriggerAppropriately_Reversed() {
        Cucumber.overrideReverseOrderForAfterHooks = true
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()

        BeforeFeature(priority: .max) { feature in
            executionOrder.append("BeforeFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeFeature(priority: 1) { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature(priority: .max) { feature in
            executionOrder.append("AfterFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        AfterFeature(priority: 1) { feature in
            executionOrder.append("AfterFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeScenario(priority: .max) { scenario in
            executionOrder.append("BeforeScenario2_\(scenario.title)")
        }

        BeforeScenario(priority: 1) { scenario in
            executionOrder.append("BeforeScenario_\(scenario.title)")
        }

        AfterScenario(priority: .max) { scenario in
            executionOrder.append("AfterScenario2_\(scenario.title)")
        }

        AfterScenario(priority: 1) { scenario in
            executionOrder.append("AfterScenario_\(scenario.title)")
        }

        BeforeStep(priority: .max) { step in
            executionOrder.append("BeforeStep2_\(step.match)")
        }

        BeforeStep(priority: 1) { step in
            executionOrder.append("BeforeStep_\(step.match)")
        }

        AfterStep(priority: .max) { step in
            executionOrder.append("AfterStep2_\(step.match)")
        }

        AfterStep(priority: 1) { step in
            executionOrder.append("AfterStep_\(step.match)")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given some precondition") }
        Given("some other precondition") { _, _ in executionOrder.append("Given some other precondition") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeFeature2",
            "BeforeScenario_Some determinable business situation",
            "BeforeScenario2_Some determinable business situation",
            "BeforeStep_some precondition",
            "BeforeStep2_some precondition",
            "Given some precondition",
            "AfterStep2_some precondition",
            "AfterStep_some precondition",
            "AfterScenario2_Some determinable business situation",
            "AfterScenario_Some determinable business situation",
            "BeforeScenario_Some other determinable business situation",
            "BeforeScenario2_Some other determinable business situation",
            "BeforeStep_some other precondition",
            "BeforeStep2_some other precondition",
            "Given some other precondition",
            "AfterStep2_some other precondition",
            "AfterStep_some other precondition",
            "AfterScenario2_Some other determinable business situation",
            "AfterScenario_Some other determinable business situation",
            "AfterFeature2",
            "AfterFeature"
        ])
    }

    func testHooksWithNoPriorityTriggerAfterHooksWithAPriority() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             When some action is performed
             Then some testable result is achieved

            Scenario: Some other determinable business situation
              Given some other precondition
              When some action is performed
              Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature(priority: 1) { feature in
            executionOrder.append("BeforeFeature2")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        BeforeFeature { feature in
            executionOrder.append("BeforeFeature")
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
        }

        Given("some precondition") { _, _ in executionOrder.append("Given") }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["BeforeFeature2", "BeforeFeature", "Given"])
    }
}
