//
//  StepDefinitions.swift
//  BasketUITests
//
//  UI test step definitions, run with CucumberSwift and XCTest: they launch the app and tap its buttons
//  with XCUITest.
//

import CucumberSwift
import XCTest

@MainActor
enum BasketUI {
    static let app = XCUIApplication()

    /// The cuke count the app shows, found by its identifier whatever kind of element SwiftUI makes of
    /// the text, and waited for, since the first launch on a simulator can be slow.
    static func cukes() -> String {
        let label = app.descendants(matching: .any)["cukes"]
        guard label.waitForExistence(timeout: 30) else {
            XCTFail("The app shows no cuke count. It shows: \(app.debugDescription)")
            return ""
        }
        return label.label
    }
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // The UI test bundle, which holds the Features folder.
        class Marker {}
        return Bundle(for: Marker.self)
    }

    public func setupSteps() {
        // Plain, synchronous steps, as XCUITest expects: its calls wait on the main run loop themselves.
        // CucumberSwift runs them on the main thread, which MainActor.assumeIsolated tells the compiler.
        Given("the app is open") { _, _ in
            MainActor.assumeIsolated { BasketUI.app.launch() }
        }
        When("I tap {string} {int} times") { match, _ in
            let button = try match.first(\.string)
            let count = try match.first(\.int)
            MainActor.assumeIsolated {
                for _ in 0..<count {
                    BasketUI.app.buttons[button].tap()
                }
            }
        }
        Then("the app shows {int} cukes") { match, _ in
            let count = try match.first(\.int)
            MainActor.assumeIsolated {
                XCTAssertEqual(BasketUI.cukes(), "Cukes: \(count)")
            }
        }
    }
}
