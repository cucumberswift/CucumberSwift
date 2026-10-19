//
//  SwiftDSLFeature.swift
//  StepDefinitionMacrosPackageTests
//
//  A feature written in the Swift DSL with the DSL step macros, such as `#Given(I: fillTheBasket())`, whose
//  text is captured when the tests compile rather than read from this file when they run.
//

import CucumberSwiftMacros
import XCTest

// CucumberSwift's DSL steps and hooks are not main-actor isolated, so their state isn't either.
nonisolated(unsafe) private var cukes = 0

private func fillTheBasket(with count: Int) { cukes = count }

private func emptyTheBasket() async {
    await Task.yield()
    cukes = 0
}

/// The text of each step of the feature that has run, as the hooks and the report see it.
nonisolated(unsafe) private var stepTexts = [String]()

extension Cucumber {
    func swiftDSLFeature() {
        #BeforeStep { step in
            guard step.scenario?.feature?.title == "Swift DSL step macros" else { return }
            stepTexts.append(step.match)
        }
        Feature("Swift DSL step macros") {
            Scenario("A basket filled and emptied") {
                #Given(I: fillTheBasket(with: 3))
                #When(I: emptyTheBasket)
                #Then(the: {
                    XCTAssertEqual(cukes, 0)
                    XCTAssertEqual(Array(stepTexts.prefix(2)), ["I: fillTheBasket(with: 3)", "I: emptyTheBasket"])
                    // A closure written over several lines reads as on one.
                    XCTAssertEqual(stepTexts.count, 3)
                    XCTAssertFalse(stepTexts.last?.contains("\n") ?? true)
                })
            }
        }
    }
}
