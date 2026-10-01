//
//  StepTestCaseTests.swift
//  CucumberSwiftTests
//

import XCTest
@testable import CucumberSwift

final class StepTestCaseTests: XCTestCase {
    private final class Probe: StepTestCase {
        func testProbe() {}
    }

    private static func allTests(in suite: XCTestSuite) -> [XCTest] {
        suite.tests.flatMap { ($0 as? XCTestSuite).map(allTests(in:)) ?? [$0] }
    }

    override func setUpWithError() throws {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        addTeardownBlock {
            Cucumber.shared.reset()
            Cucumber.shared.failedScenarios.removeAll()
        }
    }

    func testAStepAfterAFailedStepIsSkippedNotPassed() {
        let probe = Probe(selector: #selector(Probe.testProbe))
        probe.skipReason = { StepTestCase.skippedAfterFailureMessage }

        XCTAssertThrowsError(try probe.setUpWithError()) { error in
            XCTAssert(error is XCTSkip)
        }
    }

    func testAStepRunsWhenNothingFailedBeforeIt() throws {
        let probe = Probe(selector: #selector(Probe.testProbe))
        probe.skipReason = { nil }

        XCTAssertNoThrow(try probe.setUpWithError())
    }

    func testGeneratedStepTestCasesAreStepTestCases() throws {
        let generated = try XCTUnwrap(TestCaseGenerator.makeClass(className: "StepTestCaseTestsGenerated", superclass: StepTestCase.self))
        XCTAssert(generated.isSubclass(of: StepTestCase.self))
    }

    func testGeneratedStepsSkipOnlyWhenTheirOwnScenarioFailed() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some text
           Scenario: First scenario
             Given a first step
             When a second step
           Scenario: Other scenario
             Given a first step
        """)
        Given("a first step") { _, _ in }
        When("a second step") { _, _ in }

        let suite = XCTestSuite(name: "Dummy")
        CucumberTest.generateAlltests(suite)
        let stepTests = Self.allTests(in: suite).compactMap { $0 as? StepTestCase }
        let scenarios = try XCTUnwrap(Cucumber.shared.features.first?.scenarios)
        XCTAssertEqual(stepTests.count, 3)

        XCTAssertNoThrow(try stepTests.forEach { try $0.setUpWithError() })

        Cucumber.shared.failedScenarios.append(scenarios[0])

        XCTAssertThrowsError(try stepTests[0].setUpWithError()) { XCTAssert($0 is XCTSkip) }
        XCTAssertThrowsError(try stepTests[1].setUpWithError()) { XCTAssert($0 is XCTSkip) }
        XCTAssertNoThrow(try stepTests[2].setUpWithError())
    }
}
