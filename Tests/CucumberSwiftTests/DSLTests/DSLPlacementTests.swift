//
//  DSLPlacementTests.swift
//  CucumberSwiftTests
//

@testable import CucumberSwift
import XCTest

/// Keeps what `testGherkin()` fails with for a step definition, rather than recording it. Its suite has no tests, so
/// XCTest doesn't run its `testGherkin()` on its own.
private final class CapturingCucumberTest: CucumberTest {
    override static var defaultTestSuite: XCTestSuite {
        XCTestSuite(name: String(describing: Self.self))
    }

    var failures = [XCTIssue]()

    override func failStep(_ issue: XCTIssue) {
        failures.append(issue)
    }
}

/// A step definition written among a scenario's steps compiles, because it is the same type as a DSL step, so the
/// scenario leaves it out and `testGherkin()` fails at its line.
final class DSLPlacementTests: XCTestCase {
    private var capturing = false
    private var recordedIssues = [XCTIssue]()

    // While `testGherkin()` runs, keep the failures it records; other failures fail this test.
    override func record(_ issue: XCTIssue) {
        guard capturing else {
            super.record(issue)
            return
        }
        recordedIssues.append(issue)
    }

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

    func testADSLStepThatNoScenarioTakesIsRecordedAtItsLine() throws {
        func start() {}
        let stepLine = #line + 1
        _ = Given(I: start())

        let problem = try XCTUnwrap(MisplacedStepDefinition.errors.first)
        XCTAssertEqual(MisplacedStepDefinition.errors.count, 1)
        XCTAssertEqual(problem.message, MisplacedStepDefinition.stepOutsideScenarioMessage)
        XCTAssertEqual(problem.line, stepLine)
    }

    func testTestGherkinFailsAtEachMisplacedStepsLine() {
        func start() {}
        let definitionLine = #line + 3
        Feature("F") {
            Scenario("S") {
                Given("I do X") { _, _ in }
                When(I: start())
            }
        }
        let stepLine = #line + 1
        _ = Then(I: start())

        let reporter = CapturingCucumberTest()
        capturing = true
        reporter.testGherkin()
        capturing = false

        let placement = reporter.failures.filter {
            [MisplacedStepDefinition.message, MisplacedStepDefinition.stepOutsideScenarioMessage].contains($0.compactDescription)
        }
        XCTAssertEqual(placement.map(\.compactDescription), [MisplacedStepDefinition.message, MisplacedStepDefinition.stepOutsideScenarioMessage])
        XCTAssertEqual(placement.map { $0.sourceCodeContext.location?.lineNumber }, [definitionLine, stepLine])
        XCTAssertEqual(placement.map { $0.sourceCodeContext.location?.fileURL.lastPathComponent }, ["DSLPlacementTests.swift", "DSLPlacementTests.swift"])
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
