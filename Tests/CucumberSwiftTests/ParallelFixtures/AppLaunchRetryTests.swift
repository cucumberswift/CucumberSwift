//
//  AppLaunchRetryTests.swift
//  CucumberSwiftTests
//
//  The UI fixture's launch retry (#500), without an app: the launches are closures that count their calls.
//

import XCTest

final class AppLaunchRetryTests: XCTestCase {
    func testLaunchesOnceWhenTheAppIsInTheForeground() {
        var launches = 0
        let retried = AppLaunchRetry.launch(first: { launches += 1 }, isInForeground: { true }, again: { launches += 1 })
        XCTAssertEqual(launches, 1)
        XCTAssertFalse(retried)
    }

    func testLaunchesAgainWhenTheAppIsNotInTheForeground() {
        var launches = 0
        let retried = AppLaunchRetry.launch(first: { launches += 1 }, isInForeground: { false }, again: { launches += 1 })
        XCTAssertEqual(launches, 2)
        XCTAssertTrue(retried)
    }

    func testChecksTheForegroundOnlyAfterTheFirstLaunch() {
        var events = [String]()
        AppLaunchRetry.launch(first: { events.append("first") }, isInForeground: { events.append("check"); return false }, again: { events.append("again") })
        XCTAssertEqual(events, ["first", "check", "again"])
    }

    func testBothStallsAreRecognised() {
        XCTAssertTrue(AppLaunchRetry.isStall("Failed to get launch progress for <XCUIApplicationImpl: 0x1 app>: Timed out while requesting launch progress."))
        XCTAssertTrue(AppLaunchRetry.isStall("Failed to launch <XCUIApplicationImpl: 0x1 app> via Xcode: Timed out while launching application via Xcode."))
    }

    func testOtherLaunchFailuresAreNotStalls() {
        XCTAssertFalse(AppLaunchRetry.isStall("Failed to launch <XCUIApplicationImpl: 0x1 app>: The app crashed on launch."))
        XCTAssertFalse(AppLaunchRetry.isStall("Failed to get launch progress for <XCUIApplicationImpl: 0x1 app>: The app crashed on launch."))
        XCTAssertFalse(AppLaunchRetry.isStall("Failed to launch <XCUIApplicationImpl: 0x1 app> via Xcode: The app crashed on launch."))
        XCTAssertFalse(AppLaunchRetry.isStall("Timed out while launching application via Xcode"))
        XCTAssertFalse(AppLaunchRetry.isStall("The cart did not empty"))
    }
}
