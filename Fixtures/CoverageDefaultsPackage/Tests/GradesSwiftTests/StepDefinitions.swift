//
//  StepDefinitions.swift
//  GradesSwiftTests
//
//  Step definitions run with Swift Testing, through CucumberSwiftTesting.
//

import CucumberSwiftTesting
import Grades
import Testing

@MainActor
enum World {
    static var score = 0
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        // CucumberSwift never measures the files in its own package folder, and this fixture is inside it.
        Cucumber.coverageSources = ["CoverageDefaultsPackage/Sources"]
        Given("a score of {int}") { match, _ in
            World.score = try match.first(\.int)
        }
        Then("the grade is {string}") { match, _ in
            let grade = try match.first(\.string)
            #expect(Grades.grade(for: World.score) == grade)
        }
    }
}
