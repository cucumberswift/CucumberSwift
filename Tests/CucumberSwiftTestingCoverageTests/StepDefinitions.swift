//
//  StepDefinitions.swift
//  CucumberSwiftTestingCoverageTests
//
//  Runs the Grading feature with the Swift Testing runner against Grades, which Bazel builds with code
//  coverage under `bazel coverage`.
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
        Given("a score of {int}") { match, _ in
            World.score = try match.first(\.int)
        }
        Then("the grade is {string}") { match, _ in
            let grade = try match.first(\.string)
            #expect(Grades.grade(for: World.score) == grade)
        }
    }
}
