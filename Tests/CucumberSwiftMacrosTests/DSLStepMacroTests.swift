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

    func testTheTextIsTheLabelAndTheCallAsTheFunctionFormReadsIt() {
        assertMacroExpansion(
            "#Given(I: printAStatement())",
            expandedSource: #"Given(_macroStep: printAStatement(), stepText: "I: printAStatement()", line: 1, column: 7, file: "test.swift")"#,
            macros: macros)
    }

    func testEveryLabelIsPartOfTheText() {
        for label in ["it", "my", "some", "a", "the"] {
            assertMacroExpansion(
                "#Then(\(label): check())",
                expandedSource: #"Then(_macroStep: check(), stepText: "\#(label): check()", line: 1, column: 6, file: "test.swift")"#,
                macros: macros)
        }
    }

    func testAStepWithoutALabelIsTheCallAlone() {
        assertMacroExpansion(
            "#When(addCukes(2))",
            expandedSource: #"When(_macroStep: addCukes(2), stepText: "addCukes(2)", line: 1, column: 6, file: "test.swift")"#,
            macros: macros)
    }

    func testACallOverSeveralLinesReadsAsOnOneLine() {
        assertMacroExpansion(
            """
            #When(a:
                printAStatement(
                    "a",   // the first
                    "b"
                )
            )
            """,
            expandedSource: """
            When(_macroStep: printAStatement(
                    "a",   // the first
                    "b"
                ), stepText: #"a: printAStatement("a", "b")"#, line: 1, column: 6, file: "test.swift")
            """,
            macros: macros)
    }

    func testParenthesesInAStringAreText() {
        assertMacroExpansion(
            #"#And(my: printAStatement("))"))"#,
            expandedSource: ##"And(_macroStep: printAStatement("))"), stepText: #"my: printAStatement("))")"#, line: 1, column: 5, file: "test.swift")"##,
            macros: macros)
    }

    func testAnAsyncFunctionOrClosureIsPassedOn() {
        assertMacroExpansion(
            "#Given(I: signIn)",
            expandedSource: #"Given(_macroStep: signIn, stepText: "I: signIn", line: 1, column: 7, file: "test.swift")"#,
            macros: macros)
        assertMacroExpansion(
            "#But(the: { try await open(.settings) })",
            expandedSource: """
            But(_macroStep: {
                    try await open(.settings)
                }, stepText: "the: { try await open(.settings) }", line: 1, column: 5, file: "test.swift")
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
            "#ES_Dado(I: abrirLaTienda())",
            expandedSource: #"ES_Dado(_macroStep: abrirLaTienda(), stepText: "I: abrirLaTienda()", line: 1, column: 9, file: "test.swift")"#,
            macros: macros)
    }

    func testAStepTakesOneArgument() {
        assertMacroExpansion(
            "#Given(I: first(), second())",
            expandedSource: "#Given(I: first(), second())",
            diagnostics: [
                DiagnosticSpec(message: "A step takes one argument: what it runs, such as `#Given(I: logIn())`, an async function, or a closure.",
                               line: 1,
                               column: 1)
            ],
            macros: macros)
    }
}
#endif
