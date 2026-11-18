//
//  StepDefinitions.swift
//  CucumberSwiftCoverageTests
//
//  Runs the Grading feature against Grades, which Bazel builds with code coverage under `bazel coverage`.
//

import CucumberSwift
import Grades
import XCTest

@MainActor
enum World {
    static var score = 0
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // The test bundle, which holds the Features folder.
        class Marker {}
        return Bundle(for: Marker.self)
    }

    public func setupSteps() {
        Given("a score of {int}") { match, _ in
            World.score = try match.first(\.int)
        }
        Then("the grade is {string}") { match, _ in
            XCTAssertEqual(Grades.grade(for: World.score), try match.first(\.string))
        }
    }
}
