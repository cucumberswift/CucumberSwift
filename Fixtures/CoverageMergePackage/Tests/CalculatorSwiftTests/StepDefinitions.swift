//
//  StepDefinitions.swift
//  CalculatorSwiftTests
//
//  Step definitions run with Swift Testing, through CucumberSwiftTesting.
//

import Calculator
import CucumberSwiftTesting
import Testing

@MainActor
enum World {
    static var calculator = Calculator()
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a calculator") { _, _ in
            World.calculator = Calculator()
        }
        When("I add {int} and {int}") { match, _ in
            World.calculator.add(try match.first(\.int), try match.last(\.int))
        }
        When("I divide {int} by {int}") { match, _ in
            World.calculator.divide(try match.first(\.int), by: try match.last(\.int))
        }
        When("I classify {int}") { match, _ in
            World.calculator.classify(try match.first(\.int))
        }
        When("I read the memory") { _, _ in
            World.calculator.readMemory()
        }
        When("I clear the memory") { _, _ in
            World.calculator.clearMemory()
        }
        Then("the display shows {string}") { match, _ in
            let shown = try match.first(\.string)
            #expect(World.calculator.display == shown)
        }
    }
}
