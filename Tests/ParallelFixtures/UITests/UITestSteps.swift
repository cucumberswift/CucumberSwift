//
//  UITestSteps.swift
//  ParallelFixtures
//
//  The step definitions of the UI test fixture. Each scenario launches the app and drives its cart: tapping
//  on iOS, clicking on macOS, and pressing the remote's select button on tvOS, where the Add button is the
//  only one that can be focused.
//

import Foundation
import XCTest
import CucumberSwift

@MainActor
enum UITestApp {
    static let app = XCUIApplication()

    /// The item count the app shows. Found by its identifier, or by its text, whatever kind of element the
    /// platform makes of it, and waited for, since the first launch on a new simulator clone can be slow.
    /// Given an expected count, it also waits up to 30 seconds for the app to show it: on a busy runner the
    /// app can show the last tap a moment after the tap returns. When it isn't there, the failure shows
    /// what the app does show.
    static func items(expecting expected: String? = nil) -> String {
        let byIdentifier = app.descendants(matching: .any)["items"]
        let byText = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Items:' OR value BEGINSWITH 'Items:'")).firstMatch
        let found = byIdentifier.waitForExistence(timeout: 30) ? byIdentifier : byText
        guard found.exists else {
            XCTFail("The app shows no item count. App state: \(app.state.rawValue). What it shows: \(app.debugDescription.prefix(1_500))")
            return ""
        }
        func text() -> String { found.label.isEmpty ? (found.value as? String ?? "") : found.label }
        var shown = text()
        let deadline = Date().addingTimeInterval(30)
        while let expected, shown != expected, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
            shown = text()
        }
        return shown
    }

    static func add() {
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        app.buttons["add"].click()
        #else
        app.buttons["add"].tap()
        #endif
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
        // launch() ends a copy left running by the scenario before, so nothing terminates the app: on a
        // simulator clone, terminating it can fail.
        BeforeScenario { _ in
            MainActor.assumeIsolated { UITestApp.app.launch() }
        }

        Given("a fresh cart") { _, _ in
            MainActor.assumeIsolated { XCTAssertEqual(UITestApp.items(expecting: "Items: 0"), "Items: 0") }
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
            MainActor.assumeIsolated { XCTAssertEqual(UITestApp.items(expecting: "Items: \(count)"), "Items: \(count)") }
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
