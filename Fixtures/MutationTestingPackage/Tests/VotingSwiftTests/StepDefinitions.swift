//
//  StepDefinitions.swift
//  VotingSwiftTests
//
//  Step definitions run with Swift Testing, through CucumberSwiftTesting.
//

import CucumberSwiftTesting
import Testing
import Voting

@MainActor
enum World {
    static var age = 0
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a person aged {int}") { match, _ in
            World.age = try match.first(\.int)
        }
        Then("the person can retire") { _, _ in
            #expect(Voting.canRetire(age: World.age))
        }
        Then("the person cannot retire") { _, _ in
            #expect(!Voting.canRetire(age: World.age))
        }
    }
}
