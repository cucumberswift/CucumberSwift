//
//  DSLPlacementTests.swift
//  CucumberSwiftTests
//

@testable import CucumberSwift
import XCTest

/// A step definition written among a scenario's steps compiles, because it is the same type as a DSL step, so the
/// scenario leaves it out and `testGherkin()` fails at its line.
final class DSLPlacementTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MisplacedStepDefinition.reset()
    }

    override func tearDown() {
        MisplacedStepDefinition.reset()
        super.tearDown()
    }

    func testAStepDefinitionInAScenarioIsLeftOutAndRecordedAtItsLine() throws {
        func start() {}
        let definitionLine = #line + 4
        let feature =
        Feature("F") {
            Scenario("S") {
                Given("I do X") { _, _ in }
                When(I: start())
            }
        }

        XCTAssertEqual(feature.scenarios.first?.steps.map(\.match), ["I: start()"])
        let problem = try XCTUnwrap(MisplacedStepDefinition.errors.first)
        XCTAssertEqual(MisplacedStepDefinition.errors.count, 1)
        XCTAssertEqual(problem.message, MisplacedStepDefinition.message)
        XCTAssertEqual(problem.file, "\(#file)")
        XCTAssertEqual(problem.line, definitionLine)
    }

    func testDSLStepsAloneRecordNothing() {
        func start() {}
        Feature("F") {
            Background {
                Given(I: start())
            }
            Scenario("S") {
                When(I: start())
            }
        }
        XCTAssertTrue(MisplacedStepDefinition.errors.isEmpty)
    }
}
