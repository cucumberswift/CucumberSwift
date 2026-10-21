//
//  SwiftDSLFeature.swift
//  StepDefinitionMacrosPackageTests
//
//  A feature written in the Swift DSL with the DSL step macros, such as `#Given(I: fillTheBasket())`, whose
//  text is captured when the tests compile rather than read from this file when they run.
//

import CucumberSwiftMacros
import XCTest

@MainActor
private func fillTheBasket(with count: Int) { Basket.shared.cukes = count }

@MainActor
private func emptyTheBasket() async {
    await Task.yield()
    Basket.shared.cukes = 0
}

/// The text of each step of the feature that has run, as the hooks and the report see it.
@MainActor
private var stepTexts = [String]()

extension Cucumber {
    // Main-actor, as setupSteps() is, which calls it: the steps and hooks declared here use main-actor code.
    @MainActor
    func swiftDSLFeature() {
        #BeforeStep { step in
            guard step.scenario?.feature?.title == "Swift DSL step macros" else { return }
            stepTexts.append(step.match)
        }
        #Feature("Swift DSL step macros") {
            #Scenario("A basket filled and emptied") {
                #Given(I: fillTheBasket(with: 3))
                #When(I: emptyTheBasket)
                #Then(the: {
                    XCTAssertEqual(Basket.shared.cukes, 0)
                    XCTAssertEqual(Array(stepTexts.prefix(2)), ["I: fillTheBasket(with: 3)", "I: emptyTheBasket"])
                    // A closure written over several lines reads as on one.
                    XCTAssertEqual(stepTexts.count, 3)
                    XCTAssertFalse(stepTexts.last?.contains("\n") ?? true)
                })
            }
        }
    }
}
