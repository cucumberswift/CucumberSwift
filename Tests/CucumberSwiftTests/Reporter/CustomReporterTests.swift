//
//  CustomReporterTests.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 5/14/21.
//  Copyright © 2021 Tyler Thompson. All rights reserved.
//
// swiftlint:disable file_types_order type_body_length

import Foundation
import XCTest

@testable import CucumberSwift

extension Cucumber: CucumberTestObservable {
    public var observers: [CucumberTestObserver] {
        [ CustomReporterTests.mockObserver ]
    }
}

class MockTestObserver: CucumberTestObserver {
    var testSuiteStarted: (Date) -> Void
    var testSuiteFinished: (Date) -> Void
    var didStartFeature: (Feature, Date) -> Void
    var didStartScenario: (Scenario, Date) -> Void
    var didStartStep: (Step, Date) -> Void
    var didFinishFeature: (Feature, Reporter.Result, Measurement<UnitDuration>) -> Void
    var didFinishScenario: (Scenario, Reporter.Result, Measurement<UnitDuration>) -> Void
    var didFinishStep: (Step, Reporter.Result, Measurement<UnitDuration>) -> Void

    internal init(fakePropertySoThatYouMustUseMultipleTrailingClosureForEverything: () -> Void = { },
                  testSuiteStarted: @escaping (Date) -> Void = { _ in },
                  testSuiteFinished: @escaping (Date) -> Void = { _ in },
                  didStartFeature: @escaping (Feature, Date) -> Void = { _, _ in },
                  didStartScenario: @escaping (Scenario, Date) -> Void = { _, _ in },
                  didStartStep: @escaping (Step, Date) -> Void = { _, _ in },
                  didFinishFeature: @escaping (Feature, Reporter.Result, Measurement<UnitDuration>) -> Void = { _, _, _ in },
                  didFinishScenario: @escaping (Scenario, Reporter.Result, Measurement<UnitDuration>) -> Void = { _, _, _ in },
                  didFinishStep: @escaping (Step, Reporter.Result, Measurement<UnitDuration>) -> Void = { _, _, _ in }) {
        self.testSuiteStarted = testSuiteStarted
        self.testSuiteFinished = testSuiteFinished
        self.didStartFeature = didStartFeature
        self.didStartScenario = didStartScenario
        self.didStartStep = didStartStep
        self.didFinishFeature = didFinishFeature
        self.didFinishScenario = didFinishScenario
        self.didFinishStep = didFinishStep
    }

    func reset() {
        testSuiteStarted = { _ in }
        didStartFeature = { _, _ in }
        didStartScenario = { _, _ in }
        didStartStep = { _, _ in }
        didFinishFeature = { _, _, _ in }
        didFinishScenario = { _, _, _ in }
        didFinishStep = { _, _, _ in }
    }

    func testSuiteStarted(at date: Date) { testSuiteStarted(date) }

    func testSuiteFinished(at date: Date) { testSuiteFinished(date) }

    func didStart(feature: Feature, at date: Date) { didStartFeature(feature, date) }

    func didStart(scenario: Scenario, at date: Date) { didStartScenario(scenario, date) }

    func didStart(step: Step, at date: Date) { didStartStep(step, date) }

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        didFinishFeature(feature, result, duration)
    }

    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        didFinishScenario(scenario, result, duration)
    }

    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        didFinishStep(step, result, duration)
    }
}

class CustomReporterTests: XCTestCase {
    static var mockObserver = MockTestObserver()
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

    override func setUpWithError() throws {
        Cucumber.shared.reset()
        Self.mockObserver.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testDefaultSuiteReturnsEmptyOnSecondCall() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        CucumberTest.resetSetUp()
        let firstSuite = CucumberTest.defaultTestSuite

        // Second call returns empty suite to prevent XCTest from running
        // CucumberTest twice when discovered in both test bundle and framework
        let secondSuite = CucumberTest.defaultTestSuite
        XCTAssertFalse(firstSuite.tests.isEmpty, "First call should return a populated suite")
        XCTAssertTrue(secondSuite.tests.isEmpty, "Second call should return an empty suite")
    }

    func testReporterIsToldWhenTestSuiteStarts() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        Self.mockObserver.testSuiteStarted = { _ in called += 1 }

        Cucumber.shared.executeFeatures(callDefaultTestSuite: true)

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldWhenTestSuiteFinishes() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        Self.mockObserver.testSuiteFinished = { _ in called += 1 }

        Cucumber.shared.testBundleDidFinish(Bundle(for: Self.self))

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldWhenFeatureStarts() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        Self.mockObserver.didStartFeature = { feature, _ in
            defer { called += 1 }
            XCTAssertEqual(feature.title, "Some terse yet descriptive text of what is desired")
            XCTAssertEqual(feature.scenarios.count, 2)
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldWhenScenarioStarts() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        var scenarios = [Scenario]()
        Self.mockObserver.didStartScenario = { scenario, _ in
            defer { called += 1 }
            scenarios.append(scenario)
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 2)
        XCTAssertEqual(scenarios.first?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(scenarios.first?.title, "Some determinable business situation")
        XCTAssertEqual(scenarios.first?.steps.count, 6)
        XCTAssertEqual(scenarios.last?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(scenarios.last?.title, "Some other determinable business situation")
        XCTAssertEqual(scenarios.last?.steps.count, 4)
    }

    func testReporterIsToldWhenStepStarts() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        var steps = [Step]()
        Self.mockObserver.didStartStep = { step, _ in
            defer { called += 1 }
            steps.append(step)
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 10)
        XCTAssertEqual(steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(steps[safe: 0]?.match, "some precondition")
        XCTAssertEqual(steps[safe: 0]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 0]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 1]?.keyword, [.given, .and])
        XCTAssertEqual(steps[safe: 1]?.match, "some other precondition")
        XCTAssertEqual(steps[safe: 1]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 1]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 2]?.keyword, .when)
        XCTAssertEqual(steps[safe: 2]?.match, "some action by the actor")
        XCTAssertEqual(steps[safe: 2]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 2]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 3]?.keyword, [.when, .and])
        XCTAssertEqual(steps[safe: 3]?.match, "some other action")
        XCTAssertEqual(steps[safe: 3]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 3]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 4]?.keyword, [.when, .and])
        XCTAssertEqual(steps[safe: 4]?.match, "yet another action")
        XCTAssertEqual(steps[safe: 4]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 4]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 5]?.keyword, .then)
        XCTAssertEqual(steps[safe: 5]?.match, "some testable outcome is achieved")
        XCTAssertEqual(steps[safe: 5]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 5]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")

        XCTAssertEqual(steps[safe: 6]?.keyword, .given)
        XCTAssertEqual(steps[safe: 6]?.match, "some precondition")
        XCTAssertEqual(steps[safe: 6]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 6]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 7]?.keyword, [.given, .and])
        XCTAssertEqual(steps[safe: 7]?.match, "some other precondition")
        XCTAssertEqual(steps[safe: 7]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 7]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 8]?.keyword, .when)
        XCTAssertEqual(steps[safe: 8]?.match, "some action by the actor")
        XCTAssertEqual(steps[safe: 8]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 8]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 9]?.keyword, .then)
        XCTAssertEqual(steps[safe: 9]?.match, "some testable outcome is achieved")
        XCTAssertEqual(steps[safe: 9]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 9]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
    }

    func testReporterIsToldWhenStepFinishes() {
        Cucumber.shared.parseIntoFeatures(featureFile)
        var called = 0
        var steps = [Step]()
        Self.mockObserver.didFinishStep = { step, _, _ in
            defer { called += 1 }
            steps.append(step)
            XCTAssertEqual(step.result, .pending)
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 10)
        XCTAssertEqual(steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(steps[safe: 0]?.match, "some precondition")
        XCTAssertEqual(steps[safe: 0]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 0]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 1]?.keyword, [.given, .and])
        XCTAssertEqual(steps[safe: 1]?.match, "some other precondition")
        XCTAssertEqual(steps[safe: 1]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 1]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 2]?.keyword, .when)
        XCTAssertEqual(steps[safe: 2]?.match, "some action by the actor")
        XCTAssertEqual(steps[safe: 2]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 2]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 3]?.keyword, [.when, .and])
        XCTAssertEqual(steps[safe: 3]?.match, "some other action")
        XCTAssertEqual(steps[safe: 3]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 3]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 4]?.keyword, [.when, .and])
        XCTAssertEqual(steps[safe: 4]?.match, "yet another action")
        XCTAssertEqual(steps[safe: 4]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 4]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 5]?.keyword, .then)
        XCTAssertEqual(steps[safe: 5]?.match, "some testable outcome is achieved")
        XCTAssertEqual(steps[safe: 5]?.scenario?.title, "Some determinable business situation")
        XCTAssertEqual(steps[safe: 5]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")

        XCTAssertEqual(steps[safe: 6]?.keyword, .given)
        XCTAssertEqual(steps[safe: 6]?.match, "some precondition")
        XCTAssertEqual(steps[safe: 6]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 6]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 7]?.keyword, [.given, .and])
        XCTAssertEqual(steps[safe: 7]?.match, "some other precondition")
        XCTAssertEqual(steps[safe: 7]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 7]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 8]?.keyword, .when)
        XCTAssertEqual(steps[safe: 8]?.match, "some action by the actor")
        XCTAssertEqual(steps[safe: 8]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 8]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
        XCTAssertEqual(steps[safe: 9]?.keyword, .then)
        XCTAssertEqual(steps[safe: 9]?.match, "some testable outcome is achieved")
        XCTAssertEqual(steps[safe: 9]?.scenario?.title, "Some other determinable business situation")
        XCTAssertEqual(steps[safe: 9]?.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
    }

    func testReporterIsToldAboutPassingSteps() {
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Scenario: Some determinable business situation
         Given some precondition
    """)
        var called = 0
        Self.mockObserver.didFinishStep = { step, _, _ in
            defer { called += 1 }
            XCTAssertEqual(step.keyword, .given)
            XCTAssertEqual(step.match, "some precondition")
            XCTAssertEqual(step.scenario?.title, "Some determinable business situation")
            XCTAssertEqual(step.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
            XCTAssertEqual(step.result, .passed)
        }

        Given("some precondition") { _, _ in
            XCTAssert(true)
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldAboutFailingSteps() throws {
        throw XCTSkip("Unfortunately this test is designed to have XCTest fail, so even the new XCTExpectFailure thing does not work.")
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Scenario: Some determinable business situation
         Given some precondition
    """)
        var called = 0
        Self.mockObserver.didFinishStep = { step, result, _ in
            defer { called += 1 }
            XCTAssertEqual(step.keyword, .given)
            XCTAssertEqual(step.match, "some precondition")
            XCTAssertEqual(step.scenario?.title, "Some determinable business situation")
            XCTAssertEqual(step.scenario?.feature?.title, "Some terse yet descriptive text of what is desired")
            XCTAssertEqual(result, .failed("failed - should have failed"))
        }

        Given("some precondition") { _, _ in
            XCTFail("should have failed")
        }

        Cucumber.shared.reporters.forEach { $0.testSuiteStarted(at: Date()) }
        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldAboutFailingScenarios() throws {
        throw XCTSkip("Unfortunately this test is designed to have XCTest fail, so even the new XCTExpectFailure thing does not work.")
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Scenario: Some determinable business situation
         Given some precondition
    """)
        var called = 0
        Self.mockObserver.didFinishScenario = { _, result, _ in
            defer { called += 1 }
            XCTAssertEqual(result, .failed("failed - should have failed"))
        }

        Given("some precondition") { _, _ in
            XCTFail("should have failed")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 1)
    }

    func testReporterIsToldAboutFailingFeatures() throws {
        throw XCTSkip("Unfortunately this test is designed to have XCTest fail, so even the new XCTExpectFailure thing does not work.")
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
       Textual description of the business value of this feature
       Business rules that govern the scope of the feature
       Any additional information that will make the feature easier to understand

       Scenario: Some determinable business situation
         Given some precondition
    """)
        var called = 0
        Self.mockObserver.didFinishFeature = { _, result, _ in
            defer { called += 1 }
            XCTAssertEqual(result, .failed("failed - should have failed"))
        }

        Given("some precondition") { _, _ in
            XCTFail("should have failed")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(called, 1)
    }
}
