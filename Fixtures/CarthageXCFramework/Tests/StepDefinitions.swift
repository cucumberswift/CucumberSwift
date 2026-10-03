//
//  StepDefinitions.swift
//  CarthageXCFrameworkTests
//
//  Step definitions with Cucumber expressions and typed parameters. They only compile when the
//  CucumberSwiftExpressions module ships inside CucumberSwift.framework and `import CucumberSwift`
//  re-exports it.
//

import CucumberSwift
import XCTest

final class Basket {
    static var cukes = 0
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: Basket.self) }

    public func setupSteps() {
        Given("I have {int} cukes in my {string}") { match, _ in
            XCTAssertEqual(try match.first(\.string), "basket")
            Basket.cukes = try match.first(\.int)
        }

        When("I eat {int} cukes") { match, _ in
            Basket.cukes -= try match.first(\.int)
        }

        Then("the basket holds {int} cuke(s)") { (match: CucumberSwiftExpressions.Match, _) in
            XCTAssertEqual(Basket.cukes, try match.first(\.int))
        }
    }
}
