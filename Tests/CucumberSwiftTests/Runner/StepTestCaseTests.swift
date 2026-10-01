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
}
