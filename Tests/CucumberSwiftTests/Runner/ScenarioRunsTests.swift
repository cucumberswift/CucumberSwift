//
//  ScenarioRunsTests.swift
//  CucumberSwiftTests
//
//  CucumberSwift fails a scenario that starts twice in one process, and a parallel run whose scenario
//  classes were made too late for XCTest to hand out (#386). These tests count and build; they don't run scenarios.
//

import Foundation
import XCTest
@testable import CucumberSwift

class ScenarioRunsTests: XCTestCase {
    private static func reset() {
        Cucumber.parallelTesting = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.shared.reset()
        CucumberTest.resetSetUp()
    }

    override func setUpWithError() throws {
        Self.reset()
        addTeardownBlock { Self.reset() }
    }

    private func parseFeature() -> [Scenario] {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Runs \(UUID().uuidString)
           Scenario: Pay by card
             Given a cart
           Scenario: Pay with a gift card
             Given a cart
        """)
        CucumberTest.featuresLoaded = true
        return Cucumber.shared.features.flatMap(\.scenarios)
    }

    func testTheFirstStartOfAScenarioIsCountedOnce() throws {
        let scenario = try XCTUnwrap(parseFeature().first)

        XCTAssertEqual(ScenarioRuns.recordStart(of: scenario), 1)
    }

    func testEachStartOfTheSameScenarioIsCounted() throws {
        let scenario = try XCTUnwrap(parseFeature().first)

        ScenarioRuns.recordStart(of: scenario)

        XCTAssertEqual(ScenarioRuns.recordStart(of: scenario), 2)
    }

    func testScenariosAreCountedSeparately() throws {
        let scenarios = parseFeature()
        ScenarioRuns.recordStart(of: scenarios[0])

        XCTAssertEqual(ScenarioRuns.recordStart(of: scenarios[1]), 1)
    }

    func testResettingForgetsTheStarts() throws {
        let scenario = try XCTUnwrap(parseFeature().first)
        ScenarioRuns.recordStart(of: scenario)

        ScenarioRuns.reset()

        XCTAssertEqual(ScenarioRuns.recordStart(of: scenario), 1)
    }

    func testTheMessageNamesTheScenarioAndHowOftenItStarted() throws {
        let scenario = try XCTUnwrap(parseFeature().first)

        let message = ScenarioRuns.repeatedScenarioMessage(for: scenario, count: 2)

        XCTAssertTrue(message.contains("'Pay by card'"), message)
        XCTAssertTrue(message.contains("2 times"), message)
    }

    func testTheIssueIsAnAssertionFailureWithTheMessage() throws {
        let scenario = try XCTUnwrap(parseFeature().first)

        let issue = ScenarioRuns.repeatedScenarioIssue(for: scenario, count: 3)

        XCTAssertEqual(issue.type, .assertionFailure)
        XCTAssertEqual(issue.compactDescription, ScenarioRuns.repeatedScenarioMessage(for: scenario, count: 3))
    }

    // MARK: - Scenario classes made too late

    func testClassesAreNotTooLateWithoutParallelTesting() {
        _ = parseFeature()

        XCTAssertFalse(ParallelTesting.classesMadeTooLate)
    }

    func testClassesAreTooLateWhenParallelTestingIsOnAndTheyWereNotMade() {
        _ = parseFeature()
        Cucumber.parallelTesting = true

        XCTAssertTrue(ParallelTesting.classesMadeTooLate)
    }

    @MainActor
    func testClassesAreNotTooLateOnceTheyAreMade() {
        _ = parseFeature()
        Cucumber.parallelTesting = true

        ParallelTesting.makeScenarioClasses()

        XCTAssertFalse(ParallelTesting.classesMadeTooLate)
    }

    func testClassesAreNotTooLateWithOneTestPerScenario() {
        _ = parseFeature()
        Cucumber.parallelTesting = true
        Cucumber.oneTestPerScenario = true

        XCTAssertFalse(ParallelTesting.classesMadeTooLate)
    }

    @MainActor
    func testCucumberTestsSuiteHasAFailingTestWhenTheClassesWereMadeTooLate() throws {
        _ = parseFeature()
        Cucumber.parallelTesting = true

        let tests = CucumberTest.defaultTestSuite.tests
        let late = try XCTUnwrap(tests.first { $0.name.contains("ScenarioClassesMadeTooLate") })

        XCTAssertNotNil(late)
    }

    @MainActor
    func testCucumberTestsSuiteHasNoFailingTestWhenTheClassesWereMadeInTime() {
        _ = parseFeature()
        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        let tests = CucumberTest.defaultTestSuite.tests

        XCTAssertFalse(tests.contains { $0.name.contains("ScenarioClassesMadeTooLate") })
    }

    func testTheTooLateTestReportsAMessageThatSaysWhatToDo() throws {
        var reported = [String]()
        let test = try XCTUnwrap(CucumberTest.classesMadeTooLateTest { reported.append($0) })

        test.invokeTest()

        XCTAssertEqual(reported.count, 1)
        XCTAssertTrue(reported.first?.contains("Cucumber.parallelTesting = false") == true, "\(reported)")
    }
}
