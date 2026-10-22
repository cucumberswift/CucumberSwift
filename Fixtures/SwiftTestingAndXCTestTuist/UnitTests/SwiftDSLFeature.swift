//
//  SwiftDSLFeature.swift
//  BasketUnitTests
//
//  A feature written in the Swift DSL with the step functions, such as `Given(I: emptyTheBasket())`, as a
//  target without CucumberSwift's Macros trait writes it: each step's text is read from this file when the
//  tests run. The generated "Swift DSL features" test runs it.
//

@testable import BasketApp
import CucumberSwiftTesting
import Testing

@MainActor
private func emptyTheBasket() { World.basket = Basket() }

@MainActor
private func addCukes(_ count: Int) { World.basket.add(count) }

@MainActor
private func checkTheBasket() async throws {
    await Task.yield()
    #expect(World.basket.cukes == 3)
}

extension Cucumber {
    func swiftDSLFeature() {
        BeforeStep { step in
            guard step.scenario?.feature?.title == "Basket in Swift" else { return }
            // The text each step function read from this file.
            #expect(["I: emptyTheBasket()", "I: addCukes(3)", "the: checkTheBasket"].contains(step.match))
        }

        Feature("Basket in Swift") {
            Scenario("Add cukes with the step functions") {
                Given(I: emptyTheBasket())
                When(I: addCukes(3))
                Then(the: checkTheBasket)
            }
        }
    }
}
