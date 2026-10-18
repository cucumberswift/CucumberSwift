//
//  Expectations.swift
//  CucumberSwiftTesting
//
// CucumberSwift's `expectation(description:)` and `wait(for:timeout:)`, with the same signatures, so that a
// step definition that waits on an `XCTestExpectation` compiles unchanged with this runner.

#if canImport(XCTest)
import Foundation
import XCTest

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
    /// As with CucumberSwift, the wait ends when they are all fulfilled or the timeout passes, and a timeout
    /// doesn't fail the step. Steps run on the main actor, and this wait holds it: Swift Testing runs the
    /// main actor's work on the main queue, which a waiting step occupies, so work on the main actor or the
    /// main queue can't fulfill an expectation until the wait is over. Write `await` before the call, as in
    /// `await wait(for: [expectation], timeout: 5)`, to wait without holding the main actor.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) {
        XCTWaiter().wait(for: expectations, timeout: seconds)
    }

    /// Wait for a list of expectations to be fulfilled, without holding the main actor, so that work on the
    /// main actor or the main queue can fulfill them. Swift picks this one when the call is written with
    /// `await`. As with CucumberSwift, a timeout doesn't fail the step.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) async {
        await XCTWaiter().fulfillment(of: expectations, timeout: seconds)
    }
}
#endif
