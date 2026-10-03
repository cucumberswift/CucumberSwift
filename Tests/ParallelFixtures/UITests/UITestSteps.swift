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
import CucumberSwiftExpressions

@MainActor
enum UITestApp {
    static let app = XCUIApplication()

    /// The item count the app shows. Found by its identifier whatever kind of element the platform makes of
    /// the text, and waited for, since the first launch on a new simulator clone can be slow.
    static func items() -> String {
        let label = app.descendants(matching: .any)["items"]
        XCTAssertTrue(label.waitForExistence(timeout: 30), "The app shows no item count. App state: \(app.state.rawValue)")
        return label.label.isEmpty ? (label.value as? String ?? "") : label.label
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

        BeforeScenario { _ async in
            UITestApp.app.launch()
        }
        AfterScenario { _ async in
            UITestApp.app.terminate()
        }

        Given("a fresh cart" as CucumberExpression) { _, _ async throws in
            XCTAssertEqual(UITestApp.items(), "Items: 0")
        }
        When("I add {int} items" as CucumberExpression) { match, _ async throws in
            for _ in 0..<(try match.first(\.int)) {
                UITestApp.add()
            }
        }
        Then("the cart holds {int} items" as CucumberExpression) { match, _ async throws in
            XCTAssertEqual(UITestApp.items(), "Items: \(try match.first(\.int))")
        }
        // Long enough that Xcode hands the scenarios to more than one worker.
        Then("the scenario takes a moment" as CucumberExpression) { _, _ async throws in
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        // Long enough that the two scenarios that share a name run at the same time in two workers.
        Then("the scenario takes a while" as CucumberExpression) { _, _ async throws in
            try await Task.sleep(nanoseconds: 4_000_000_000)
        }
    }
}
