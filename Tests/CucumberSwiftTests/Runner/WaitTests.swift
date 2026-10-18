import XCTest
@testable import CucumberSwift

/// `Cucumber.wait(for:timeout:)`, in both its forms, fails the step when the timeout passes or an inverted
/// expectation is fulfilled, so the scenario fails and its later steps don't run (#442). In an async step the
/// form written with `await` doesn't hold the main actor, so work on it or on the main queue can fulfill the
/// expectation.
class WaitTests: XCTestCase {
    private static let timedOutMessage = #"Asynchronous wait failed: Exceeded timeout of 0.1 seconds, with unfulfilled expectations: "never", "nor this"."#
    private static let invertedMessage = #"Fulfilled inverted expectation "inverted"."#

    private var capturing = false
    private var recordedIssues = [XCTIssue]()
    private var ranTheNextStep = false
    /// How many issues the step had recorded when its wait returned: the wait must fail the step there, not later.
    private var issuesWhenTheWaitReturned: Int?

    private static func resetCucumber() {
        Cucumber.shared.reset()
        Cucumber.shared.failedScenarios.removeAll()
        StepTestCase.skippedScenarios.removeAll()
    }

    private static func unfulfilledExpectations() -> [XCTestExpectation] {
        [Cucumber.shared.expectation(description: "never"), Cucumber.shared.expectation(description: "nor this")]
    }

    private static func invertedExpectation() -> XCTestExpectation {
        let expectation = Cucumber.shared.expectation(description: "inverted")
        expectation.isInverted = true
        expectation.fulfill()
        return expectation
    }

    private static func expectationMainQueueWorkFulfills() -> XCTestExpectation {
        let expectation = Cucumber.shared.expectation(description: "main queue")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        return expectation
    }

    private static func expectationAMainActorTaskFulfills() -> XCTestExpectation {
        let expectation = Cucumber.shared.expectation(description: "main actor")
        Task { @MainActor in expectation.fulfill() }
        return expectation
    }

    override func setUpWithError() throws {
        Self.resetCucumber()
        addTeardownBlock { Self.resetCucumber() }
    }

    // While the scenario runs, keep the failures its steps record, and tell CucumberSwift about them as
    // XCTest would, so that a failed scenario skips its remaining steps. Other failures fail this test.
    override func record(_ issue: XCTIssue) {
        guard capturing else { return super.record(issue) }
        recordedIssues.append(issue)
        Cucumber.shared.testCase(self,
                                 didFailWithDescription: issue.compactDescription,
                                 inFile: issue.sourceCodeContext.location?.fileURL.path,
                                 atLine: issue.sourceCodeContext.location?.lineNumber ?? 0)
    }

    /// Runs a scenario whose first step is the wait that `defineTheWait` defines, as its scenario test would.
    private func runTheScenario(_ defineTheWait: () -> Void) throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Waiting
           Scenario: Wait
             Given a wait
             Then the next step
        """)
        defineTheWait()
        Then("the next step") { _, _ in self.ranTheNextStep = true }
        let scenario = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first)
        capturing = true
        defer { capturing = false }
        _ = CucumberTest.run(scenario, on: self)
    }

    private func noteTheIssuesWhenTheWaitReturns() {
        issuesWhenTheWaitReturned = recordedIssues.count
    }

    private func assertTheStepFailed(with message: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(issuesWhenTheWaitReturned, 1, "The wait didn't fail the step before it returned", file: file, line: line)
        XCTAssertEqual(recordedIssues.map(\.compactDescription), [message], file: file, line: line)
        XCTAssertFalse(ranTheNextStep, "The step after the failed wait ran", file: file, line: line)
    }

    private func assertTheStepPassed(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(recordedIssues.map(\.compactDescription), [], file: file, line: line)
        XCTAssertTrue(ranTheNextStep, "The step after the wait didn't run", file: file, line: line)
    }

    func testAWaitThatTimesOutFailsTheStep() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                Cucumber.shared.wait(for: Self.unfulfilledExpectations(), timeout: 0.1)
                self.noteTheIssuesWhenTheWaitReturns()
            }
        }
        assertTheStepFailed(with: Self.timedOutMessage)
    }

    func testAWaitForAFulfilledInvertedExpectationFailsTheStep() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                Cucumber.shared.wait(for: [Self.invertedExpectation()], timeout: 0.1)
                self.noteTheIssuesWhenTheWaitReturns()
            }
        }
        assertTheStepFailed(with: Self.invertedMessage)
    }

    func testAWaitThatMainQueueWorkFulfillsPasses() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                let expectation = Self.expectationMainQueueWorkFulfills()
                Cucumber.shared.wait(for: [expectation], timeout: 5)
            }
        }
        assertTheStepPassed()
    }

    func testAnAwaitedWaitThatTimesOutFailsTheStep() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                await Cucumber.shared.wait(for: Self.unfulfilledExpectations(), timeout: 0.1)
                self.noteTheIssuesWhenTheWaitReturns()
            }
        }
        assertTheStepFailed(with: Self.timedOutMessage)
    }

    func testAnAwaitedWaitForAFulfilledInvertedExpectationFailsTheStep() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                await Cucumber.shared.wait(for: [Self.invertedExpectation()], timeout: 0.1)
                self.noteTheIssuesWhenTheWaitReturns()
            }
        }
        assertTheStepFailed(with: Self.invertedMessage)
    }

    func testAnAwaitedWaitLetsMainQueueWorkFulfillTheExpectation() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                let expectation = Self.expectationMainQueueWorkFulfills()
                await Cucumber.shared.wait(for: [expectation], timeout: 5)
            }
        }
        assertTheStepPassed()
    }

    func testAnAwaitedWaitLetsAMainActorTaskFulfillTheExpectation() throws {
        try runTheScenario {
            Given("a wait") { _, _ in
                let expectation = Self.expectationAMainActorTaskFulfills()
                await Cucumber.shared.wait(for: [expectation], timeout: 5)
            }
        }
        assertTheStepPassed()
    }
}
