//
//  StepFailureLocationTests.swift
//  CucumberSwiftTests
//
//  A failure recorded while a step runs is moved to the step's line in its feature file, so that
//  clicking it in Xcode opens the Gherkin and Xcode marks the step there (#59).
//
import Foundation
import XCTest
@testable import CucumberSwift

class StepFailureLocationTests: XCTestCase {
    private static let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private static let featureURI = directory.appendingPathComponent("Located.feature").absoluteString
    private static let stepDefinitions = directory.appendingPathComponent("StepDefinitions.swift").path

    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    private func firstStep(uri: String) throws -> Step {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given some precondition
             Then some outcome
        """, uri: uri)
        return try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first?.steps.last)
    }

    private func issue(at file: String, line: Int) -> XCTIssue {
        XCTIssue(type: .assertionFailure,
                 compactDescription: "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")",
                 detailedDescription: nil,
                 sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: file, lineNumber: line)),
                 associatedError: nil,
                 attachments: [])
    }

    func testAFailureInAStepDefinitionMovesToTheStepInItsFeatureFile() throws {
        let step = try firstStep(uri: Self.featureURI)
        let located = StepTestCase.issue(issue(at: Self.stepDefinitions, line: 42), locatedAt: step)

        XCTAssertEqual(located.sourceCodeContext.location?.fileURL, URL(string: Self.featureURI))
        XCTAssertEqual(located.sourceCodeContext.location?.lineNumber, 4)
    }

    // The reporters and the issue navigator see the same failure as before: only its location changes.
    func testTheFailureKeepsItsDescriptionAndType() throws {
        let step = try firstStep(uri: Self.featureURI)
        let original = issue(at: Self.stepDefinitions, line: 42)
        let located = StepTestCase.issue(original, locatedAt: step)

        XCTAssertEqual(located.compactDescription, original.compactDescription)
        XCTAssertEqual(located.type, original.type)
    }

    func testAFailureAlreadyInTheFeatureFileStaysWhereItIs() throws {
        let step = try firstStep(uri: Self.featureURI)
        let original = XCTIssue(type: .assertionFailure,
                                compactDescription: "ambiguous",
                                detailedDescription: nil,
                                sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(fileURL: try XCTUnwrap(URL(string: Self.featureURI)),
                                                                                                        lineNumber: 3)),
                                associatedError: nil,
                                attachments: [])

        XCTAssertEqual(StepTestCase.issue(original, locatedAt: step).sourceCodeContext.location?.lineNumber, 3)
    }

    // A step with no feature file, such as one from the DSL, keeps the step definition's location.
    func testAStepWithNoFeatureFileKeepsTheOriginalLocation() throws {
        let step = try firstStep(uri: "")
        let located = StepTestCase.issue(issue(at: Self.stepDefinitions, line: 42), locatedAt: step)

        XCTAssertEqual(located.sourceCodeContext.location?.fileURL.path, Self.stepDefinitions)
        XCTAssertEqual(located.sourceCodeContext.location?.lineNumber, 42)
    }

    // CucumberStepTest.m and StepTestSupport find each other by name, so a typo in either compiles
    // and only shows when a step is skipped or fails.
    func testTheSupportClassAnswersWhatTheObjectiveCClassAsks() throws {
        let support: AnyObject = try XCTUnwrap(NSClassFromString("CucumberStepTestSupport"))
        XCTAssertTrue(support.responds(to: NSSelectorFromString("skipErrorForStepTest:")))
        XCTAssertTrue(support.responds(to: NSSelectorFromString("locateIssue:inStepTest:")))
    }

    func testGeneratedScenarioClassesRelocateTheirFailures() throws {
        let base = try XCTUnwrap(NSClassFromString("CucumberStepTest"))
        let generated = try XCTUnwrap(TestCaseGenerator.makeClass(className: "StepFailureLocationTestsScenario", superclass: StepTestCase.superclass))
        XCTAssertTrue(generated.isSubclass(of: base))
    }
}
