//
//  StepDefinitions.swift
//  BasketUnitTests
//
//  Unit test step definitions, run with Swift Testing: they check the app's `Basket` directly, and use
//  `#expect` and `#require`, because Swift Testing ignores a failed XCTest assertion before Swift 6.4.
//

@testable import BasketApp
import CucumberSwiftTesting
import Testing

@MainActor
enum World {
    static var basket = Basket()
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("an empty basket") { _, _ in
            World.basket = Basket()
        }
        When("I add {int} cukes") { match, _ in
            World.basket.add(try match.first(\.int))
        }
        And("I remove {int} cukes") { match, _ in
            try World.basket.remove(try match.first(\.int))
        }
        Then("the basket has {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(World.basket.cukes == count)
        }
        Then("removing {int} cukes fails") { match, _ in
            let count = try match.first(\.int)
            #expect(throws: Basket.NotEnoughCukes.self) {
                try World.basket.remove(count)
            }
        }
    }
}
