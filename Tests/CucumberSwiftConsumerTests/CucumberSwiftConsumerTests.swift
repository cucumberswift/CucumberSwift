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

private let unimplementedStub = """
Given(#/^I have some steps that have not been implemented$/#) { _, _ in
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let lookInTheReportStub = """
When(#/^I look in my test report$/#) { _, _ in
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let seePendingStepsStub = """
Then(#/^I see some PENDING steps with a swift attachment$/#) { _, _ in
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let copyAndPasteStub = """
Then(#/^I can copy and paste the swift code into my test case$/#) { _, _ in
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let accessTheDataTableStub = """
Then(#/^I can access the data table$/#) { _, _ in
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let docStringStub = """
Given(#/^a DocString of some kind that is not implemented$/#) { _, step in
    let docString = step.docString
    XCTFail("Step not implemented: replace this line with your test code")
}
"""
private let dataTableStub = """
Given(#/^I have some data table that is not implemented$/#) { _, step in
    let dataTable = step.dataTable
    XCTFail("Step not implemented: replace this line with your test code")
}
"""

/// The step definitions CucumberSwift generates for the steps in CucumberSwift.feature that have none,
/// in the order the steps are in the file.
private let unimplementedStepDefinitions = [
    unimplementedStub,
    lookInTheReportStub,
    seePendingStepsStub,
    copyAndPasteStub,
    accessTheDataTableStub,
    docStringStub,
    lookInTheReportStub,
    seePendingStepsStub,
    copyAndPasteStub,
    dataTableStub,
    lookInTheReportStub,
    seePendingStepsStub,
    copyAndPasteStub
]

extension CucumberTest {
    @_dynamicReplacement(for: failStep)
    func replacementFailStep(_ issue: XCTIssue) {
        recordedIssues.append(issue)
    }
}

// The superclass of the generated step tests is an Objective-C class in its own SwiftPM target, which
// CucumberSwift finds by name. A consumer's test bundle must still contain it, or every step would run
// on a plain XCTestCase: named with "()", and with its failures at the Swift line, not the feature file.
class CucumberStepTestLinkTests: XCTestCase {
    func testTheObjectiveCStepTestIsLinkedIntoTheConsumer() {
        XCTAssertNotNil(NSClassFromString("CucumberStepTest"))
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
        // SwiftPM copies the Features folder into a separate resource bundle,
        // not into the test bundle as Xcode does.
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        class TestDiscovery: CucumberTest { }
        return Bundle(for: TestDiscovery.self)
        #endif
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
            // Each step with no step definition fails in its own test, in the order the steps run (#262).
            let issues = recordedIssues.filter { $0.sourceCodeContext.location?.fileURL.lastPathComponent == URL(string: feature.uri)?.lastPathComponent }
            let expected = feature.uri.hasSuffix("/CucumberSwift.feature") ? unimplementedStepDefinitions : []
            XCTAssertEqual(issues.count, expected.count)
            zip(issues, expected).forEach { XCTAssert($0.description.contains($1), $0.description) }
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

        // Regression coverage for https://github.com/cucumberswift/CucumberSwift/issues/115:
        // two steps with identical literal text but different side-channel data (a DataTable or
        // DocString) must each run with their own data, not silently alias to the first.
        var repeatedDataTableRows = [[DataTable.Row]]()
        Given("a step with a repeated data table") { _, step in
            repeatedDataTableRows.append(step.dataTable?.rows ?? [])
        }
        Then("each repeated data table step saw its own table") { _, _ in
            XCTAssertEqual(repeatedDataTableRows, [[["value"], ["one"]], [["value"], ["two"]]])
        }

        var repeatedDocStrings = [String]()
        Given("a step with a repeated doc string") { _, step in
            repeatedDocStrings.append(step.docString?.literal ?? "")
        }
        Then("each repeated doc string step saw its own doc string") { _, _ in
            XCTAssertEqual(repeatedDocStrings, ["first", "second"])
        }

        setupAsyncSteps()
    }

    // Async steps and hooks (#229): each step waits for the one before it, on the main actor.
    private func setupAsyncSteps() {
        var executionOrder = [String]()
        var asyncStepsOnMainThread = [Bool]()
        func isOnMainThread() -> Bool { Thread.isMainThread }

        BeforeScenario { scenario in
            guard scenario.feature?.title == "Async steps" else { return }
            await Task.yield()
            executionOrder.append("async BeforeScenario")
        }
        Given("an async step that waits") { _, _ in
            try await Task.sleep(nanoseconds: 100_000_000)
            asyncStepsOnMainThread.append(isOnMainThread())
            executionOrder.append("async wait")
        }
        Given("a sync step") { _, _ in
            executionOrder.append("sync")
        }
        When("an async step awaits work on a background thread") { _, _ in
            let answer = await Task.detached { isOnMainThread() ? 0 : 42 }.value
            asyncStepsOnMainThread.append(isOnMainThread())
            executionOrder.append("background \(answer)")
        }
        Then("every async step ran on the main thread") { _, _ in
            XCTAssertEqual(asyncStepsOnMainThread, [true, true])
        }
        Then("the steps and the async hook ran in the order written") { _, _ in
            XCTAssertEqual(executionOrder, ["async BeforeScenario", "async wait", "sync", "background 42"])
        }
    }
}
