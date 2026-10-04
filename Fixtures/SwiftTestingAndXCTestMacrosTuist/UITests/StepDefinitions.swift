//
//  StepDefinitions.swift
//  BasketUITests
//
//  UI test step definitions written as macros, run with CucumberSwift and XCTest: they launch the app
//  and tap its buttons with XCUITest.
//

import CucumberSwiftMacros
import XCTest

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
