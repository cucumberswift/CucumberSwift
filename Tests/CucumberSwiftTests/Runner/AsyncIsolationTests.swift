//
//  AsyncIsolationTests.swift
//  CucumberSwiftTests
//
//  Characterization tests for where step definitions, hooks and reporters run (#229, and the isolation
//  questions in #113). CucumberSwift runs every step on XCTest's main thread and, for an async step, on
//  the main actor. A closure passed as a step or hook picks up `@MainActor` from the parameter type, and
//  so does a function marked `@MainActor`. A plain `async` function keeps its own isolation and runs on
//  a background thread; CucumberSwift still waits for it, so the order is the same. Each case runs as
//  several steps and checks its thread before and after awaiting background work, so a form that ran
//  on the main thread only some of the time would fail.
//

import Foundation
import XCTest
import CucumberSwiftExpressions

@testable import CucumberSwift

private func isOnMainThread() -> Bool {
    Thread.isMainThread
}

/// Records the thread of each check a step makes, by case, and the order the steps ran in.
private final class ThreadLog {
    private(set) var checks = [String: [Bool]]()
    private(set) var order = [String]()

    func record(_ label: String, _ onMainThread: Bool) {
        checks[label, default: []].append(onMainThread)
    }

    func ran(_ label: String) {
        order.append(label)
    }

    /// Records where the caller is running. It is synchronous, so it runs on the caller's thread.
    func check(_ label: String) {
        record(label, isOnMainThread())
    }

    /// Checks again, after the step has awaited something, and records that the step ran.
    func finish(_ label: String) {
        check(label)
        ran(label)
    }
}

/// Work on a background thread for a step to await. A step body checks its thread itself, before and
/// after this: a check made inside a plain async function would report that function's thread instead.
private func backgroundWork() async {
    _ = await Task.detached { isOnMainThread() }.value
}

private let stepsPerCase = 3

/// A feature whose single scenario has `stepsPerCase` steps for each label, in the order given.
private func parseFeature(withStepsFor labels: [String]) {
    let steps = labels.flatMap { label in (1...stepsPerCase).map { "     Given \(label) step \($0)" } }
    Cucumber.shared.parseIntoFeatures("""
    Feature: Where steps run
       Scenario: Every kind of step definition
    \(steps.joined(separator: "\n"))
    """)
}

/// What the log should hold for `label` if each of its steps made `checksPerStep` checks, all on (or off)
/// the main thread.
private func expected(_ onMainThread: Bool, checksPerStep: Int = 2) -> [Bool] {
    Array(repeating: onMainThread, count: stepsPerCase * checksPerStep)
}

private func expectedOrder(_ labels: [String]) -> [String] {
    labels.flatMap { Array(repeating: $0, count: stepsPerCase) }
}

// Step definitions passed as functions rather than closures. Each is called with a label through `log`.
private var log = ThreadLog()

@MainActor
private func mainActorExpressionStep(_ match: CucumberSwiftExpressions.Match, _ step: Step) async throws {
    log.check("@MainActor function")
    await backgroundWork()
    log.finish("@MainActor function")
}

private func nonisolatedExpressionStep(_ match: CucumberSwiftExpressions.Match, _ step: Step) async throws {
    log.check("plain async function")
    await backgroundWork()
    log.finish("plain async function")
}

private func syncExpressionStep(_ match: CucumberSwiftExpressions.Match, _ step: Step) throws {
    log.record("sync function", isOnMainThread())
    log.ran("sync function")
}

@MainActor
private func mainActorHook(_ scenario: Scenario) async throws {
    log.check("@MainActor hook function")
    await backgroundWork()
    log.finish("@MainActor hook function")
}

private func nonisolatedHook(_ scenario: Scenario) async throws {
    log.check("plain async hook function")
    await backgroundWork()
    log.finish("plain async hook function")
}

class AsyncIsolationTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        log = ThreadLog()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        CustomReporterTests.mockObserver.reset()
        log = ThreadLog()
    }

    // MARK: Step definitions

    func testSyncStepDefinitionsRunOnTheMainThread() {
        let labels = ["a sync closure", "a sync function"]
        parseFeature(withStepsFor: labels)
        Given("a sync closure step {int}") { _, _ in
            log.record("sync closure", isOnMainThread())
            log.ran("a sync closure")
        }
        Given("a sync function step {int}", callback: syncExpressionStep)

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["sync closure"], expected(true, checksPerStep: 1))
        XCTAssertEqual(log.checks["sync function"], expected(true, checksPerStep: 1))
    }

    func testAsyncClosuresRunOnTheMainActorForEveryMatcherKind() throws {
        var labels = ["a Cucumber expression closure", "an anchored pattern closure"]
        #if compiler(>=5.7) && canImport(_StringProcessing)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) { labels.append("a Regex closure") }
        #endif
        parseFeature(withStepsFor: labels)

        Given("a Cucumber expression closure step {int}") { _, _ in
            log.check("a Cucumber expression closure")
            await backgroundWork()
            log.finish("a Cucumber expression closure")
        }
        Given("^an anchored pattern closure step (\\d+)$") { _, _ in
            log.check("an anchored pattern closure")
            await backgroundWork()
            log.finish("an anchored pattern closure")
        }
        #if compiler(>=5.7) && canImport(_StringProcessing)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            Given(try Regex("^a Regex closure step (\\d+)$")) { _, _ in
                log.check("a Regex closure")
                await backgroundWork()
                log.finish("a Regex closure")
            }
        }
        #endif

        Cucumber.shared.executeFeatures()

        for label in labels {
            XCTAssertEqual(log.checks[label], expected(true), label)
        }
        XCTAssertEqual(log.order, expectedOrder(labels))
    }

    @available(*, deprecated, message: "Exercises the deprecated regular expression String API")
    func testAsyncRegexStringClosuresRunOnTheMainActor() {
        parseFeature(withStepsFor: ["a regex string closure"])
        Given("^a regex string closure step (\\d+)$") { (_: [String], _) in
            log.check("a regex string closure")
            await backgroundWork()
            log.finish("a regex string closure")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["a regex string closure"], expected(true))
    }

    func testAMainActorFunctionRunsOnTheMainActorAndAPlainAsyncFunctionDoesNot() {
        let labels = ["a main actor function", "a plain async function"]
        parseFeature(withStepsFor: labels)
        Given("a main actor function step {int}", callback: mainActorExpressionStep)
        Given("a plain async function step {int}", callback: nonisolatedExpressionStep)

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["@MainActor function"], expected(true))
        XCTAssertEqual(log.checks["plain async function"], expected(false))
        // Off the main thread or not, each step still finished before the next one started.
        XCTAssertEqual(log.order, expectedOrder(["@MainActor function", "plain async function"]))
    }

    func testAClosureThatCallsAPlainAsyncHelperLeavesTheMainActorOnlyForTheHelper() {
        func plainAsyncHelper() async {
            log.check("inside the helper")
            await backgroundWork()
            log.check("inside the helper")
        }
        parseFeature(withStepsFor: ["a closure calling a helper"])
        Given("a closure calling a helper step {int}") { _, _ in
            log.check("the closure")
            await plainAsyncHelper()
            log.finish("the closure")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["the closure"], expected(true))
        XCTAssertEqual(log.checks["inside the helper"], expected(false))
    }

    // MARK: Hooks

    func testHooksRunOnTheMainActorExceptAPlainAsyncFunction() {
        parseFeature(withStepsFor: ["a hooked"])
        Given("a hooked step {int}") { _, _ in log.ran("step") }
        BeforeScenario { _ in
            log.record("sync hook closure", isOnMainThread())
        }
        BeforeScenario { _ in
            log.check("async hook closure")
            await backgroundWork()
            log.finish("async hook closure")
        }
        BeforeScenario(closure: mainActorHook)
        BeforeScenario(closure: nonisolatedHook)
        BeforeStep { _ in
            log.check("async BeforeStep closure")
            await backgroundWork()
            log.finish("async BeforeStep closure")
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["sync hook closure"], [true])
        XCTAssertEqual(log.checks["async hook closure"], [true, true])
        XCTAssertEqual(log.checks["@MainActor hook function"], [true, true])
        XCTAssertEqual(log.checks["plain async hook function"], [false, false])
        XCTAssertEqual(log.checks["async BeforeStep closure"], expected(true))
        // Each hook finished before the next began, and before the scenario's first step.
        XCTAssertEqual(Array(log.order.prefix(3)),
                       ["async hook closure", "@MainActor hook function", "plain async hook function"])
        XCTAssertEqual(log.order.filter { $0 == "step" }.count, stepsPerCase)
    }

    // MARK: DSL

    func testDSLStepsRunOnTheMainActorExceptAPlainAsyncFunction() {
        @MainActor func mainActorStep() async {
            log.check("DSL @MainActor function")
            await backgroundWork()
            log.finish("DSL @MainActor function")
        }
        func nonisolatedStep() async {
            log.check("DSL plain async function")
            await backgroundWork()
            log.finish("DSL plain async function")
        }
        func syncStep() {
            log.record("DSL sync call", isOnMainThread())
        }

        let scenario = Scenario("Every kind of DSL step") {
            Given(I: syncStep())
            Given(I: syncStep())
            Given(I: syncStep())
            When(I: mainActorStep)
            When(I: mainActorStep)
            When(I: mainActorStep)
            Then(I: nonisolatedStep)
            Then(I: nonisolatedStep)
            Then(I: nonisolatedStep)
            // swiftlint:disable trailing_closure
            And(the: { log.check("DSL closure"); await backgroundWork(); log.finish("DSL closure") })
            And(the: { log.check("DSL closure"); await backgroundWork(); log.finish("DSL closure") })
            And(the: { log.check("DSL closure"); await backgroundWork(); log.finish("DSL closure") })
            // swiftlint:enable trailing_closure
        }
        Feature("Where DSL steps run") {
            scenario
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["DSL sync call"], expected(true, checksPerStep: 1))
        XCTAssertEqual(log.checks["DSL @MainActor function"], expected(true))
        XCTAssertEqual(log.checks["DSL plain async function"], expected(false))
        XCTAssertEqual(log.checks["DSL closure"], expected(true))
        XCTAssertEqual(log.order, expectedOrder(["DSL @MainActor function", "DSL plain async function", "DSL closure"]))
    }

    // MARK: ExecuteFirstStep and reporters

    func testAwaitExecuteFirstStepKeepsTheIsolationOfTheStepItRuns() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Where steps run
           Scenario: A step that runs others
             Given a closure step
             And a plain async function step 1
             And a step that runs both
        """)
        Given("a closure step") { _, _ in
            log.check("closure run by ExecuteFirstStep")
            await backgroundWork()
            log.finish("closure run by ExecuteFirstStep")
        }
        Given("a plain async function step {int}", callback: nonisolatedExpressionStep)
        Given("a step that runs both") { _, _ in
            log = ThreadLog()
            await ExecuteFirstStep(matching: "a closure step")
            await ExecuteFirstStep(matching: "a plain async function step 1")
            log.record("the step that ran them", isOnMainThread())
        }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["closure run by ExecuteFirstStep"], [true, true])
        XCTAssertEqual(log.checks["plain async function"], [false, false])
        XCTAssertEqual(log.checks["the step that ran them"], [true])
    }

    func testReportersAreToldAboutAsyncStepsOnTheMainThread() {
        parseFeature(withStepsFor: ["a plain async function"])
        Given("a plain async function step {int}", callback: nonisolatedExpressionStep)
        CustomReporterTests.mockObserver.didStartStep = { _, _ in log.record("didStart", isOnMainThread()) }
        CustomReporterTests.mockObserver.didFinishStep = { _, _, _ in log.record("didFinish", isOnMainThread()) }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(log.checks["plain async function"], expected(false))
        XCTAssertEqual(log.checks["didStart"], expected(true, checksPerStep: 1))
        XCTAssertEqual(log.checks["didFinish"], expected(true, checksPerStep: 1))
    }
}
