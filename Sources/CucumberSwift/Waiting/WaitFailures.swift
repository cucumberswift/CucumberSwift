//
//  WaitFailures.swift
//  CucumberSwift
//
// Compiled into both runners: CucumberSwiftTesting's Waiting folder links to this one.

#if canImport(XCTest)
import Foundation
import XCTest

/// What an `XCTWaiter` reported, with XCTest's messages: the format strings are those `XCTestCase` uses as a
/// waiter's delegate. An `XCTestCase` delegate queues the failure, and records it only once XCTest gets back to
/// the test, which with Xcode 16 is after the step has ended, and never outside an XCTest run. So each runner's
/// `wait(for:timeout:)` uses this one and records `messages` as the wait returns, while the step still runs.
/// The waiter calls its delegate on any queue.
final class WaitFailures: NSObject, XCTWaiterDelegate, @unchecked Sendable {
    private let timeout: TimeInterval
    private let lock = NSLock()
    private var reported = [String]()

    /// Why the wait failed, in the order the waiter said: none when it succeeded.
    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return reported
    }

    init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    private func add(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        reported.append(message)
    }

    func waiter(_: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
        let descriptions = unfulfilledExpectations.map(\.expectationDescription).joined(separator: "\", \"")
        let format = "Asynchronous wait failed: Exceeded timeout of %g seconds, with unfulfilled expectations: \"%@\"."
        add(String(format: format, timeout, descriptions))
    }

    func waiter(_: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
        add(String(format: "Fulfilled inverted expectation \"%@\".", expectation.expectationDescription))
    }
}
#endif
