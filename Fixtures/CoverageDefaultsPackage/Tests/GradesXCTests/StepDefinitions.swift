//
//  StepDefinitions.swift
//  GradesXCTests
//
//  Step definitions run with CucumberSwift and XCTest.
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
        Bundle.module
    }

    public func setupSteps() {
        // CucumberSwift never measures the files in its own package folder, and this fixture is inside it.
        Cucumber.coverageSources = ["CoverageDefaultsPackage/Sources"]
        Given("a score of {int}") { match, _ in
            World.score = try match.first(\.int)
        }
        Then("the grade is {string}") { match, _ in
            XCTAssertEqual(Grades.grade(for: World.score), try match.first(\.string))
        }
    }
}
