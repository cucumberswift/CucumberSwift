//
//  StepTimeout.swift
//  CucumberSwiftTesting
//
// `asyncStepTimeout` and `continueTestingAfterFailure`, as CucumberSwift applies them to the steps and hooks
// it runs: a step or hook that outlasts the timeout fails, and with `continueTestingAfterFailure` off an async
// step's task is cancelled at its first failed expectation. Either way the body is waited for, so a body that
// ignores cancellation holds up the run rather than overlap the next step.

import Foundation

struct StepTimeoutError: LocalizedError {
    let timeout: TimeInterval

    var errorDescription: String? {
        "The async step did not finish within \(timeout) seconds. Set `asyncStepTimeout` in your StepImplementation to allow longer."
    }
}

extension Cucumber {
    // Not named like the protocol's requirements: a conformance in a module that sees these would take them
    // as its witnesses, and answer with itself.
    var stepTimeout: TimeInterval {
        (self as Any as? StepImplementation)?.asyncStepTimeout ?? 60
    }

    var continuesTestingAfterFailure: Bool {
        (self as Any as? StepImplementation)?.continueTestingAfterFailure ?? true
    }

    var reversesAfterHooks: Bool {
        (self as Any as? StepImplementation)?.reverseOrderForAfterHooks ?? false
    }

    /// Runs a step's or a hook's body, and throws what it threw, or ``StepTimeoutError`` when it runs past
    /// `asyncStepTimeout`. When `continueTestingAfterFailure` is off, an issue added to `record` while it
    /// runs cancels the body's task, and the cancellation it throws on the way out is not reported.
    func runWithTimeout(record: IssueRecord?, _ body: @escaping @MainActor () async throws -> Void) async throws {
        let timeout = stepTimeout
        // A body that blocks the main actor can't be interrupted, and the timeout fires while it runs. It has
        // finished by the time this resumes, and is not failed: CucumberSwift's timeout covers only a step or
        // a hook that suspends, as the async ones do.
        let finished = FinishedFlag()
        let task = Task { @MainActor in
            defer { finished.value = true }
            return try await body()
        }
        let cancelsOnIssue = !continuesTestingAfterFailure
        if cancelsOnIssue { record?.onIssue = { task.cancel() } }
        defer { if cancelsOnIssue { record?.onIssue = nil } }

        let timedOut = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                _ = await task.result
                return false
            }
            group.addTask {
                // Longer than any test can run, rather than overflow, for a timeout that isn't finite.
                let nanoseconds = timeout.isFinite ? UInt64(max(timeout, 0) * 1_000_000_000) : UInt64.max
                try? await Task.sleep(nanoseconds: nanoseconds)
                return true
            }
            let first = await group.next() ?? false
            // Asked before the body is cancelled, which makes it finish too.
            if first, await finished.value {
                group.cancelAll()
                return false
            }
            // Before the group ends, which waits for the body: a body that is cancelled in time stops sooner.
            if first { task.cancel() }
            group.cancelAll()
            return first
        }
        if timedOut { throw StepTimeoutError(timeout: timeout) }
        do {
            try await task.value
        } catch is CancellationError where cancelsOnIssue && !(record?.messages.isEmpty ?? true) {
            // The issue that cancelled the body is already recorded, so the cancellation is not news.
        }
    }
}

/// Whether a step's or a hook's body has returned. Only touched on the main actor.
@MainActor
private final class FinishedFlag {
    var value = false
}
