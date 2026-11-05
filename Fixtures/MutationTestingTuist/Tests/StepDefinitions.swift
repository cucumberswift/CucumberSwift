//
//  StepDefinitions.swift
//  VotingTests
//
//  Step definitions run with CucumberSwift and XCTest.
//

import CucumberSwift
import Voting
import XCTest

@MainActor
enum World {
    static var age = 0
    static var licensed = false
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // The test bundle, which holds the Features folder.
        class Marker {}
        return Bundle(for: Marker.self)
    }

    public func setupSteps() {
        Given("a person aged {int}") { match, _ in
            World.age = try match.first(\.int)
            World.licensed = false
        }
        Given("a person aged {int} with a licence") { match, _ in
            World.age = try match.first(\.int)
            World.licensed = true
        }
        Then("the person can vote") { _, _ in
            XCTAssertTrue(Voting.canVote(age: World.age))
        }
        Then("the person cannot vote") { _, _ in
            XCTAssertFalse(Voting.canVote(age: World.age))
        }
        Then("the person can drive") { _, _ in
            XCTAssertTrue(Voting.canDrive(age: World.age, licensed: World.licensed))
        }
        Then("the person cannot drive") { _, _ in
            XCTAssertFalse(Voting.canDrive(age: World.age, licensed: World.licensed))
        }
    }
}
