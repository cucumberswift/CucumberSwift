//
//  UndefinedStepTests.swift
//  CucumberSwiftTests
//
//  A step that no step definition matches fails its own test, at its line in the feature file, and the
//  steps after it are skipped, as with one test per scenario (#262). testGherkin no longer reports it, so
//  it is reported once. These tests run each step's test body in order, as XCTest would, without running
//  a feature suite or a nested XCTest run.
//

import Foundation
import XCTest
@testable import CucumberSwift

class UndefinedStepTests: XCTestCase {
    private static let featureURI = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Undefined.feature").absoluteString

    private var capturing = false
    private var recordedIssues = [XCTIssue]()

    private static func resetCucumber() {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        StepTestCase.skippedScenarios.removeAll()
    }

    // While a step runs, keep the failures it records, and tell CucumberSwift about them as XCTest would,
    // so that a failed scenario skips its remaining steps. Other failures fail this test.
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

    override func setUpWithError() throws {
        Self.resetCucumber()
        addTeardownBlock { Self.resetCucumber() }
    }

    private var scenarios: [Scenario] {
        Cucumber.shared.features.flatMap(\.scenarios)
    }

    /// Runs each step's test in order, as a test per step does: a step that its test would skip doesn't run.
    /// Returns the steps that were skipped.
    @discardableResult
    private func runStepTests(of scenario: Scenario) -> [Step] {
        capturing = true
        defer { capturing = false }
        var skipped = [Step]()
        for (index, step) in scenario.steps.enumerated() {
            if StepTestCase.skipReason(for: step) != nil {
                skipped.append(step)
                continue
            }
            step.method(at: index, of: scenario.steps.count)?.closure()
        }
        return skipped
    }

    func testAnUndefinedStepFailsItsOwnTestAndTheStepsAfterItAreSkipped() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Calculator
           Scenario: Add two numbers
             Given I have entered 2 into the calculator
             And the display shows "2"
             When I press add
        """, uri: Self.featureURI)
        var events = [String]()
        Given("I have entered {int} into the calculator") { _, _ in events.append("Given") }
        When("I press add") { _, _ in events.append("When") }
        let scenario = try XCTUnwrap(scenarios.first)

        let skipped = runStepTests(of: scenario)

        XCTAssertEqual(recordedIssues.count, 1)
        let issue = try XCTUnwrap(recordedIssues.first)
        XCTAssertTrue(issue.compactDescription.hasPrefix("No CucumberSwift expression found that matches this step."), issue.compactDescription)
        XCTAssertTrue(issue.compactDescription.contains(#"Given(#/^the display shows \"(.*?)\"$/#)"#), issue.compactDescription)
        XCTAssertEqual(issue.sourceCodeContext.location?.fileURL, URL(string: Self.featureURI))
        XCTAssertEqual(issue.sourceCodeContext.location?.lineNumber, 4)
        XCTAssertEqual(issue.attachments.map(\.name), ["Undefined.feature:4"])
        XCTAssertEqual(events, ["Given"])
        XCTAssertTrue(skipped.first === scenario.steps[2])
        XCTAssertEqual(StepTestCase.skipReason(for: scenario.steps[2]), StepTestCase.skippedAfterFailureMessage)
    }

    // Steps that differ only in their arguments share one generated step definition. Each one's failure has it.
    func testEachUndefinedStepThatSharesAGeneratedStepDefinitionHasIt() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Calculator
           Scenario: Add two numbers
             Given I have entered 2 into the calculator
           Scenario: Add three numbers
             Given I have entered 3 into the calculator
        """, uri: Self.featureURI)

        scenarios.forEach { runStepTests(of: $0) }

        XCTAssertEqual(recordedIssues.count, 2)
        XCTAssertEqual(recordedIssues.map(\.sourceCodeContext.location?.lineNumber), [3, 5])
        recordedIssues.forEach {
            XCTAssertTrue($0.compactDescription.contains(#"Given(#/^I have entered (\d+) into the calculator$/#)"#), $0.compactDescription)
        }
    }

    // Each undefined step fails in its own test, so testGherkin doesn't report it a second time.
    func testTestGherkinDoesNotReportAnUndefinedStep() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Calculator
           Scenario: Add two numbers
             Given I have entered 2 into the calculator
        """, uri: Self.featureURI)

        capturing = true
        CucumberTest().testGherkin()
        capturing = false

        XCTAssertFalse(recordedIssues.contains { $0.compactDescription.hasPrefix("No CucumberSwift expression found") },
                       recordedIssues.map(\.compactDescription).joined(separator: "\n"))
    }
}
