//
//  MisplacedStepDefinition.swift
//  CucumberSwift
//
// Steps written where the other kind belongs in the Swift DSL: a step definition, such as `Given("I do X") { _, _ in }`,
// among a scenario's steps, and a DSL step, such as `Given(I: doX())`, that no scenario takes, such as one inside a
// hook. A step definition and a DSL step are the same type, so the compiler can't tell them apart: each container leaves
// the step definition out of what it takes, and `testGherkin()` fails at the line of each.

import Foundation

enum MisplacedStepDefinition {
    static let message = "A step definition belongs in setupSteps(), outside a feature written in the Swift DSL. "
        + "Inside a scenario, write a DSL step, such as Given(I: doSomething())."

    static let stepOutsideScenarioMessage = "A DSL step belongs inside a Scenario, Background or ScenarioOutline. "
        + "To match a step of a feature file, write a step definition, such as Given(\"I do something\") { _, _ in }."

    private static let state = Locked([RegularExpression.Problem]())
    /// The DSL steps created and not yet taken by a scenario, kept so that a step's identity isn't reused.
    private static let unplaced = Locked([ObjectIdentifier: StepDSL]())

    /// One problem for each step definition written among a scenario's steps, and for each DSL step that no scenario
    /// took, at its own line.
    static var errors: [RegularExpression.Problem] {
        let leftOver = unplaced.snapshot.values.sorted { ($0.sourceLine ?? 0) < ($1.sourceLine ?? 0) }.map { step in
            RegularExpression.Problem(message: stepOutsideScenarioMessage,
                                      file: step.sourceFile.map { String(describing: $0) },
                                      line: step.sourceLine)
        }
        return state.snapshot + leftOver
    }

    /// A DSL step was created: it is reported unless a scenario takes it.
    static func created(_ step: StepDSL) {
        unplaced.withLock { $0[ObjectIdentifier(step)] = step }
    }

    /// The steps a scenario, a background or an outline takes, with each step definition among them left out and
    /// recorded at its line, and the DSL steps marked as placed. Only what a container takes counts as placed, so a
    /// step built and thrown away is still reported.
    static func take(_ steps: [StepDSL]) -> [StepDSL] {
        for step in steps where !step.canExecute {
            state.append(RegularExpression.Problem(message: message,
                                                   file: step.sourceFile.map { String(describing: $0) },
                                                   line: step.sourceLine))
        }
        let taken = steps.filter(\.canExecute)
        unplaced.withLock { unplaced in taken.forEach { unplaced[ObjectIdentifier($0)] = nil } }
        return taken
    }

    static func reset() {
        state.withLock { $0 = [] }
        unplaced.withLock { $0 = [:] }
    }
}
