//
//  BasketUI.swift
//  BasketUITests
//
//  Shared by the UI tests of SwiftTestingAndXCTestTuist and SwiftTestingAndXCTestMacrosTuist, which links
//  to this file, so that the two fixtures differ only in how they write step definitions.
//

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
