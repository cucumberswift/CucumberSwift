//
//  SwiftFeature.swift
//  VotingTests
//
//  A feature written in Swift, with no feature file, that runs with the feature files' scenarios.
//

import CucumberSwift
import Voting
import XCTest

@MainActor
func aPerson(aged age: Int) {
    World.age = age
}

@MainActor
func theyCanVote() {
    XCTAssertTrue(Voting.canVote(age: World.age))
}

@MainActor
func theyCannotVote() {
    XCTAssertFalse(Voting.canVote(age: World.age))
}

extension Cucumber {
    /// Called from `setupSteps()`.
    @MainActor
    func addVotingInSwift() {
        Feature("Voting in Swift") {
            Scenario("An adult can vote in Swift") {
                Given(a: aPerson(aged: 30))
                Then(the: theyCanVote())
            }
            Scenario("A child cannot vote in Swift") {
                Given(a: aPerson(aged: 5))
                Then(the: theyCannotVote())
            }
        }
    }
}
