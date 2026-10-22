@testable import CucumberSwiftLintTool
import XCTest

/// A step definition inside a feature written in the Swift DSL, and a DSL step outside one, are errors, which fail
/// the build. The rest of the file is left alone.
final class DSLPlacementCheckTests: LintTestCase {
    private let feature = "Feature: F\n  Scenario: S\n    Given I do X\n"

    private func errors(_ steps: String) throws -> [String] {
        try check(feature, steps: steps).filter { $0.severity == .error }.map { "\($0.line) \($0.message)" }
    }

    func testAStepDefinitionInADSLScenarioIsAnError() throws {
        XCTAssertEqual(try errors("""
        Given("I do X") { _, _ in }
        Feature("F") {
            Scenario("S") {
                When("I do {int} things") { _, _ in }
                Then(I: check())
            }
        }
        """), ["4 \(DSLPlacementCheck.stepDefinitionInFeature)"])
    }

    func testAStepDefinitionMacroInAFeatureMacroIsAnError() throws {
        XCTAssertEqual(try errors("""
        #Feature("F") {
            #Background {
                #Given(#/^I do X$/#) { }
            }
        }
        """), ["3 \(DSLPlacementCheck.stepDefinitionInFeature)"])
    }

    func testALocalizedStepDefinitionInALocalizedScenarioIsAnError() throws {
        XCTAssertEqual(try errors("""
        ES_Característica("C") {
            ES_Escenario("E") {
                ES_Dado("hago X") { _, _ in }
            }
        }
        """), ["3 \(DSLPlacementCheck.stepDefinitionInFeature)"])
    }

    func testARawStringStepDefinitionInAScenarioIsAnError() throws {
        XCTAssertEqual(try errors(##"""
        Scenario("S") {
            Given(#"I do "X""#) { _, _ in }
        }
        """##), ["2 \(DSLPlacementCheck.stepDefinitionInFeature)"])
    }

    func testAStepDefinitionInAStringIsNotOne() throws {
        XCTAssertEqual(try errors(#"""
        Scenario("S") {
            Given(I: write("""
                Given("I do X") { _, _ in }
                """))
            When(I: write("Then(\"done\") { _, _ in }"))
        }
        """#), [])
    }

    func testADSLStepOutsideAScenarioIsAnError() throws {
        XCTAssertEqual(try errors("""
        func setupSteps() {
            Given(I: logIn())
            #When(the: { try await signIn() })
        }
        """), ["2 \(DSLPlacementCheck.stepOutsideScenario)", "3 \(DSLPlacementCheck.stepOutsideScenario)"])
    }

    func testStepsWhereTheyBelongAreFine() throws {
        XCTAssertEqual(try errors("""
        Given("I do X") { _, _ in }   // a step definition, in setupSteps()
        // Given(I: notCode()) in a comment, and in a string: "Scenario(\\"S\\") { Given(\\"x\\") { _, _ in } }"
        Feature("F") {
            Background { Given(I: openTheShop()) }
            ScenarioOutline({ "Buy \\($0)" }, headers: Int.self, steps: { count in
                When(I: buy(count))
            }, examples: { [1, 2] })
            Rule("R") {
                Scenario("S") { Then(the: check()) }
            }
        }
        @StepBuilder func sharedSteps() -> [StepDSL] {
            Given(I: logIn())
        }
        """), [])
    }

    func testAnErrorIsPrintedAsOneAndAWarningAsOne() {
        let error = Diagnostic(file: "/S.swift", line: 2, message: "m", severity: .error)
        XCTAssertEqual(error.description, "/S.swift:2:1: error: m")
        XCTAssertEqual(Diagnostic(file: "/S.swift", line: 2, message: "m").description, "/S.swift:2:1: warning: m")
    }
}
