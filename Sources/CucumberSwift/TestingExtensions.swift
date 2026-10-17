//
//  TestingExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 2/24/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

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
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) {
        XCTWaiter().wait(for: expectations, timeout: seconds)
    }

    /// Wait for a list of expectations to be fulfilled, without holding the main actor. In an `async` step,
    /// work on the main actor or the main queue can fulfill them only while the step suspends, which
    /// `wait(for:timeout:)` does not; write `await` before the call to choose this one.
    ///
    /// - Parameters:
    ///   - expectations: the expectations to wait for
    ///   - seconds: the wait timeout
    ///
    public func wait(for expectations: [XCTestExpectation], timeout seconds: TimeInterval) async {
        await XCTWaiter().fulfillment(of: expectations, timeout: seconds)
    }
}
