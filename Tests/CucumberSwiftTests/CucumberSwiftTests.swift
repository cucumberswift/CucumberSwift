//
//  CucumberSwiftTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length file_length

import XCTest
import CucumberSwiftExpressions
@testable import CucumberSwift

class CucumberSwiftTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testStepsGetCallbacksAttachedCorrectly() {
        let bundle: Bundle = {
            #if canImport(CucumberSwift_ObjC)
            // swiftlint:disable:next force_unwrapping
            return Bundle(url: Bundle.module.bundleURL.deletingLastPathComponent().appendingPathComponent("CucumberSwift_CucumberSwiftTests.bundle"))!
            #else
            return Bundle(for: CucumberSwiftTests.self)
            #endif
        }()

        Cucumber.shared.readFromFeaturesFolder(in: bundle)
        var givenCalled = false
        Given("S(.)mE (?:precondition)") { matches, _  in
            givenCalled = true
            XCTAssertEqual(matches.count, 2)
            XCTAssertEqual(matches.last, "o")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(givenCalled)

        var whenCalled = false
        When("(.*?)") { matches, _ in
            whenCalled = true
            XCTAssertEqual(matches.count, 2)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(whenCalled)

        var thenCalled = false
        Then("(.*?)") { matches, _ in
            thenCalled = true
            XCTAssertEqual(matches.count, 2)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(thenCalled)

        var andCalled = false
        And("(.*?)") { matches, _ in
            andCalled = true
            XCTAssertEqual(matches.count, 2)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(andCalled)

        var butCalled = false
        But("(.*?)") { matches, _ in
            butCalled = true
            XCTAssertEqual(matches.count, 1)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertFalse(butCalled)

        var matchAllCalled = false
        MatchAll("(.*?)") { matches, _ in
            matchAllCalled = true
            XCTAssertEqual(matches.count, 2)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(matchAllCalled)
    }

#if swift(>=5.7)
    @available(iOS 16.0, *)
    func testStepsGetCallbacksAttachedCorrectly_WithRegexLiterals() {
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
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalled = false
        Given(/^S(.)mE (?:precondition)$/.ignoresCase()) { match, _  in
            givenCalled = true
            XCTAssertEqual(match.1, "o")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(givenCalled)

        var whenCalled = false
        When(/^some (\w+) by the actor$/) { match, _ in
            whenCalled = true
            XCTAssertEqual(match.1, "action")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(whenCalled)

        var thenCalled = false
        Then(/^some (\w+) outcome is achieved$/) { match, _ in
            thenCalled = true
            XCTAssertEqual(match.1, "testable")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(thenCalled)

        var andCalled = false
        Given(/^some (\w+) precondition$/) { match, _ in
            andCalled = true
            XCTAssertEqual(match.1, "other")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(andCalled)

        var matchAllCalled = false
        MatchAll(/(.*?)/) { _, _ in
            matchAllCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(matchAllCalled)
    }
#endif

    func testExecuteFirstStep_WithoutParameter() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalledCount = 0
        Given("some precondition") { _, _  in
            givenCalledCount += 1
        }

        Given("some other precondition") { _, _  in
            ExecuteFirstStep(matching: "some precondition")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenCalledCount, 2)
    }

    func testExecuteFirstStep_WithKeyword() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some text
             When some text
             Then some then text

        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalledCount = 0
        Given("some text") { _, _  in
            givenCalledCount += 1
        }

        var whenCalledCount = 0
        When("some text") { _, _  in
            whenCalledCount += 1
        }

        Then("some then text") { _, _ in
            ExecuteFirstStep(keyword: .when, matching: "some text")
            ExecuteFirstStep(keyword: .given, matching: "some text")
            ExecuteFirstStep(keyword: .given, matching: "some text")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenCalledCount, 3)
        XCTAssertEqual(whenCalledCount, 2)
    }

    func testExecuteFirstStep_WithParameter() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition with parameter1
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenParameters = [String]()
        Given("some precondition with (.*)") { match, _  in
            givenParameters.append(match[1])
        }

        Given("some other precondition") { _, _  in
            ExecuteFirstStep(matching: "some precondition with parameter2")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenParameters.count, 2)
        XCTAssertEqual(givenParameters[0], "parameter1")
        XCTAssertEqual(givenParameters[1], "parameter2")
    }

    func testExecuteFirstStep_WithoutParameterWithCucumberExpression() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalledCount = 0
        Given("some precondition" as CucumberExpression) { _, _  in
            givenCalledCount += 1
        }

        Given("some other precondition" as CucumberExpression) { _, _  in
            ExecuteFirstStep(matching: "some precondition")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenCalledCount, 2)
    }

    func testExecuteFirstStep_WithParameterWithCucumberExpression() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition with parameter1
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenParameters = [String]()
        Given("some precondition with {}" as CucumberExpression) { match, _  in
            givenParameters.append(try match.first(\.anonymous))
        }

        Given("some other precondition" as CucumberExpression) { _, _  in
            ExecuteFirstStep(matching: "some precondition with parameter2")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenParameters.count, 2)
        XCTAssertEqual(givenParameters[0], "parameter1")
        XCTAssertEqual(givenParameters[1], "parameter2")
    }

    func testExecuteFirstStep_WithKeywordWithCucumberExpression() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some text
             When some text
             Then some then text

        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalledCount = 0
        Given("some text" as CucumberExpression) { _, _  in
            givenCalledCount += 1
        }

        var whenCalledCount = 0
        When("some text" as CucumberExpression) { _, _  in
            whenCalledCount += 1
        }

        Then("some then text" as CucumberExpression) { _, _ in
            ExecuteFirstStep(keyword: .when, matching: "some text")
            ExecuteFirstStep(keyword: .given, matching: "some text")
            ExecuteFirstStep(keyword: .given, matching: "some text")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenCalledCount, 3)
        XCTAssertEqual(whenCalledCount, 2)
    }

#if swift(>=5.7)
    @available(iOS 16.0, *)
    func testExecuteFirstStep_WithoutParameterWithRegexLiteral() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalledCount = 0
        Given(/^some precondition$/) { _, _  in
            givenCalledCount += 1
        }

        Given(/^some other precondition$/) { _, _  in
            ExecuteFirstStep(matching: "some precondition")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenCalledCount, 2)
    }

    @available(iOS 16.0, *)
    func testExecuteFirstStep_WithParameterWithRegexLiteral() {
        let featureFile: String =
        """
        Feature: Some text

           Scenario: Some determinable business situation
             Given some precondition with parameter1
               And some other precondition
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenParameters = [String]()
        Given(/some precondition with (.*)/) { match, _  in
            givenParameters.append("\(match.1)")
        }

        Given(/some other precondition/) { _, _  in
            ExecuteFirstStep(matching: "some precondition with parameter2")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertEqual(givenParameters.count, 2)
        XCTAssertEqual(givenParameters[0], "parameter1")
        XCTAssertEqual(givenParameters[1], "parameter2")
    }
#endif

    func testStepsGetCallbacksAttachedCorrectly_WithCucumberExpressions() {
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
        """

        Cucumber.shared.parseIntoFeatures(featureFile)
        var givenCalled = false
        Given("some {word}" as CucumberExpression) { match, _  in
            givenCalled = true
            XCTAssertEqual(try match.first(\.word), "precondition")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(givenCalled)

        var whenCalled = false
        When("some {word} by the actor" as CucumberExpression) { match, _ in
            whenCalled = true
            XCTAssertEqual(try match.first(\.word), "action")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(whenCalled)

        var thenCalled = false
        Then("some {word} outcome is achieved" as CucumberExpression) { match, _ in
            thenCalled = true
            XCTAssertEqual(try match.first(\.word), "testable")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(thenCalled)

        var andCalled = false
        Given("some {word} precondition" as CucumberExpression) { match, _ in
            andCalled = true
            XCTAssertEqual(try match.first(\.word), "other")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(andCalled)

        var matchAllCalled = false
        MatchAll("{}" as CucumberExpression) { _, _ in
            matchAllCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(matchAllCalled)
    }

    func testGivenWorksForChainedAnd() {
        let bundle: Bundle = {
            #if canImport(CucumberSwift_ObjC)
            // swiftlint:disable:next force_unwrapping
            return Bundle(url: Bundle.module.bundleURL.deletingLastPathComponent().appendingPathComponent("CucumberSwift_CucumberSwiftTests.bundle"))!
            #else
            return Bundle(for: CucumberSwiftTests.self)
            #endif
        }()

        Cucumber.shared.readFromFeaturesFolder(in: bundle)
        var givenCalled = false
        Given("S(.)mE (?:precondition)") { matches, _  in
            givenCalled = true
            XCTAssertEqual(matches.count, 2)
            XCTAssertEqual(matches.last, "o")
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(givenCalled)

        var andCalled = false
        Given("some other precondition") { matches, _ in
            andCalled = true
            XCTAssertEqual(matches.count, 1)
        }
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(andCalled)
    }

    func testStepFailsIfObserverCallsBackWithFailure() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.currentStep = Step(with: AST.StepNode())

        XCTAssertEqual(Cucumber.shared.currentStep?.result, .pending)

        let errorMessage = "You did something stupid"
        Cucumber.shared.testCase(XCTestCase(), didFailWithDescription: errorMessage, inFile: nil, atLine: 0)
        XCTAssertEqual(Cucumber.shared.currentStep?.result, .failed)
        XCTAssertEqual(Cucumber.shared.currentStep?.errorMessage, errorMessage)
    }

    func testRemainingStepsInScenarioAreSkippedIfStepFails() {
        Cucumber.shared.features.removeAll()
        let step1 = Step(with: AST.StepNode())
        step1.result = .passed
        let step2 = Step(with: AST.StepNode())
        let step3 = Step(with: AST.StepNode())
        let scenario = Scenario(with: [ step1, step2, step3 ],
                                title: "test",
                                tags: [],
                                position: .start)
        step1.scenario = scenario
        step2.scenario = scenario
        step3.scenario = scenario
        Cucumber.shared.currentStep = step2

        XCTAssertEqual(step2.result, .pending)

        let errorMessage = "You did something stupid"
        Cucumber.shared.testCase(XCTestCase(), didFailWithDescription: errorMessage, inFile: nil, atLine: 0)
        XCTAssertEqual(step1.result, .passed)
        XCTAssertEqual(step2.result, .failed)
        XCTAssertEqual(step2.errorMessage, errorMessage)
        XCTAssertEqual(step3.result, .skipped)
    }
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        Bundle(for: CucumberSwiftTests.self)
    }
    static var shouldRunWith: (Scenario?, [String]) -> Bool = { _, _ in true }
    public func setupSteps() { }
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        Cucumber.shouldRunWith(scenario, tags)
    }

    public static var overrideReverseOrderForAfterHooks = false
    public var reverseOrderForAfterHooks: Bool { Cucumber.overrideReverseOrderForAfterHooks }

    public static var overrideStrictPendingSteps = false
    public var strictPendingSteps: Bool { Cucumber.overrideStrictPendingSteps }
}
