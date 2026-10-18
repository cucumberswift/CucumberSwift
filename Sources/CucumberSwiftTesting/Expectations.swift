//
//  Expectations.swift
//  CucumberSwiftTesting
//
// CucumberSwift's `expectation(description:)` and `wait(for:timeout:)`, with the same signatures, so that a
// step definition that waits on an `XCTestExpectation` compiles unchanged with this runner.

#if canImport(XCTest)
import Foundation
import Testing
import XCTest

/// What a wait reported, with XCTest's messages: the format strings are those `XCTestCase` uses as a waiter's
/// delegate, which records its issues only while XCTest runs the test. They are recorded once the wait is
/// over, on the step's task: the waiter calls its delegate on any queue, where no step runs.
private final class WaitFailures: NSObject, XCTWaiterDelegate, @unchecked Sendable {
    private let timeout: TimeInterval
    private let lock = NSLock()
    private var messages = [String]()

    init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    private func add(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        messages.append(message)
    }

    func waiter(_ waiter: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
        let descriptions = unfulfilledExpectations.map(\.expectationDescription).joined(separator: "\", \"")
        let format = "Asynchronous wait failed: Exceeded timeout of %g seconds, with unfulfilled expectations: \"%@\"."
        add(String(format: format, timeout, descriptions))
    }

    func waiter(_ waiter: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
        add(String(format: "Fulfilled inverted expectation \"%@\".", expectation.expectationDescription))
    }

    /// Fails the running step at its line in the feature file, as a thrown error does.
    func recordAsIssues() {
        lock.lock()
        let messages = messages
        lock.unlock()
        let running = RunningLocation.current
        for message in messages {
            running?.record?.add(message)
            if let location = running?.location {
                Issue.record(Comment(rawValue: message), sourceLocation: location)
            } else {
                Issue.record(Comment(rawValue: message))
            }
        }
    }
}

extension Cucumber {
    /// Create an unfulfilled expectation.
    ///
    /// - Parameter description: the expectation description
    /// - Returns: the new expectation
    ///
    public func expectation(description: String) -> XCTestExpectation {
        XCTestExpectation(description: description)
    }

    /// Wait for a list of expectations to be fulfilled.
    ///
    /// As with CucumberSwift, if the timeout passes first, or an inverted expectation is fulfilled, the step
    /// fails at its line in the feature file with XCTest's message for that result. The scenario fails, and
    /// its later steps are skipped. Steps run on the main actor, and this wait holds it: Swift Testing runs
    /// the main actor's work on the main queue, which a waiting step occupies, so work on the main actor or
    /// the main queue can't fulfill an expectation until the wait is over. Write `await` before the call, as
    /// in `await wait(for: [expectation], timeout: 5)`, to wait without holding the main actor.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) {
        let failures = WaitFailures(timeout: seconds)
        // Not on this thread: an `XCTWaiter` ends its wait with `CFRunLoopStop` on the waiting thread's run loop,
        // and on the main thread that can stop the run loop Swift Testing's process runs on, which then exits
        // as if every test had passed. The step is blocked either way, so nothing else changes.
        let waited = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            XCTWaiter(delegate: failures).wait(for: expectations, timeout: seconds)
            waited.signal()
        }
        waited.wait()
        failures.recordAsIssues()
    }

    /// Wait for a list of expectations to be fulfilled, without holding the main actor.
    ///
    /// Work on the main actor or the main queue can fulfill them. Swift picks this one when the call is
    /// written with `await`. As with `wait(for:timeout:)`, a timeout or a fulfilled inverted expectation
    /// fails the step.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) async {
        let failures = WaitFailures(timeout: seconds)
        await XCTWaiter(delegate: failures).fulfillment(of: expectations, timeout: seconds)
        failures.recordAsIssues()
    }
}
#endif
