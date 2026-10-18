//
//  TestingExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 2/24/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

/// What a wait reported, with XCTest's messages: the format strings are those `XCTestCase` uses as a waiter's
/// delegate. An `XCTestCase` delegate records the failure only once XCTest gets back to the test, which with
/// Xcode 16 is after the step has ended, so this one keeps the messages, and they are recorded when the wait
/// returns, while the step still runs. The waiter calls its delegate on any queue.
final class WaitFailures: NSObject, XCTWaiterDelegate, @unchecked Sendable {
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

    func waiter(_: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
        let descriptions = unfulfilledExpectations.map(\.expectationDescription).joined(separator: "\", \"")
        let format = "Asynchronous wait failed: Exceeded timeout of %g seconds, with unfulfilled expectations: \"%@\"."
        add(String(format: format, timeout, descriptions))
    }

    func waiter(_: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
        add(String(format: "Fulfilled inverted expectation \"%@\".", expectation.expectationDescription))
    }

    /// Fails the running test, which moves the failure to the step's line in its feature file.
    func recordOnTheRunningTest() {
        lock.lock()
        let messages = messages
        lock.unlock()
        for message in messages {
            Cucumber.shared.runningTestCase?.record(XCTIssue(type: .assertionFailure, compactDescription: message))
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
    /// If the timeout passes first, or an inverted expectation is fulfilled, the step fails at its line in
    /// the feature file with XCTest's message for that result, as `XCTestCase.wait(for:timeout:)` fails a
    /// test. The scenario fails, and its later steps are skipped. In an `async` step this wait holds the main
    /// actor, so work on the main actor or the main queue can't fulfill the expectations; write
    /// `await wait(for:timeout:)` there.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) {
        let failures = WaitFailures(timeout: seconds)
        XCTWaiter(delegate: failures).wait(for: expectations, timeout: seconds)
        failures.recordOnTheRunningTest()
    }

    /// Wait for a list of expectations to be fulfilled, without holding the main actor.
    ///
    /// In an `async` step, work on the main actor or the main queue can fulfill them only while the step
    /// suspends, which `wait(for:timeout:)` does not; write `await` before the call to choose this one. A
    /// timeout or a fulfilled inverted expectation fails the step, as with `wait(for:timeout:)`.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) async {
        let failures = WaitFailures(timeout: seconds)
        await XCTWaiter(delegate: failures).fulfillment(of: expectations, timeout: seconds)
        failures.recordOnTheRunningTest()
    }
}
