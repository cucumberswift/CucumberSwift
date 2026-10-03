//
//  StepDefinitions.swift
//  StepDefinitionMacrosTuistTests
//
//  Step definitions written with the step definition macros. Without the Macros trait the macros
//  are not declared, so this file only compiles when Tuist's trait reaches Xcode.
//

import CucumberSwiftMacros
import XCTest

@MainActor final class Basket {
    static let shared = Basket()
    var cukes = 0
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle(for: Basket.self) }

    public func setupSteps() {
        #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
            XCTAssertEqual(container, "basket")
            Basket.shared.cukes = count
        }

        #When("I eat {int} cukes") { (count: Int) in
            Basket.shared.cukes -= count
        }

        #Then("^the basket holds (\\d+) cukes?$") { (count: String) in
            XCTAssertEqual(Basket.shared.cukes, Int(count))
        }
    }
}
