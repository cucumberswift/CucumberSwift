//
//  StepDefinitions.swift
//  BasketUITests
//
//  UI test step definitions written as macros, run with CucumberSwift and XCTest: they launch the app
//  and tap its buttons with XCUITest.
//

import UIStepDefinitionMacros
import XCTest

/// Drives the app with XCUITest. Synchronous, as XCUITest expects: its calls wait on the main run loop
/// themselves. CucumberSwift runs steps on the main thread, which MainActor.assumeIsolated tells the
/// compiler.
enum BasketUI {
    @MainActor static let app = XCUIApplication()

    static func launch() {
        MainActor.assumeIsolated { app.launch() }
    }

    static func tap(_ button: String, times count: Int) {
        MainActor.assumeIsolated {
            for _ in 0..<count {
                app.buttons[button].tap()
            }
        }
    }

    /// The cuke count the app shows, found by its identifier whatever kind of element SwiftUI makes of
    /// the text, and waited for, since the first launch on a simulator can be slow.
    static func cukes() -> String {
        MainActor.assumeIsolated {
            let label = app.descendants(matching: .any)["cukes"]
            guard label.waitForExistence(timeout: 30) else {
                XCTFail("The app shows no cuke count. It shows: \(app.debugDescription)")
                return ""
            }
            return label.label
        }
    }
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // The UI test bundle, which holds the Features folder.
        class Marker {}
        return Bundle(for: Marker.self)
    }

    public func setupSteps() {
        #Given("the app is open") {
            BasketUI.launch()
        }
        #When("I tap {string} {int} times") { (button: String, count: Int) in
            BasketUI.tap(button, times: count)
        }
        #Then("the app shows {int} cukes") { (count: Int) in
            XCTAssertEqual(BasketUI.cukes(), "Cukes: \(count)")
        }
    }
}
