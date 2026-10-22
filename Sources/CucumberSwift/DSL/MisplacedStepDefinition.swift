//
//  MisplacedStepDefinition.swift
//  CucumberSwift
//
// Step definitions written among a scenario's steps in the Swift DSL, such as `Given("I do X") { _, _ in }` inside
// `Scenario { … }`. A step definition and a DSL step are the same type, so the compiler can't tell them apart there:
// `StepBuilder` leaves the step definition out of the scenario, and `testGherkin()` fails at its line.

import Foundation

enum MisplacedStepDefinition {
    static let message = "A step definition belongs in setupSteps(), outside a feature written in the Swift DSL. "
        + "Inside a scenario, write a DSL step, such as Given(I: doSomething())."

    private static let state = Locked([RegularExpression.Problem]())

    /// One problem for each step definition written among a scenario's steps, at its own line.
    static var errors: [RegularExpression.Problem] {
        state.snapshot
    }

    static func record(file: StaticString?, line: Int?) {
        state.withLock { $0.append(.init(message: message, file: file.map { String(describing: $0) }, line: line)) }
    }

    static func reset() {
        state.withLock { $0 = [] }
    }
}
