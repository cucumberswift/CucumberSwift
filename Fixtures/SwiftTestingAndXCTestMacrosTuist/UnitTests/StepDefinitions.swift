//
//  StepDefinitions.swift
//  BasketUnitTests
//
//  Unit test step definitions written as macros, run with Swift Testing: the compiler checks each
//  expression against its closure's parameters. They use `#expect` and `#require`, because Swift
//  Testing ignores a failed XCTest assertion before Swift 6.4.
//

@testable import BasketApp
import UnitStepDefinitionMacros
import Testing

@MainActor
enum World {
    static var basket = Basket()
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Given("an empty basket") {
            World.basket = Basket()
        }
        #When("I add {int} cukes") { (count: Int) in
            World.basket.add(count)
        }
        #And("I remove {int} cukes") { (count: Int) in
            try World.basket.remove(count)
        }
        #Then("the basket has {int} cukes") { (count: Int) in
            #expect(World.basket.cukes == count)
        }
        #Then("removing {int} cukes fails") { (count: Int) in
            #expect(throws: Basket.NotEnoughCukes.self) {
                try World.basket.remove(count)
            }
        }
    }
}
