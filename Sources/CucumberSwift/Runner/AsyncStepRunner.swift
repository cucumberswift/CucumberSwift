//
//  AsyncStepRunner.swift
//  CucumberSwift
//
//  Copyright © 2026 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

/// Runs the body of an async step or hook from the synchronous test method that XCTest calls.
///
/// Steps never run in parallel: the body starts on the main actor and the test method blocks until it
/// has finished, so the next step cannot start before this one ends. `XCTWaiter` keeps the main run
/// loop turning while it blocks, so main-actor work inside the body goes ahead.
///
/// The body runs inside that one wait, which ends only when the body does, when it runs past the
/// timeout, or when a failure cancels it. XCTest interrupts a wait nested inside another only when the
/// outer one times out, so the waits XCUI makes inside the body, such as an element query or a tap,
/// finish as they would in a synchronous step (#424).
enum AsyncStepRunner {
    typealias Body = @MainActor () async throws -> Void

    enum Outcome {
        case finished
        case threw(Error)
        case timedOut
    }

    struct TimeoutError: LocalizedError {
        let timeout: TimeInterval
        var errorDescription: String? {
            "The async step did not finish within \(timeout) seconds. Set `asyncStepTimeout` in your StepImplementation to allow longer."
        }
    }

    struct NestedWaitError: LocalizedError {
        var errorDescription: String? {
            "An async step was started synchronously from inside another async step or hook. Use `await ExecuteFirstStep(matching:)` there instead."
        }
    }

    /// Only touched on the main thread: by the task, which runs on the main actor, by the failure check,
    /// a timer on the main run loop, and by `wait`, which runs there too and lets the body in only while
    /// `XCTWaiter` turns the run loop.
    private final class State {
        var error: Error?
        var done = false
        /// What the current wait waits for. Fulfilled once, by whichever ends that wait first.
        var waitEnded: XCTestExpectation?

        func endWait() {
            waitEnded?.fulfill()
            waitEnded = nil
        }
    }

    /// How long an async step or hook may take when `StepImplementation` does not set `asyncStepTimeout`.
    static let defaultTimeout: TimeInterval = 60

    static var timeout: TimeInterval {
        (Cucumber.shared as? StepImplementation)?.asyncStepTimeout ?? defaultTimeout
    }

    /// How often a failure is looked for while the body runs.
    private static let failureCheckInterval: TimeInterval = 0.05

    /// How long the run loop turns at a time while a cancelled body finishes.
    private static let cancelledBodyPollInterval: TimeInterval = 0.05

    /// Whether a hook runs with no test running, as `AfterFeature` does at the end of a parallel worker.
    /// XCTest drops a failure recorded then, so a thrown error is printed instead.
    static var isOutsideTest = false

    private static var isInsideTask: Bool {
        withUnsafeCurrentTask { $0 != nil }
    }

    /// Turns an async step body into the synchronous `Step.Execute` the runner calls.
    static func blockingStep(_ body: @escaping Step.AsyncExecute) -> Step.Execute {
        { match, step in try run { try await body(match, step) } }
    }

    /// Turns an async hook into the synchronous closure the hook storage holds. A thrown error fails the
    /// test at the hook, or with no test running, is printed with the hook's file and line.
    static func blockingHook<T>(_ hook: @escaping @MainActor (T) async throws -> Void,
                                file: StaticString,
                                line: UInt) -> (T) -> Void {
        { value in
            guard isOutsideTest else {
                runFailingOnError({ try await hook(value) }, file: file, line: line)
                return
            }
            do {
                try run { try await hook(value) }
            } catch {
                print(outsideTestErrorMessage(error, for: value, file: file, line: line))
            }
        }
    }

    /// What is printed when a hook throws with no test running, such as an `AfterFeature` hook at the end of
    /// a parallel worker.
    static func outsideTestErrorMessage<T>(_ error: Error, for value: T, file: StaticString, line: UInt) -> String {
        let subject = (value as? Feature).map { " for the feature '\($0.title)'" } ?? ""
        return "CucumberSwift: the hook at \(file):\(line) threw\(subject) after this worker's last test, "
            + "so it can't fail a test: \(error.localizedDescription)"
    }

    /// Like `run`, but a thrown error fails the test at `file` and `line` instead of propagating.
    static func runFailingOnError(_ body: @escaping Body, file: StaticString, line: UInt) {
        XCTAssertNoThrow(try run(body), file: file, line: line)
    }

    /// Runs `body` to completion in the current step's test, and throws what it threw, or `TimeoutError`.
    static func run(_ body: @escaping Body) throws {
        // Blocking here from inside a task would stop the main actor from running the new body.
        guard !isInsideTask else { throw NestedWaitError() }

        let testCase = Cucumber.shared.currentStep?.testCase
        let continueAfterFailure = testCase?.continueAfterFailure ?? true
        let failuresBefore = testCase?.testRun?.totalFailureCount ?? 0
        // With `continueAfterFailure = false`, a failure inside the body would make XCTest cut the wait
        // short while the body carries on running, and it could then overlap the next step. So XCTest is
        // told to continue while the body runs, and the body is cancelled on failure instead.
        testCase?.continueAfterFailure = true
        defer { testCase?.continueAfterFailure = continueAfterFailure }

        let hasFailed = { (testCase?.testRun?.totalFailureCount ?? 0) > failuresBefore }
        let outcome = wait(timeout: timeout, cancelOnFailure: !continueAfterFailure, hasFailed: hasFailed, body: body)

        switch outcome {
            case .finished: return
            case .threw(let error): throw error
            case .timedOut: throw TimeoutError(timeout: timeout)
        }
    }

    /// Starts `body` on the main actor and returns only once it has finished. It is cancelled when it runs
    /// past `timeout`, or when `hasFailed` turns true and `cancelOnFailure` is set, and is still waited
    /// for after that: a body that ignores cancellation holds up the run rather than overlap the next step.
    static func wait(timeout: TimeInterval,
                     cancelOnFailure: Bool,
                     hasFailed: @escaping () -> Bool,
                     body: @escaping Body) -> Outcome {
        let state = State()
        let finished = XCTestExpectation(description: "async step finished")
        state.waitEnded = finished
        let task = Task { @MainActor in
            defer {
                state.done = true
                state.endWait()
            }
            do {
                try await body()
            } catch {
                state.error = error
            }
        }

        // One wait for the whole body, rather than a loop of short ones: a short wait that times out
        // would interrupt any wait the body makes, such as XCUI's (#424). A failure ends it early instead,
        // from a timer that the run loop fires while the body runs, so the body can be cancelled.
        var cancelledOnFailure = false
        let failureCheck = Timer(timeInterval: failureCheckInterval, repeats: true) { timer in
            guard !state.done, hasFailed() else { return }
            timer.invalidate()
            cancelledOnFailure = true
            state.endWait()
        }
        if cancelOnFailure {
            RunLoop.main.add(failureCheck, forMode: .common)
            // A failure recorded before the wait began cancels the body at once, not at the first check.
            if hasFailed() {
                failureCheck.invalidate()
                cancelledOnFailure = true
                state.endWait()
            }
        }
        let timedOut = XCTWaiter().wait(for: [finished], timeout: timeout) == .timedOut && !state.done
        failureCheck.invalidate()

        if !state.done {
            task.cancel()
            // The body is still waited for, but not with an `XCTWaiter`: one that timed out would interrupt
            // an XCUI wait the cancelled body is making, however long that wait lasts. Turning the run loop
            // lets the body go on, and nothing around it can time out. The timer keeps the run loop from
            // returning at once when nothing else is scheduled.
            let keepTurning = Timer(timeInterval: cancelledBodyPollInterval, repeats: true) { _ in
                // Empty on purpose: the timer only gives the run loop a source, so that it waits.
            }
            RunLoop.current.add(keepTurning, forMode: .default)
            defer { keepTurning.invalidate() }
            while !state.done {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: cancelledBodyPollInterval))
            }
        }

        if timedOut { return .timedOut }
        // The failure that cancelled the body is already recorded, so the cancellation it threw on the way
        // out is not news. Any other error is.
        if cancelledOnFailure, state.error == nil || state.error is CancellationError { return .finished }
        if let error = state.error { return .threw(error) }
        return .finished
    }
}
