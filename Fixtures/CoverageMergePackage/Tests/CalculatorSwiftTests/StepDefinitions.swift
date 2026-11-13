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

    /// Runs `action` on the scenario's calculator.
    static func use(_ action: (Calculator) -> Void) {
        action(calculator)
    }
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a calculator") { _, _ in
            World.calculator = Calculator()
        }
        When("I add {int} and {int}") { match, _ in
            let (first, second) = (try match.first(\.int), try match.last(\.int))
            World.use { $0.add(first, second) }
        }
        When("I divide {int} by {int}") { match, _ in
            let (dividend, divisor) = (try match.first(\.int), try match.last(\.int))
            World.use { $0.divide(dividend, by: divisor) }
        }
        When("I classify {int}") { match, _ in
            let number = try match.first(\.int)
            World.use { $0.classify(number) }
        }
        When("I read the memory") { _, _ in
            World.use { $0.readMemory() }
        }
        When("I clear the memory") { _, _ in
            World.use { $0.clearMemory() }
        }
        Then("the display shows {string}") { match, _ in
            let shown = try match.first(\.string)
            #expect(World.calculator.display == shown)
        }
    }
}
