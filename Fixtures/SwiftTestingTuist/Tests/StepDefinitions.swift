//
//  StepDefinitions.swift
//  SwiftTestingTuistTests
//
//  Step definitions for the Swift Testing runner in an Xcode project, in the Swift 6 language mode.
//  If the plugin stops generating the tests in Xcode, or a scenario stops matching, this fixture fails.
//

import CucumberSwiftTesting
import Testing

/// Main-actor state, as a test's app driver or view model would be.
@MainActor final class Basket {
    static let shared = Basket()
    var cukes = 0
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("an empty basket") { _, _ in
            Basket.shared.cukes = 0
        }
        When("I add {int} cukes") { match, _ in
            Basket.shared.cukes += try match.first(\.int)
        }
        And("I remove {int} cukes") { match, _ in
            Basket.shared.cukes -= try match.first(\.int)
        }
        Then("the basket has {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(Basket.shared.cukes == count)
        }
    }
}
