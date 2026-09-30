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

    /// Only touched on the main thread: by the task, which runs on the main actor, and by `wait`, which
    /// runs there too and lets the body in only while `XCTWaiter` turns the run loop.
    private final class State {
        var error: Error?
        var done = false
        var poll: XCTestExpectation?
    }

    /// How long an async step or hook may take when `StepImplementation` does not set `asyncStepTimeout`.
    static let defaultTimeout: TimeInterval = 60

    static var timeout: TimeInterval {
        (Cucumber.shared as? StepImplementation)?.asyncStepTimeout ?? defaultTimeout
    }

    private static let pollInterval: TimeInterval = 0.05

    private static var isInsideTask: Bool {
        withUnsafeCurrentTask { $0 != nil }
    }

    /// Turns an async step body into the synchronous `Step.Execute` the runner calls.
    static func blockingStep(_ body: @escaping Step.AsyncExecute) -> Step.Execute {
        { match, step in try run { try await body(match, step) } }
    }

    /// Turns an async hook into the synchronous closure the hook storage holds. A thrown error fails the
    /// test at the hook.
    static func blockingHook<T>(_ hook: @escaping @MainActor (T) async throws -> Void,
                                file: StaticString,
                                line: UInt) -> (T) -> Void {
        { value in runFailingOnError({ try await hook(value) }, file: file, line: line) }
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
                     hasFailed: () -> Bool,
                     body: @escaping Body) -> Outcome {
        let state = State()
        let task = Task { @MainActor in
            defer {
                state.done = true
                state.poll?.fulfill()
            }
            do {
                try await body()
            } catch {
                state.error = error
            }
        }

        let deadline = Date().addingTimeInterval(timeout)
        var timedOut = false
        var cancelledOnFailure = false
        while !state.done {
            // An expectation can be waited on only once, so each short wait gets its own.
            let poll = XCTestExpectation(description: "async step finished")
            state.poll = poll
            _ = XCTWaiter().wait(for: [poll], timeout: pollInterval)
            guard !state.done, !task.isCancelled else { continue }
            if Date() >= deadline {
                timedOut = true
                task.cancel()
            } else if cancelOnFailure && hasFailed() {
                cancelledOnFailure = true
                task.cancel()
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
