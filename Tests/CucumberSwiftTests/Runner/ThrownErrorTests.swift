//
//  ThrownErrorTests.swift
//  CucumberSwiftTests
//
//  A step that throws fails with the error's own description, and a failed `try #require` with its
//  expectation, as the Swift Testing runner reports them (#563). These tests run each step's test body, as
//  XCTest would, without running a feature suite or a nested XCTest run.
//

import Foundation
import XCTest
#if canImport(Testing)
import Testing
#endif
@testable import CucumberSwift

private struct Described: Error, CustomStringConvertible { var description: String { "the card was declined" } }

private struct Localized: LocalizedError { var errorDescription: String? { "the voucher expired" } }

class ThrownErrorTests: XCTestCase {
    private var capturing = false
    private var recordedIssues = [XCTIssue]()

    // While a step runs, keep the failures it records, and tell CucumberSwift about them as XCTest would.
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

    private static func resetCucumber() {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        StepTestCase.skippedScenarios.removeAll()
    }

    /// Runs the one step that throws `error`, and returns what the step failed with.
    private func messageOfStep(throwing error: @escaping () throws -> Void) throws -> String {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Payments
           Scenario: Pay
             When I pay
        """)
        When("I pay") { _, _ in try error() }
        let step = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first?.steps.first)

        capturing = true
        defer { capturing = false }
        step.method(at: 0, of: 1)?.closure()

        XCTAssertEqual(recordedIssues.count, 1)
        XCTAssertEqual(step.errorMessage, recordedIssues.first?.compactDescription)
        return try XCTUnwrap(recordedIssues.first?.compactDescription)
    }

    func testAThrownErrorIsReportedByItsOwnDescription() throws {
        XCTAssertEqual(try messageOfStep { throw Described() }, "the card was declined")
    }

    func testAThrownLocalizedErrorIsReportedByItsErrorDescription() throws {
        XCTAssertEqual(try messageOfStep { throw Localized() }, "the voucher expired")
    }

    // With no test running there is nowhere to record the failure, so it fails the current test directly.
    func testAThrownErrorFailsTheCurrentTestWhenNoTestIsRunning() throws {
        Cucumber.shared.runningTestCaseObserver.testCaseDidFinish(self)
        defer { Cucumber.shared.runningTestCaseObserver.testCaseWillStart(self) }

        // XCTFail adds its own "failed - " to the message.
        XCTAssertEqual(try messageOfStep { throw Described() }, "failed - the card was declined")
    }

    #if canImport(Testing)
    func testAFailedRequireIsReportedByItsExpectation() throws {
        XCTAssertEqual(try messageOfStep { try #require(1 == 2) }, "Expectation failed: 1 == 2")
    }

    func testAFailedRequireOfAPropertyAndOfACallIsReportedByItsExpectation() {
        let numbers = [1]
        let property = captureRequireFailure { try #require(numbers.isEmpty) }
        let call = captureRequireFailure { try #require(numbers.contains(5)) }

        XCTAssertEqual(property, "Expectation failed: numbers.isEmpty")
        XCTAssertEqual(call, "Expectation failed: numbers.contains(5)")
    }

    func testAFailedRequireWithAStringALabelledArgumentAndAnUnknownFormIsReportedAsFarAsItIsKnown() {
        let numbers = [Int](), word = "a"
        let string = captureRequireFailure { try #require(word == "b") }
        let labelled = captureRequireFailure { try #require(numbers.firstIndex(of: 5) != nil) }
        let unknown = captureRequireFailure { try #require(!numbers.isEmpty || numbers.count > 1) }

        XCTAssertEqual(string, "Expectation failed: word == \"b\"")
        XCTAssertEqual(labelled, "Expectation failed: numbers.firstIndex(of: 5) != nil")
        XCTAssertNotNil(unknown)
    }

    private func captureRequireFailure(_ body: () throws -> Void) -> String? {
        do { try body() } catch { return ThrownErrorDescription.of(error) }
        return nil
    }
    #endif
}
