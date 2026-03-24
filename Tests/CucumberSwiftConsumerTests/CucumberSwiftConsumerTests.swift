//
//  CucumberSwiftConsumerTests.swift
//  CucumberSwiftConsumerTests
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//
// swiftlint:disable all

import XCTest
import CucumberSwift

class Me: XCTestCase {
    static var unitTestSetupCalled = 0
    static var unitTestExecuted = false
    static var unitTestTearDownCalled = 0

    override func setUp() {
        Me.unitTestSetupCalled += 1
    }

    func unitTestIsExecuted() {
        Me.unitTestExecuted = true
    }

    override func tearDown() {
        Me.unitTestTearDownCalled += 1
    }
}

extension Feature: Hashable {
    public static func == (lhs: Feature, rhs: Feature) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}

extension Step: Hashable {
    public static func == (lhs: Step, rhs: Step) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}

var recordedIssues = [XCTIssue]()

extension CucumberTest {
    @_dynamicReplacement(for: failStep)
    func replacementFailStep(_ issue: XCTIssue) {
        recordedIssues.append(issue)
    }
}

// Z prefix ensures this runs after XCTest has already executed the CucumberTest suite
class ZCucumberTestCacheTests: XCTestCase {
    func testDefaultTestSuiteReturnsEmptyOnSubsequentCalls() {
        // First call builds the full suite. Second call must return an empty suite
        // to prevent XCTest from running CucumberTest twice when discovered in both
        // the test bundle and framework, avoiding "Invalid attempt to start a test
        // run that has already been started".
        let firstSuite = CucumberTest.defaultTestSuite
        let secondSuite = CucumberTest.defaultTestSuite
        XCTAssertFalse(firstSuite === secondSuite)
        XCTAssertTrue(secondSuite.tests.isEmpty,
                      "Second call should return an empty suite")
    }
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class TestDiscovery: CucumberTest { }
        return Bundle(for: TestDiscovery.self)
    }

    public func setupSteps() {
        var beforeFeatureHooks = [Feature: Int]()
        BeforeFeature { feature in
            beforeFeatureHooks[feature, default: 0] += 1
        }
        var secondaryBeforeFeatureHooks = [Feature: Int]()
        BeforeFeature { feature in
            secondaryBeforeFeatureHooks[feature, default: 0] += 1
        }
        var beforeScenarioHooks = [Scenario: Int]()
        BeforeScenario { scenario in
            beforeScenarioHooks[scenario, default: 0] += 1
        }
        var beforeStepHooks = [Step: Int]()
        BeforeStep { step in
            beforeStepHooks[step, default: 0] += 1
        }
        var afterStepHooks = [Step: Int]()
        AfterStep { step in
            if afterStepHooks[step] != nil {
                XCTFail("Should not have the same after hook called")
            }
            afterStepHooks[step, default: 0] += 1
        }
        var afterScenarioHooks = [Scenario: Int]()
        AfterScenario { scenario in
            if afterScenarioHooks[scenario] != nil {
                XCTFail("Should not have the same after hook called")
            }
            afterScenarioHooks[scenario, default: 0] += 1
        }
        var afterFeatureHooks = [Feature: Int]()
        AfterFeature { feature in
            if afterFeatureHooks[feature] != nil {
                XCTFail("Should not have the same after hook called")
            }
            afterFeatureHooks[feature, default: 0] += 1
            XCTAssertEqual(recordedIssues.count, 13)
            guard recordedIssues.count == 13 else { return }
            XCTAssert(recordedIssues[0].description.contains(
                """
                Given(/^I have some steps that have not been implemented$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[1].description.contains(
                """
                Given(/^a DocString of some kind that is not implemented$/) { _, step in
                    let docString = step.docString
                }
                """))
            XCTAssert(recordedIssues[2].description.contains(
                """
                Given(/^I have some data table that is not implemented$/) { _, step in
                    let dataTable = step.dataTable
                }
                """))
            XCTAssert(recordedIssues[3].description.contains(
                """
                When(/^I look in my test report$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[4].description.contains(
                """
                When(/^I look in my test report$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[5].description.contains(
                """
                When(/^I look in my test report$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[6].description.contains(
                """
                Then(/^I see some PENDING steps with a swift attachment$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[7].description.contains(
                """
                Then(/^I can access the data table$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[8].description.contains(
                """
                Then(/^I see some PENDING steps with a swift attachment$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[9].description.contains(
                """
                Then(/^I see some PENDING steps with a swift attachment$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[10].description.contains(
                """
                Then(/^I can copy and paste the swift code into my test case$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[11].description.contains(
                """
                Then(/^I can copy and paste the swift code into my test case$/) { _, _ in

                }
                """))
            XCTAssert(recordedIssues[12].description.contains(
                """
                Then(/^I can copy and paste the swift code into my test case$/) { _, _ in

                }
                """))
        }
        Given("I have a before feature hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have a before scenario outline hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have a before scenario hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have a before step hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have an after step hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have an after scenario hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have an after feature hook") { _, _ in
            XCTAssert(true)
        }
        Given("I have a scenario defined") { _, _ in
            XCTAssert(true)
        }
        Given("I point my step to a unit test", class: Me.self, selector: #selector(Me.unitTestIsExecuted))
        Given("a step with a data table") { _, step in
            guard let dataTable = step.dataTable else {
                XCTFail("no data table found!"); return
            }
            XCTAssertEqual(dataTable.rows.count, 2)
            XCTAssertEqual(dataTable.rows[0][0], "foo")
            XCTAssertEqual(dataTable.rows[0][1], "bar")
            XCTAssertEqual(dataTable.rows[1][0], "boz")
            XCTAssertEqual(dataTable.rows[1][1], "boo")
        }

        When("I run the tests") { _, step in
            XCTAssert(true)
            XCTAssertNotNil(step.testCase)
        }

        Then("BeforeFeature gets called once per feature") { _, step in
            XCTAssertEqual(beforeFeatureHooks[step.scenario!.feature!], 1)
            XCTAssertEqual(secondaryBeforeFeatureHooks[step.scenario!.feature!], 1)
        }
        Then("BeforeScenario gets called once per scenario") { _, step in
            XCTAssertEqual(beforeScenarioHooks[step.scenario!], 1)
        }
        Then("BeforeScenario gets called once per scenario outline") { _, step in
            XCTAssertEqual(beforeScenarioHooks[step.scenario!], 1)
        }
        Then("BeforeStep gets called once per step") { _, step in
            XCTAssertEqual(beforeStepHooks[step], 1)
        }
        Then("AfterStep gets called once per step") { _, _ in
            XCTAssertFalse(afterStepHooks.keys.isEmpty)
        }
        Then("AfterScenario gets called once per scenario") { _, _ in
            // gotta test this after the scenario...
        }
        Then("AfterFeature gets called once per feature") { _, _ in
            // gotta test this after the feature...
        }
        Then("The scenario runs without crashing") { _, _ in
            let expectation = self.expectation(description: "waiting")
            expectation.fulfill()
            self.wait(for: [expectation], timeout: 3)
            XCTAssert(true)
        }
        Then("The unit test runs") { _, _ in
            XCTAssertEqual(Me.unitTestSetupCalled, 1)
            XCTAssert(Me.unitTestExecuted, "Unit test did not run")
            XCTAssertEqual(Me.unitTestTearDownCalled, 1)
        }
        And("The steps are slightly different") { _, _ in
            XCTAssert(true)
        }
    }
}
