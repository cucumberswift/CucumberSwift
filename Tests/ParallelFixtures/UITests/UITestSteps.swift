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

    /// The element that shows the item count. Found by its identifier, or by its text, whatever kind of
    /// element the platform makes of it, and waited for, since the first launch on a new simulator clone can
    /// be slow.
    static func itemCount() -> XCUIElement? {
        let byIdentifier = app.descendants(matching: .any)["items"]
        let byText = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Items:' OR value BEGINSWITH 'Items:'")).firstMatch
        let found = byIdentifier.waitForExistence(timeout: 30) ? byIdentifier : byText
        guard found.exists else {
            XCTFail("The app shows no item count. App state: \(app.state.rawValue). What it shows: \(app.debugDescription.prefix(1_500))")
            return nil
        }
        return found
    }

    /// Waits up to 30 seconds for the app to show `count` items: on a busy runner the app can show a tap a
    /// moment after the tap returns. When it doesn't, the failure says what the app shows instead.
    static func waitForItems(_ count: Int, _ failure: String) {
        guard let element = itemCount() else { return }
        let text = "Items: \(count)"
        let shows = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@ OR value == %@", text, text), object: element)
        guard XCTWaiter().wait(for: [shows], timeout: 30) != .completed else { return }
        let shown = element.label.isEmpty ? (element.value as? String ?? "") : element.label
        XCTFail("\(failure): the app shows '\(shown)', not '\(text)'")
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

    /// Empties the cart, and waits until the app shows it empty. On tvOS the focus moves down to Empty and
    /// back up to Add, where the app put it when it started.
    static func empty() {
        #if os(tvOS)
        XCUIRemote.shared.press(.down)
        waitForFocus(on: app.buttons["empty"])
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        app.buttons["empty"].click()
        #else
        app.buttons["empty"].tap()
        #endif
        expected = 0
        waitForItems(0, "The cart did not empty")
        #if os(tvOS)
        XCUIRemote.shared.press(.up)
        waitForFocus(on: app.buttons["add"])
        #endif
    }

    /// Adds an item, and waits until the app counts it, so that the next tap starts from a known count.
    static func add() {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        app.buttons["add"].click()
        #else
        app.buttons["add"].tap()
        #endif
        expected += 1
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

    public func setupSteps() {
        ParallelFixtureSupport.setUp()

        // Plain, synchronous hooks and steps, as XCUITest expects: its calls wait on the main run loop
        // themselves. They run on the main thread, which MainActor.assumeIsolated tells the compiler.
        // On a Simulator the app is launched once per worker, when it isn't running, and never terminated:
        // launch() would first terminate a copy left running by the scenario before, and on a simulator
        // clone with Xcode 16.4 that fails at times ("Failed to terminate", #375). On a Mac each scenario
        // launches it afresh.
        BeforeScenario { _ in
            MainActor.assumeIsolated {
                #if targetEnvironment(simulator)
                if UITestApp.app.state == .notRunning {
                    UITestApp.app.launch()
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
        When("I add {int} items") { match, _ in
            let count = try match.first(\.int)
            MainActor.assumeIsolated {
                for _ in 0..<count {
                    UITestApp.add()
                }
            }
        }
        Then("the cart holds {int} items") { match, _ in
            let count = try match.first(\.int)
            MainActor.assumeIsolated {
                UITestApp.waitForItems(count, "The cart does not hold \(count) items")
            }
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
