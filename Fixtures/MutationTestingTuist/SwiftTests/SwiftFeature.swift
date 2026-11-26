//
//  SwiftFeature.swift
//  VotingSwiftTests
//
//  A feature written in Swift, with no feature file, that runs with the feature files' scenarios.
//

import CucumberSwiftTesting
import Testing
import Voting

@MainActor
func aPerson(aged age: Int) {
    World.age = age
}

@MainActor
func theyCanRetire() {
    #expect(Voting.canRetire(age: World.age))
}

@MainActor
func theyCannotRetire() {
    #expect(!Voting.canRetire(age: World.age))
}

extension Cucumber {
    /// Called from `setupSteps()`.
    @MainActor
    func addRetiringInSwift() {
        Feature("Retiring in Swift") {
            Scenario("A senior can retire in Swift") {
                Given(a: aPerson(aged: 70))
                Then(the: theyCanRetire())
            }
            Scenario("An adult cannot retire in Swift") {
                Given(a: aPerson(aged: 30))
                Then(the: theyCannotRetire())
            }
        }
    }
}
