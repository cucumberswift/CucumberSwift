//
//  ScenarioRunTests.swift
//  CucumberSwiftTests
//
//  With one test per scenario, a scenario's steps run in order within its test. These tests run one
//  scenario's steps as its test would, without running a feature suite or a nested XCTest run (#59).
//

import Foundation
import XCTest
@testable import CucumberSwift

class ScenarioRunTests: XCTestCase {
    private var capturing = false
    private var recordedIssues = [XCTIssue]()

    private static func resetCucumber() {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        StepTestCase.skippedScenarios.removeAll()
        Cucumber.overrideContinueTestingAfterFailure = nil
    }

    // While a scenario runs, keep the failures its steps record, and tell CucumberSwift about them as
    // XCTest would, so that a failed scenario skips its remaining steps. Other failures fail this test.
    override func record(_ issue: XCTIssue) {
        guard capturing else {
            super.record(issue)
            return
        }
        recordedIssues.append(issue)
        Cucumber.shared.testCase(self,
                                 didFailWithDescription: issue.compactDescription,
                                 inFile: issue.sourceCodeContext.location?.fileURL.path,
                                 atLine: issue.sourceCodeContext.location?.lineNumber ?? 0)
    }

    /// Runs the first scenario of the features parsed so far, as its scenario test would.
    private func runFirstScenario() throws -> XCTSkip? {
        let scenario = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first)
        capturing = true
        defer { capturing = false }
        return CucumberTest.run(scenario, on: self)
    }

    override func setUpWithError() throws {
        Self.resetCucumber()
        addTeardownBlock { Self.resetCucumber() }
    }

    func testTheStepsRunInOrderWithTheirHooks() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given a cart
             When I pay
             Then I get a receipt
        """)
        var events = [String]()
        Given("a cart") { _, _ in events.append("Given") }
        When("I pay") { _, _ in events.append("When") }
        Then("I get a receipt") { _, _ in events.append("Then") }
        AfterStep { _ in events.append("after step") }
        AfterScenario { _ in events.append("after scenario") }

        let skip = try runFirstScenario()

        XCTAssertNil(skip)
        XCTAssertTrue(recordedIssues.isEmpty)
        XCTAssertEqual(events, ["Given", "after step", "When", "after step", "Then", "after step", "after scenario"])
    }

    func testAFailingStepFailsTheScenarioAndTheRestDontRun() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given a cart
             When I pay
             Then I get a receipt
        """)
        var events = [String]()
        Given("a cart") { _, _ in events.append("Given") }
        When("I pay") { _, _ in XCTFail("The payment failed") }
        Then("I get a receipt") { _, _ in events.append("Then") }
        AfterScenario { _ in events.append("after scenario") }

        let skip = try runFirstScenario()

        XCTAssertNil(skip)
        XCTAssertEqual(recordedIssues.count, 1)
        XCTAssertEqual(events, ["Given", "after scenario"])
    }

    func testAStepThatThrowsXCTSkipSkipsTheScenario() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given the card terminal is offline
             Then I get a receipt
        """)
        var events = [String]()
        Given("the card terminal is offline") { _, _ in throw XCTSkip("Offline") }
        Then("I get a receipt") { _, _ in events.append("Then") }

        let skip = try runFirstScenario()

        XCTAssertEqual(skip?.message, "Offline")
        XCTAssertTrue(recordedIssues.isEmpty)
        XCTAssertEqual(events, [])
    }

    // A step that records a failure and then throws XCTSkip leaves the scenario failed, not skipped.
    func testAFailureThenXCTSkipLeavesTheScenarioFailed() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given the card terminal is offline
             Then I get a receipt
        """)
        var events = [String]()
        Given("the card terminal is offline") { _, _ in
            XCTFail("The terminal did not answer")
            throw XCTSkip("Offline")
        }
        Then("I get a receipt") { _, _ in events.append("Then") }

        let skip = try runFirstScenario()

        XCTAssertNil(skip, "A failed scenario is reported as failed, not skipped")
        XCTAssertEqual(recordedIssues.count, 1)
        XCTAssertEqual(events, [])
    }

    // With continueTestingAfterFailure off, the scenario's test is set not to continue after a failure,
    // so XCTest stops it at the failed assertion, as it stops a step's test.
    func testTheScenarioTestTakesContinueTestingAfterFailure() throws {
        Cucumber.overrideContinueTestingAfterFailure = false
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             When I pay
        """)
        When("I pay") { _, _ in }
        addTeardownBlock { [weak self] in self?.continueAfterFailure = true }

        _ = try runFirstScenario()

        XCTAssertFalse(continueAfterFailure)
    }

    // A step with no step definition fails its scenario's test, at the step's line, with the step
    // definition to add, and the steps after it don't run (#262).
    func testAScenarioWithAnUndefinedStepFails() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given a cart
             When nothing matches this step
             Then I get a receipt
        """, uri: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Checkout.feature").absoluteString)
        var events = [String]()
        Given("a cart") { _, _ in events.append("Given") }
        Then("I get a receipt") { _, _ in events.append("Then") }

        let skip = try runFirstScenario()

        XCTAssertNil(skip)
        XCTAssertEqual(recordedIssues.count, 1)
        XCTAssertTrue(recordedIssues.first?.compactDescription.hasPrefix("No CucumberSwift expression found") ?? false)
        XCTAssertTrue(recordedIssues.first?.compactDescription.contains("When(#/^nothing matches this step$/#)") ?? false)
        XCTAssertEqual(recordedIssues.first?.sourceCodeContext.location?.lineNumber, 4)
        XCTAssertEqual(events, ["Given"])
    }

    // While a scenario's step runs, a failure in its step definition is located at the step's line.
    func testAFailureDuringAStepIsLocatedAtTheStepsLine() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Checkout
           Scenario: Pay
             Given a cart
        """, uri: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Located.feature").absoluteString)
        var line: Int?
        Given("a cart") { _, _ in
            let issue = XCTIssue(type: .assertionFailure,
                                 compactDescription: "failed",
                                 detailedDescription: nil,
                                 sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: "Steps.swift", lineNumber: 7)),
                                 associatedError: nil,
                                 attachments: [])
            line = CucumberTestSupport.locateIssue(issue).sourceCodeContext.location?.lineNumber
        }

        _ = try runFirstScenario()

        XCTAssertEqual(line, 3)
    }

    // Both Objective-C test classes ask CucumberSwift where to record an issue, then record it. On a test
    // that isn't running, XCTest passes the issue to the running one, this test, which keeps it.
    func testTheObjectiveCTestClassesPassTheirIssuesOn() throws {
        let stepClass = try XCTUnwrap(TestCaseGenerator.makeClass(className: "ScenarioRunTestsRecord", superclass: StepTestCase.superclass))
        let scenarioClass = try XCTUnwrap(CucumberTest.scenarioTestClass)
        let issue = XCTIssue(type: .assertionFailure,
                             compactDescription: "failed",
                             detailedDescription: nil,
                             sourceCodeContext: XCTSourceCodeContext(),
                             associatedError: nil,
                             attachments: [])

        capturing = true
        stepClass.init().record(issue)
        scenarioClass.init().record(issue)
        capturing = false

        XCTAssertEqual(recordedIssues.count, 2)
    }
}
