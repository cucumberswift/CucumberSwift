//
//  StepDefinitions.swift
//  BasketUITests
//
//  UI test step definitions, run with CucumberSwift and XCTest: they launch the app and tap its buttons
//  with XCUITest.
//

import CucumberSwift
import XCTest

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // The UI test bundle, which holds the Features folder.
        class Marker {}
        return Bundle(for: Marker.self)
    }

    public func setupSteps() {
        Given("the app is open") { _, _ in
            BasketUI.launch()
        }
        When("I tap {string} {int} times") { match, _ in
            BasketUI.tap(try match.first(\.string), times: try match.first(\.int))
        }
        Then("the app shows {int} cukes") { match, _ in
            let count = try match.first(\.int)
            XCTAssertEqual(BasketUI.cukes(), "Cukes: \(count)")
        }
    }
}
