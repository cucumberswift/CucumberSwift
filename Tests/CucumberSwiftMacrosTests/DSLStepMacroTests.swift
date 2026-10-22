//
//  DSLStepMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// Each DSL step macro expands to its step with the text that the function form reads from the Swift file
/// when the tests run, captured when they compile, and the line and column of its opening parenthesis.
final class DSLStepMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Given": DSLStepMacro.self,
        "When": DSLStepMacro.self,
        "Then": DSLStepMacro.self,
        "And": DSLStepMacro.self,
        "But": DSLStepMacro.self,
        "MatchAll": DSLStepMacro.self,
        "ES_Dado": DSLStepMacro.self
    ]

    /// `source` as the contents of a scenario's closure, where a DSL step belongs: indented, a line down.
    private func scenario(_ source: String) -> String {
        "Scenario(\"S\") {\n" + source.split(separator: "\n", omittingEmptySubsequences: false).map { "    " + $0 }.joined(separator: "\n") + "\n}"
    }

    func testTheTextIsTheLabelAndTheCallAsTheFunctionFormReadsIt() {
        assertMacroExpansion(
            scenario("#Given(I: printAStatement())"),
            expandedSource: scenario(#"Given(_macroStep: printAStatement(), stepText: "I: printAStatement()", line: 2, column: 11, file: "test.swift")"#),
            macros: macros)
    }

    func testEveryLabelIsPartOfTheText() {
        for label in ["it", "my", "some", "a", "the"] {
            assertMacroExpansion(
                scenario("#Then(\(label): check())"),
                expandedSource: scenario(#"Then(_macroStep: check(), stepText: "\#(label): check()", line: 2, column: 10, file: "test.swift")"#),
                macros: macros)
        }
    }

    func testAStepWithoutALabelIsTheCallAlone() {
        assertMacroExpansion(
            scenario("#When(addCukes(2))"),
            expandedSource: scenario(#"When(_macroStep: addCukes(2), stepText: "addCukes(2)", line: 2, column: 10, file: "test.swift")"#),
            macros: macros)
    }

    func testACallOverSeveralLinesReadsAsOnOneLine() {
        assertMacroExpansion(
            """
            Scenario("S") {
                #When(a:
                    printAStatement(
                        "a",   // the first
                        "b"
                    )
                )
            }
            """,
            expandedSource: """
            Scenario("S") {
                When(_macroStep: printAStatement(
                            "a",   // the first
                            "b"
                        ), stepText: #"a: printAStatement("a", "b")"#, line: 2, column: 10, file: "test.swift")
            }
            """,
            macros: macros)
    }

    func testParenthesesInAStringAreText() {
        assertMacroExpansion(
            scenario(#"#And(my: printAStatement("))"))"#),
            expandedSource: scenario(##"And(_macroStep: printAStatement("))"), stepText: #"my: printAStatement("))")"#, line: 2, column: 9, file: "test.swift")"##),
            macros: macros)
    }

    func testAnAsyncFunctionOrClosureIsPassedOn() {
        assertMacroExpansion(
            scenario("#Given(I: signIn)"),
            expandedSource: scenario(#"Given(_macroStep: signIn, stepText: "I: signIn", line: 2, column: 11, file: "test.swift")"#),
            macros: macros)
        assertMacroExpansion(
            scenario("#But(the: { try await open(.settings) })"),
            expandedSource: """
            Scenario("S") {
                But(_macroStep: {
                        try await open(.settings)
                    }, stepText: "the: { try await open(.settings) }", line: 2, column: 9, file: "test.swift")
            }
            """,
            macros: macros)
    }

    func testTheLineAndColumnAreThoseOfTheOpeningParenthesis() {
        assertMacroExpansion(
            """
            Scenario("A") {
                #MatchAll(I: wait())
            }
            """,
            expandedSource: """
            Scenario("A") {
                MatchAll(_macroStep: wait(), stepText: "I: wait()", line: 2, column: 14, file: "test.swift")
            }
            """,
            macros: macros)
    }

    func testALocalizedStepExpandsToItsLocalizedType() {
        assertMacroExpansion(
            scenario("#ES_Dado(I: abrirLaTienda())"),
            expandedSource: scenario(#"ES_Dado(_macroStep: abrirLaTienda(), stepText: "I: abrirLaTienda()", line: 2, column: 13, file: "test.swift")"#),
            macros: macros)
    }

    func testAStepOutsideAnyClosureIsAnError() {
        assertMacroExpansion(
            """
            func setupSteps() {
                #Given(I: logIn())
            }
            """,
            expandedSource: """
            func setupSteps() {
                Given(_macroStep: logIn(), stepText: "I: logIn()", line: 2, column: 11, file: "test.swift")
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: DSLPlacementMessage.stepOutsideScenario.message, line: 2, column: 5)
            ],
            macros: macros)
    }

    func testAStepInAStepBuilderFunctionIsFine() {
        assertMacroExpansion(
            """
            @StepBuilder func signInSteps() -> [StepDSL] {
                #Given(I: logIn())
            }
            """,
            expandedSource: """
            @StepBuilder func signInSteps() -> [StepDSL] {
                Given(_macroStep: logIn(), stepText: "I: logIn()", line: 2, column: 11, file: "test.swift")
            }
            """,
            macros: macros)
    }

    func testAStepTakesOneArgument() {
        assertMacroExpansion(
            scenario("#Given(I: first(), second())"),
            expandedSource: scenario("#Given(I: first(), second())"),
            diagnostics: [
                DiagnosticSpec(message: "A step takes one argument: what it runs, such as `#Given(I: logIn())`, an async function, or a closure.",
                               line: 2,
                               column: 5)
            ],
            macros: macros)
    }
}
#endif
