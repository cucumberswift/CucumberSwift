//
//  CoverageScoreTestsTests.swift
//  CucumberSwiftTests
//
//  With coverage on, each feature has tests of its own that record its scores' issues after its
//  scenarios, one for each kind of issue, so that no step fails for its feature's scores (#502).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageScoreTestsTests: XCTestCase {
    private let uri = FileManager.default.temporaryDirectory.appendingPathComponent("Adding.feature").absoluteString

    override func setUp() {
        super.setUp()
        CoverageScoreTests.reset()
    }

    override func tearDown() {
        Cucumber.coverage = nil
        Cucumber.parallelTesting = nil
        Cucumber.parallelTestingUnit = nil
        CoverageScoreTests.reset()
        super.tearDown()
    }

    private func feature() throws -> Feature {
        let cucumber = Cucumber(withString: "")
        cucumber.parseIntoFeatures("""
        Feature: Adding
            Scenario: Adding two numbers
                Given a calculator
        """, uri: uri)
        return try XCTUnwrap(cucumber.features.first)
    }

    private func issue(_ kind: CoverageIssue.Kind, line: Int = 1) -> CoverageIssue {
        CoverageIssue(severity: .warning, message: "\(kind)", file: URL(string: uri), line: line, kind: kind)
    }

    func testWithCoverageOffAFeatureHasNoScoreTests() throws {
        Cucumber.coverage = false
        XCTAssertNil(CoverageScoreTests.suite(for: try feature(), className: "Adding|CoverageScoresOff"))
    }

    func testAFeaturesScoreTestsAreATestForEachKindOfIssue() throws {
        Cucumber.coverage = true
        let suite = try XCTUnwrap(CoverageScoreTests.suite(for: try feature(), className: "Adding|CoverageScoresKinds"))
        XCTAssertEqual(suite.tests.count, CoverageIssue.Kind.allCases.count)
        XCTAssertTrue(CoverageScoreTests.isWaiting(for: URL(string: uri)))
    }

    func testTheScoreTestsRecordTheFeaturesIssuesAndThenLetLaterOnesThrough() throws {
        Cucumber.coverage = true
        let suite = try XCTUnwrap(CoverageScoreTests.suite(for: try feature(), className: "Adding|CoverageScoresRun"))
        // Held for the score tests, so that the test running now doesn't record them.
        CoverageScoreTests.receive(issue(.coverage), in: nil)
        CoverageScoreTests.receive(issue(.redundantScenario, line: 2), in: nil)
        // Each score test records its warnings in the test that runs it, here this one.
        for case let test as XCTestCase in suite.tests {
            test.invokeTest()
        }
        XCTAssertFalse(CoverageScoreTests.isWaiting(for: URL(string: uri)))
        // Once they ran, an issue of the feature goes to the test that is running, or is printed.
        CoverageScoreTests.receive(issue(.coverage), in: nil)
        XCTAssertFalse(CoverageScoreTests.isWaiting(for: URL(string: uri)))
    }

    func testAFeatureWithoutScoreTestsGetsItsIssuesInTheRunningTest() {
        XCTAssertFalse(CoverageScoreTests.isWaiting(for: URL(string: uri)))
        // A warning, recorded in this test, which a warning doesn't fail.
        CoverageScoreTests.receive(issue(.coverage), in: self)
    }

    func testTheScoreTestsComeAfterEachFeaturesLastScenario() throws {
        Cucumber.coverage = true
        let first = try feature()
        XCTAssertNil(CucumberTest.scoreTests(after: first, next: first))
        XCTAssertNotNil(CucumberTest.scoreTests(after: first, next: nil))
    }

    func testTheScoreTestsFinishAFeatureWhoseLastScenarioATagLeftOut() throws {
        Cucumber.coverage = true
        let feature = try feature()
        var finished = [Feature]()
        let suite = try XCTUnwrap(CoverageScoreTests.suite(for: feature, className: "Adding|CoverageScoresFinish") { finished.append($0) })
        for case let test as XCTestCase in suite.tests {
            test.invokeTest()
        }
        // Once, before the first records the feature's issues.
        XCTAssertEqual(finished.count, 1)
        XCTAssertTrue(finished.first === feature)
    }

    func testAParallelRunThatHandsOutScenariosScoresNothing() {
        Cucumber.parallelTesting = true
        Cucumber.parallelTestingUnit = .scenario
        XCTAssertNotNil(CoverageScoreTests.settings(environment: [:]).scoresOffReason)
        Cucumber.parallelTestingUnit = .feature
        XCTAssertNil(CoverageScoreTests.settings(environment: [:]).scoresOffReason)
        Cucumber.parallelTesting = false
        Cucumber.parallelTestingUnit = .scenario
        XCTAssertNil(CoverageScoreTests.settings(environment: [:]).scoresOffReason)
    }
}
