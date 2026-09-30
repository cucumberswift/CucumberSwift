//
//  AsyncStepTests.swift
//  CucumberSwiftTests
//
//  Copyright © 2026 Tyler Thompson. All rights reserved.
//
// swiftlint:disable type_body_length file_length function_body_length

import Foundation
import XCTest
import CucumberSwiftExpressions

@testable import CucumberSwift

/// A closure bound to an async overload runs inside a task; one bound to a sync overload does not.
private func isInsideTask() -> Bool {
    withUnsafeCurrentTask { $0 != nil }
}

private func isOnMainThread() -> Bool {
    Thread.isMainThread
}

private struct StepError: Error { }

class AsyncStepTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        Cucumber.overrideAsyncStepTimeout = nil
        Cucumber.shared.currentStep = nil
    }

    // MARK: Ordering

    func testMixedSyncAndAsyncStepsRunOneAtATimeInDeclaredOrder() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given a sync step
             When a slow async step
             And a fast async step
             Then another sync step
             And a final async step
        """)

        var executionOrder = [String]()
        var running = 0
        func enter(_ name: String) {
            XCTAssertEqual(running, 0, "\(name) started while another step was still running")
            running += 1
            executionOrder.append("start \(name)")
        }
        func leave(_ name: String) {
            running -= 1
            executionOrder.append("end \(name)")
        }

        Given("a sync step") { _, _ in
            enter("sync")
            leave("sync")
        }
        When("a slow async step") { _, _ in
            enter("slow")
            try await Task.sleep(nanoseconds: 200_000_000)
            await Task.yield()
            leave("slow")
        }
        And("a fast async step") { _, _ in
            enter("fast")
            await Task.yield()
            leave("fast")
        }
        Then("another sync step") { _, _ in
            enter("another sync")
            leave("another sync")
        }
        And("a final async step") { _, _ in
            enter("final")
            try await Task.sleep(nanoseconds: 50_000_000)
            leave("final")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "start sync", "end sync",
            "start slow", "end slow",
            "start fast", "end fast",
            "start another sync", "end another sync",
            "start final", "end final"
        ])
    }

    func testAsyncHooksRunInTheSameOrderAsSyncHooks() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             Then some testable result is achieved
        """)

        var executionOrder = [String]()
        BeforeFeature { _ in
            await Task.yield()
            executionOrder.append("BeforeFeature")
        }
        BeforeScenario { _ in
            executionOrder.append("BeforeScenario")
        }
        BeforeStep { step in
            try await Task.sleep(nanoseconds: 50_000_000)
            executionOrder.append("BeforeStep \(step.match)")
        }
        AfterStep { step in
            executionOrder.append("AfterStep \(step.match)")
        }
        AfterScenario { _ in
            await Task.yield()
            executionOrder.append("AfterScenario")
        }
        AfterFeature { _ in
            try await Task.sleep(nanoseconds: 50_000_000)
            executionOrder.append("AfterFeature")
        }

        Given("some precondition") { _, _ in
            await Task.yield()
            executionOrder.append("Given")
        }
        Then("some testable result is achieved") { _, _ in
            executionOrder.append("Then")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, [
            "BeforeFeature",
            "BeforeScenario",
            "BeforeStep some precondition",
            "Given",
            "AfterStep some precondition",
            "BeforeStep some testable result is achieved",
            "Then",
            "AfterStep some testable result is achieved",
            "AfterScenario",
            "AfterFeature"
        ])
    }

    func testAsyncHooksKeepTheirPriority() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)

        var executionOrder = [String]()
        BeforeScenario(priority: 2) { _ in
            await Task.yield()
            executionOrder.append("async priority 2")
        }
        BeforeScenario(priority: 1) { _ in
            executionOrder.append("sync priority 1")
        }
        BeforeScenario { _ in
            await Task.yield()
            executionOrder.append("async no priority")
        }
        Given("some precondition") { _, _ in
            // The test is about the hooks around this step.
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["sync priority 1", "async priority 2", "async no priority"])
    }

    // MARK: Main actor

    func testAsyncStepRunsOnTheMainThreadAndResumesAfterBackgroundWork() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)

        var onMainBefore = false
        var onMainAfter = false
        var backgroundResult: Int?
        Given("some precondition") { _, _ in
            onMainBefore = isOnMainThread()
            backgroundResult = await Task.detached { () -> Int in
                XCTAssertFalse(isOnMainThread())
                return 42
            }.value
            onMainAfter = isOnMainThread()
        }

        Cucumber.shared.executeFeatures()

        XCTAssert(onMainBefore)
        XCTAssert(onMainAfter)
        XCTAssertEqual(backgroundResult, 42)
    }

    // MARK: ExecuteFirstStep

    func testAwaitExecuteFirstStepRunsAsyncAndSyncStepsFromAnAsyncStep() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some text
           Scenario: Some determinable business situation
             Given an async precondition
               And a sync precondition
               And a step that reuses both
        """)

        var executionOrder = [String]()
        Given("an async precondition") { _, _ in
            await Task.yield()
            executionOrder.append("async")
        }
        Given("a sync precondition") { _, _ in
            executionOrder.append("sync")
        }
        Given("a step that reuses both") { _, _ in
            await ExecuteFirstStep(matching: "an async precondition")
            await ExecuteFirstStep(keyword: .given, matching: "a sync precondition")
            executionOrder.append("reuse")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["async", "sync", "async", "sync", "reuse"])
    }

    func testSyncExecuteFirstStepWaitsForAnAsyncStep() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some text
           Scenario: Some determinable business situation
             Given an async precondition
               And a sync step that reuses it
        """)

        var executionOrder = [String]()
        Given("an async precondition") { _, _ in
            try await Task.sleep(nanoseconds: 50_000_000)
            executionOrder.append("async")
        }
        Given("a sync step that reuses it") { _, _ in
            ExecuteFirstStep(matching: "an async precondition")
            executionOrder.append("sync")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["async", "async", "sync"])
    }

    // MARK: Failure, errors and timeout

    func testAFailureDuringAnAsyncStepSkipsTheRestOfTheScenario() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given a failing async step
             When some action is performed
             Then some testable result is achieved
        """)

        var executionOrder = [String]()
        Given("a failing async step") { _, _ in
            await Task.yield()
            // What XCTest tells CucumberSwift when an assertion fails in this step.
            Cucumber.shared.testCase(XCTestCase(), didFailWithDescription: "failed on purpose", inFile: nil, atLine: 0)
            await Task.yield()
            executionOrder.append("Given")
        }
        When("some action is performed") { _, _ in
            await Task.yield()
            executionOrder.append("When")
        }
        Then("some testable result is achieved") { _, _ in
            executionOrder.append("Then")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["Given"])
        let steps = Cucumber.shared.features.first?.scenarios.first?.steps ?? []
        XCTAssertEqual(steps.first?.result, .failed("failed on purpose"))
        XCTAssert(Cucumber.shared.failedScenarios.contains { $0 === steps.first?.scenario })
    }

    func testAnErrorThrownByAnAsyncBodyIsReturned() {
        let outcome = AsyncStepRunner.wait(timeout: 5, cancelOnFailure: true, hasFailed: { false }, body: {
            await Task.yield()
            throw StepError()
        })

        guard case .threw(let error) = outcome else { return XCTFail("Expected an error, got \(outcome)") }
        XCTAssert(error is StepError)
    }

    func testRunRethrowsWhatTheAsyncBodyThrew() {
        XCTAssertThrowsError(try AsyncStepRunner.run {
            await Task.yield()
            throw StepError()
        }) { error in
            XCTAssert(error is StepError)
        }
    }

    func testAFailureCancelsTheAsyncBodyAndWaitsForItToFinish() {
        var sawCancellation = false
        var finished = false
        let outcome = AsyncStepRunner.wait(timeout: 5, cancelOnFailure: true, hasFailed: { true }, body: {
            defer { finished = true }
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                sawCancellation = error is CancellationError
                // Still running after the cancellation: the next step must not start yet.
                await Task.yield()
                throw error
            }
        })

        XCTAssert(sawCancellation)
        XCTAssert(finished)
        // The failure that caused the cancellation is already recorded, so nothing more is reported.
        guard case .finished = outcome else { return XCTFail("Expected .finished, got \(outcome)") }
    }

    func testAnErrorOtherThanCancellationIsStillReturnedAfterAFailureCancelsTheBody() {
        let outcome = AsyncStepRunner.wait(timeout: 5, cancelOnFailure: true, hasFailed: { true }, body: {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                throw StepError()
            }
        })

        guard case .threw(let error) = outcome else { return XCTFail("Expected an error, got \(outcome)") }
        XCTAssert(error is StepError)
    }

    func testAFailureDoesNotCancelTheBodyWhenTestingContinuesAfterFailure() {
        var completed = false
        let outcome = AsyncStepRunner.wait(timeout: 5, cancelOnFailure: false, hasFailed: { true }, body: {
            try await Task.sleep(nanoseconds: 100_000_000)
            completed = true
        })

        XCTAssert(completed)
        guard case .finished = outcome else { return XCTFail("Expected .finished, got \(outcome)") }
    }

    func testAnAsyncBodyThatRunsPastTheTimeoutIsCancelledAndWaitedFor() {
        var finished = false
        let start = Date()
        let outcome = AsyncStepRunner.wait(timeout: 0.2, cancelOnFailure: true, hasFailed: { false }, body: {
            defer { finished = true }
            try await Task.sleep(nanoseconds: 10_000_000_000)
        })

        XCTAssert(finished)
        XCTAssertLessThan(Date().timeIntervalSince(start), 5)
        guard case .timedOut = outcome else { return XCTFail("Expected .timedOut, got \(outcome)") }
    }

    func testRunThrowsATimeoutErrorAfterTheConfiguredTimeout() {
        Cucumber.overrideAsyncStepTimeout = 0.2
        XCTAssertEqual(AsyncStepRunner.timeout, 0.2)

        XCTAssertThrowsError(try AsyncStepRunner.run {
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }) { error in
            XCTAssertEqual((error as? AsyncStepRunner.TimeoutError)?.timeout, 0.2)
        }
    }

    func testTheDefaultTimeoutIsGenerous() {
        Cucumber.overrideAsyncStepTimeout = nil
        XCTAssertEqual(AsyncStepRunner.timeout, 60)
    }

    /// With `continueAfterFailure = false`, CucumberSwift's default, a failure inside the body would make
    /// XCTest stop the test method while the body carried on running, so it could overlap the next step.
    func testXCTestIsToldToContinueWhileTheBodyRunsAndTheSettingIsRestoredAfter() throws {
        let step = Step(with: AST.StepNode())
        let testCase = XCTestCase()
        testCase.continueAfterFailure = false
        step.testCase = testCase
        Cucumber.shared.currentStep = step

        var duringBody: Bool?
        try AsyncStepRunner.run {
            await Task.yield()
            duringBody = testCase.continueAfterFailure
        }

        XCTAssertEqual(duringBody, true)
        XCTAssertFalse(testCase.continueAfterFailure)
    }

    func testStartingAnAsyncStepSynchronouslyFromInsideATaskThrows() {
        let done = expectation(description: "task finished")
        var caught: Error?
        Task { @MainActor in
            defer { done.fulfill() }
            do {
                try AsyncStepRunner.run { /* Never runs: starting it from inside a task throws. */ }
            } catch {
                caught = error
            }
        }
        wait(for: [done], timeout: 5)

        XCTAssert(caught is AsyncStepRunner.NestedWaitError)
    }

    // MARK: Ambiguous steps

    func testAnAsyncStepDefinitionCountsTowardAmbiguity() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)
        let firstLine = #line + 1
        Given("some precondition") { _, _ in await Task.yield() }
        let secondLine = #line + 1
        MatchAll("some precondition") { _, _ in
            // Only here to make the step ambiguous.
        }

        let step = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first?.steps.first)
        XCTAssertTrue(step.isAmbiguous)
        XCTAssertEqual(step.matchingDefinitions.map(\.line), [firstLine, secondLine])
    }

    func testAnAmbiguousStepWithAnAsyncDefinitionRunsNeither() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)
        var calls = 0
        Given("some precondition") { _, _ in calls += 1 }
        MatchAll("some precondition") { _, _ in
            await Task.yield()
            calls += 1
        }

        // The feature's tests are not run by XCTest here, so the failure lands on this test.
        XCTExpectFailure("The step is ambiguous") {
            Cucumber.shared.executeFeatures()
        }

        XCTAssertEqual(calls, 0)
        XCTAssertEqual(Cucumber.shared.features.first?.scenarios.first?.steps.first?.result, .ambiguous)
    }

    @MainActor
    func testAwaitExecuteFirstStepFailsOnAnAmbiguousStepAndRunsNothing() async throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)
        var calls = 0
        Given("some precondition") { _, _ in
            await Task.yield()
            calls += 1
        }
        MatchAll("some precondition") { _, _ in calls += 1 }

        XCTExpectFailure("The step is ambiguous")
        await ExecuteFirstStep(matching: "some precondition")

        XCTAssertEqual(calls, 0)
    }

    func testAnAsyncCucumberExpressionDefinitionCanDuplicateASyncOne() {
        Given("there are {int} flights") { _, _ in }
        let secondLine = #line + 1
        Given("there are {int} flights") { _, _ in await Task.yield() }

        XCTAssertEqual(DuplicateStepDefinition.errors.map(\.line), [secondLine])
    }

    @available(*, deprecated, message: "Exercises the deprecated regular expression String API")
    func testAnAsyncRegexStringDefinitionCanDuplicateASyncOne() {
        Given("^there are (\\d+) flights$") { (_: [String], _) in }
        let secondLine = #line + 1
        Given("^there are (\\d+) flights$") { (_: [String], _) in await Task.yield() }

        XCTAssertEqual(DuplicateStepDefinition.errors.map(\.line), [secondLine])
    }

    // MARK: Overload selection

    func testCucumberExpressionClosuresBindToTheMatchingOverload() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I have 5 cukes
             When I eat 2 cukes
        """)

        var syncInTask: Bool?
        var asyncInTask: Bool?
        var eaten: Int?
        Given("I have {int} cukes") { _, _ in
            syncInTask = isInsideTask()
        }
        When("I eat {int} cukes") { match, _ in
            await Task.yield()
            asyncInTask = isInsideTask()
            eaten = try match.first(\.int)
        }

        Cucumber.shared.executeFeatures()

        // `{int}` would not compile as a regular expression, so running at all shows the Cucumber
        // expression overloads were chosen.
        XCTAssertEqual(syncInTask, false)
        XCTAssertEqual(asyncInTask, true)
        XCTAssertEqual(eaten, 2)
    }

    func testAnchoredStringPatternsBindToTheCucumberExpressionOverloads() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given the app is at the Main Menu
             When the user opens Settings
        """)

        var syncMatch: Any?
        var asyncMatch: Any?
        Given("^the app is at the (\\w+) Menu$") { match, _ in
            syncMatch = match
        }
        When("^the user opens (\\w+)$") { match, _ in
            await Task.yield()
            asyncMatch = match
        }

        Cucumber.shared.executeFeatures()

        XCTAssert(syncMatch is CucumberSwiftExpressions.Match)
        XCTAssert(asyncMatch is CucumberSwiftExpressions.Match)
    }

    @available(*, deprecated, message: "Exercises the deprecated regular expression String API")
    func testRegexStringClosuresBindToTheMatchingOverload() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given the app is at the Main Menu
             When the user opens Settings
        """)

        var syncInTask: Bool?
        var syncCapture: String?
        var asyncInTask: Bool?
        var asyncCapture: String?
        Given("^the app is at the (\\w+) Menu$") { (matches: [String], _) in
            syncInTask = isInsideTask()
            syncCapture = matches.last
        }
        When("^the user opens (\\w+)$") { (matches: [String], _) in
            await Task.yield()
            asyncInTask = isInsideTask()
            asyncCapture = matches.last
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(syncInTask, false)
        XCTAssertEqual(syncCapture, "Main")
        XCTAssertEqual(asyncInTask, true)
        XCTAssertEqual(asyncCapture, "Settings")
    }

    #if compiler(>=5.7) && canImport(_StringProcessing)
    func testRegexClosuresBindToTheMatchingOverload() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) else { throw XCTSkip("Regex needs iOS 16, macOS 13 or tvOS 16") }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given the app is at the Main Menu
             When the user opens Settings
        """)

        var syncInTask: Bool?
        var asyncInTask: Bool?
        var asyncCapture: Substring?
        Given(try Regex("^the app is at the (\\w+) Menu$")) { _, _ in
            syncInTask = isInsideTask()
        }
        When(try Regex("^the user opens (\\w+)$")) { match, _ in
            await Task.yield()
            asyncInTask = isInsideTask()
            asyncCapture = match.output[1].substring
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(syncInTask, false)
        XCTAssertEqual(asyncInTask, true)
        XCTAssertEqual(asyncCapture, "Settings")
    }
    #endif

    func testHookClosuresBindToTheMatchingOverload() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
        """)

        var syncInTask: Bool?
        var asyncInTask: Bool?
        BeforeScenario { _ in
            syncInTask = isInsideTask()
        }
        AfterScenario { _ in
            await Task.yield()
            asyncInTask = isInsideTask()
        }
        Given("some precondition") { _, _ in
            // The test is about the hooks around this step.
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(syncInTask, false)
        XCTAssertEqual(asyncInTask, true)
    }

    func testDSLStepsBindToTheMatchingOverload() {
        var executionOrder = [String]()
        func syncStep() {
            executionOrder.append("sync \(isInsideTask())")
        }
        func asyncStep() async {
            await Task.yield()
            executionOrder.append("async \(isInsideTask())")
        }

        let scenario = Scenario("Some determinable business situation") {
            Given(I: syncStep())
            When(I: asyncStep)
            // swiftlint:disable:next trailing_closure
            Then(the: {
                try await Task.sleep(nanoseconds: 50_000_000)
                executionOrder.append("closure \(isInsideTask())")
            })
        }
        Feature("Some terse yet descriptive text of what is desired") {
            scenario
        }

        let steps = Cucumber.shared.features.first?.scenarios.first?.steps ?? []
        XCTAssertEqual(steps.prefix(2).map(\.match), ["I: syncStep()", "I: asyncStep"])

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(executionOrder, ["sync false", "async true", "closure true"])
    }
}
