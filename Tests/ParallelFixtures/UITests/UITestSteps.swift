//
//  UITestSteps.swift
//  ParallelFixtures
//
//  The step definitions of the UI test fixture. Each scenario drives the app's cart: tapping on iOS,
//  clicking on macOS, and on tvOS pressing the remote's buttons, which act on the focused button.
//
//  On a Simulator the app runs for the whole worker, so one app serves every scenario that worker runs:
//  all of them when Xcode chooses one worker. So each scenario first empties the cart, and every step
//  waits until the app shows the count it expects before going on. No step reads a count left by an
//  earlier scenario.
//

import Foundation
import XCTest
import CucumberSwift

@MainActor
enum UITestApp {
    static let app = XCUIApplication()
    /// The count the scenario expects the app to show: 0 once the cart is emptied, one more for each item added.
    static var expected = 0

    /// The element that shows the item count, found by its identifier, or by its text, whatever kind of
    /// element the platform makes of it. A new query each time, so it reads what the app shows now.
    static func itemCount() -> XCUIElement {
        let byIdentifier = app.descendants(matching: .any)["items"]
        if byIdentifier.exists { return byIdentifier }
        return app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Items:' OR value BEGINSWITH 'Items:'")).firstMatch
    }

    /// Waits up to 30 seconds for the app to show `count` items: on a busy runner the app can show a tap a
    /// moment after the tap returns, and the first launch on a new simulator clone can be slow. Each pass
    /// queries the element afresh and compares its label and value, rather than a predicate expectation,
    /// which reported a count it was not comparing (#375). When the app doesn't show the count, the failure
    /// says what it showed last.
    @discardableResult
    static func waitForItems(_ count: Int, _ failure: String, timeout: TimeInterval = 30, reportFailure: Bool = true) -> Bool {
        let outcome = ItemCountWait.wait(
            for: count,
            timeout: timeout,
            interval: 0.25,
            read: {
                let element = itemCount()
                guard element.exists else { return nil }
                return ItemCountWait.Reading(label: element.label, value: element.value as? String ?? "")
            },
            now: { Date() },
            sleep: { Thread.sleep(forTimeInterval: $0) }
        )
        guard case .timedOut(let lastSeen) = outcome else { return true }
        guard reportFailure else { return false }
        guard let lastSeen else {
            XCTFail("\(failure): the app shows no item count. App state: \(app.state.rawValue). What it shows: \(app.debugDescription.prefix(1_500))")
            return false
        }
        XCTFail("\(failure): expected '\(ItemCountWait.text(for: count))', the app last showed label '\(lastSeen.label)', value '\(lastSeen.value)'")
        return false
    }

    #if os(tvOS)
    /// Waits up to 30 seconds for a button to have the focus, since the remote's buttons act on it.
    static func waitForFocus(on button: XCUIElement) {
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: button)
        if XCTWaiter().wait(for: [focused], timeout: 30) != .completed {
            XCTFail("The '\(button.identifier)' button did not get the focus. What the app shows: \(app.debugDescription.prefix(1_500))")
        }
    }
    #endif

    /// Waits up to 30 seconds for a button to exist and be hittable before it is pressed: on a busy runner, a tap
    /// that has to resolve the button itself can time out while evaluating the UI query, and XCUITest records
    /// that as a failure that can't be caught and retried (#375). Not on tvOS, where buttons are pressed by focus.
    static func waitForButton(_ button: XCUIElement) {
        #if !os(tvOS)
        guard button.waitForExistence(timeout: 30) else { return }
        let deadline = Date().addingTimeInterval(30)
        while !button.isHittable && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
        }
        #endif
    }

    /// Launches the app, and once more if it isn't in the foreground after the first try. While Xcode sets up
    /// another Simulator clone, the first launch on a clone can stall and fail with "Failed to get launch
    /// progress" or "Timed out while launching application via Xcode" (#500). So the first try expects those
    /// failures, and only those: a crash or any other launch
    /// error still fails the test, and so does the second try. `testCase` is the test that runs the hook: with
    /// `continueAfterFailure` off, XCTest ends the test at the first recorded issue, expected or not, and then
    /// neither the second try nor the step's body would run in it, so it is on while the app launches.
    static func launch(in testCase: XCTestCase?) {
        let continueAfterFailure = testCase?.continueAfterFailure
        testCase?.continueAfterFailure = true
        defer { if let continueAfterFailure { testCase?.continueAfterFailure = continueAfterFailure } }
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        options.issueMatcher = { AppLaunchRetry.isStall($0.compactDescription) }
        AppLaunchRetry.launch(
            first: {
                XCTExpectFailure("The app's first launch on a Simulator clone can stall (#500)", options: options) {
                    app.launch()
                }
            },
            isInForeground: { app.state == .runningForeground },
            again: {
                XCTContext.runActivity(named: "The app isn't in the foreground after its first launch (state \(app.state.rawValue)); launching it again (#500)") { _ in
                    app.launch()
                }
            }
        )
    }

    /// Empties the cart, and waits until the app shows it empty. On tvOS the focus moves down to Empty and
    /// back up to Add, where the app put it when it started.
    static func empty() {
        #if os(tvOS)
        XCUIRemote.shared.press(.down)
        waitForFocus(on: app.buttons["empty"])
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        waitForButton(app.buttons["empty"])
        app.buttons["empty"].click()
        #else
        waitForButton(app.buttons["empty"])
        app.buttons["empty"].tap()
        #endif
        expected = 0
        waitForItems(0, "The cart did not empty")
        #if os(tvOS)
        XCUIRemote.shared.press(.up)
        waitForFocus(on: app.buttons["add"])
        #endif
    }

    private static func pressAdd() {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        waitForButton(app.buttons["add"])
        app.buttons["add"].click()
        #else
        waitForButton(app.buttons["add"])
        app.buttons["add"].tap()
        #endif
    }

    /// Adds an item, and waits until the app counts it, so that the next tap starts from a known count. A tap
    /// the app drops, which a busy simulator does at times, is pressed once more after 10 seconds, but only
    /// while the app still shows the count from before it: a late tap that landed shows the new count, and
    /// pressing again would add a second item.
    static func add() {
        pressAdd()
        expected += 1
        if waitForItems(expected, "", timeout: 10, reportFailure: false) { return }
        if waitForItems(expected - 1, "", timeout: 1, reportFailure: false) {
            pressAdd()
        }
        waitForItems(expected, "The app did not count an added item")
    }
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        // A subclass of CucumberTest, as consumers write it.
        class TestDiscovery: CucumberTest {
            // Empty on purpose: XCTest hands this subclass to a worker of its own, which must not run the scenarios again.
        }
        return Bundle(for: TestDiscovery.self)
    }

    // Longer than the longest step: "I add 5 items" waits up to 30 seconds for the app to count each item. With
    // the default 60 seconds, an app that doesn't respond fails as a timeout rather than as what it didn't show.
    public var asyncStepTimeout: TimeInterval { 300 }

    public func setupSteps() {
        ParallelFixtureSupport.setUp()

        // Plain, synchronous hooks and steps, as XCUITest expects: its calls wait on the main run loop
        // themselves. They run on the main thread, which MainActor.assumeIsolated tells the compiler.
        // On a Simulator the app is launched once per worker, when it isn't running, and never terminated:
        // launch() would first terminate a copy left running by the scenario before, and on a simulator
        // clone with Xcode 16.4 that fails at times ("Failed to terminate", #375). On a Mac each scenario
        // launches it afresh.
        BeforeScenario { scenario in
            MainActor.assumeIsolated {
                #if targetEnvironment(simulator)
                if UITestApp.app.state == .notRunning {
                    UITestApp.launch(in: scenario.steps.first?.testCase)
                }
                #else
                UITestApp.app.launch()
                #endif
            }
        }

        Given("a fresh cart") { _, _ in
            MainActor.assumeIsolated {
                UITestApp.empty()
            }
        }
        // Async steps that query and tap elements (#424). They run on the main actor, and each suspends
        // before and between its XCUI calls, as a step that awaits other work would.
        When("I add {int} items") { match, _ async throws in
            let count = try match.first(\.int)
            for _ in 0..<count {
                await Task.yield()
                UITestApp.add()
            }
        }
        Then("the cart holds {int} items") { match, _ async throws in
            let count = try match.first(\.int)
            await Task.yield()
            UITestApp.waitForItems(count, "The cart does not hold \(count) items")
        }
        // Long enough that Xcode hands the scenarios to more than one worker.
        Then("the scenario takes a moment") { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }
        // Long enough that the two scenarios that share a name run at the same time in two workers.
        Then("the scenario takes a while") { _, _ in
            Thread.sleep(forTimeInterval: 4)
        }
    }
}
