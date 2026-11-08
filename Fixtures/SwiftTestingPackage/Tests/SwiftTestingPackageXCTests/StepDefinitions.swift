//
//  StepDefinitions.swift
//  SwiftTestingPackageXCTests
//
//  Step definitions for the XCTest target, which runs its feature files with CucumberSwift's XCTest runner
//  beside the Swift Testing target. Both targets write one Cucumber JSON report.
//

import CucumberSwiftMacros
import XCTest

@MainActor final class Checkout {
    static let shared = Checkout()
    var cukes = 0
    var isPaid = false
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle.module }

    public func setupSteps() {
        #Given("a basket of {int} cukes") { (cukes: Int) in
            Checkout.shared.cukes = cukes
            Checkout.shared.isPaid = false
        }
        #When("I pay for the basket") {
            Checkout.shared.isPaid = true
        }
        #Then("the basket is paid") {
            XCTAssertTrue(Checkout.shared.isPaid)
        }
    }
}
