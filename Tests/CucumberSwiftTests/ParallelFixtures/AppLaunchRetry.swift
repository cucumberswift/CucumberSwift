//
//  AppLaunchRetry.swift
//  CucumberSwiftTests
//
//  How the UI fixture launches its app when the first launch stalls (#500), apart from XCUITest so that unit
//  tests can reach it. It lives in this bundle, where AppLaunchRetryTests run; the fixtures' manifest,
//  Tests/ParallelFixtures/Project.swift, compiles this same file into the UI test targets.
//

import Foundation

enum AppLaunchRetry {
    /// Whether a launch failure is the stall: Xcode's reply to the launch never came back in time, as it does
    /// on a Simulator clone that Xcode is still setting up. Only the two timeouts seen so far count. A crash or any other launch error is not.
    static func isStall(_ description: String) -> Bool {
        (description.contains("Failed to get launch progress") && description.contains("Timed out while requesting launch progress"))
            || (description.contains("Failed to launch") && description.contains("Timed out while launching application via Xcode"))
    }

    /// Runs `first`, and `again` once more when the app isn't in the foreground after it. Returns whether it ran `again`.
    @discardableResult
    static func launch(first: () -> Void, isInForeground: () -> Bool, again: () -> Void) -> Bool {
        first()
        guard !isInForeground() else { return false }
        again()
        return true
    }
}
