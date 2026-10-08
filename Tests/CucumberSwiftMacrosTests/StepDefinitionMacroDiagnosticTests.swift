//
//  StepDefinitionMacroDiagnosticTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// The errors the step definition macros report, and what applying each fix-it produces.
final class StepDefinitionMacroDiagnosticTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["Given": StepDefinitionMacro.self]

    func testTooFewArgumentsOffersTheParameters() {
        assertMacroExpansion(
            """
            #Given("I have {int} cukes in my {string}") { (count: Int) in
                print(count)
            }
            """,
            expandedSource: """
            #Given("I have {int} cukes in my {string}") { (count: Int) in
                print(count)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The pattern has 2 parameters, but the closure takes 1 argument. "
                                   + "Give the closure one argument per parameter, in order, optionally followed by the Step.",
                               line: 1,
                               column: 47,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (count: Int, string: String)")])
            ],
            macros: macros,
            applyFixIts: ["Change the closure's parameters to (count: Int, string: String)"],
            fixedSource: """
            #Given("I have {int} cukes in my {string}") { (count: Int, string: String) in
                print(count)
            }
            """)
    }

    func testClosureWithoutParametersIsOfferedThem() {
        assertMacroExpansion(
            """
            #Given("I have {int} cukes") { }
            """,
            expandedSource: """
            #Given("I have {int} cukes") { }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The pattern has 1 parameter, but the closure takes 0 arguments. "
                                   + "Give the closure one argument per parameter, in order, optionally followed by the Step.",
                               line: 1,
                               column: 30,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (int: Int)")])
            ],
            macros: macros,
            applyFixIts: ["Change the closure's parameters to (int: Int)"],
            fixedSource: """
            #Given("I have {int} cukes") { (int: Int) in }
            """)
    }

    func testWrongTypeOffersTheExpressionsType() {
        assertMacroExpansion(
            """
            #Given("I have {int} cukes") { (count: String) in
                print(count)
            }
            """,
            expandedSource: """
            #Given("I have {int} cukes") { (count: String) in
                print(count)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "{int} gives Int, but 'count' is declared as String.",
                               line: 1,
                               column: 40,
                               fixIts: [FixItSpec(message: "Change the type to Int")])
            ],
            macros: macros,
            applyFixIts: ["Change the type to Int"],
            fixedSource: """
            #Given("I have {int} cukes") { (count: Int) in
                print(count)
            }
            """)
    }

    func testUnterminatedParameterOffersTheClosingBrace() {
        assertMacroExpansion(
            """
            #Given("I have {int cukes") { (count: Int) in }
            """,
            expandedSource: """
            #Given("I have {int cukes") { (count: Int) in }
            """,
            diagnostics: [
                DiagnosticSpec(message: #"The '{' does not have a matching '}'. If you did not intend to use a parameter you can use '\{' to escape the a parameter"#,
                               line: 1,
                               column: 8,
                               fixIts: [FixItSpec(message: "Insert '}'")])
            ],
            macros: macros,
            applyFixIts: ["Insert '}'"],
            fixedSource: """
            #Given("I have {int} cukes") { (count: Int) in }
            """)
    }

    func testInvalidRegularExpressionIsAnErrorThatCanBecomeAnExpression() {
        // #310: Foundation describes this pattern's problem with a full stop of its own.
        let message = problemMessage("I have {int} cukes$")
        XCTAssert(message.hasSuffix(". Remove the anchors, or write a valid regular expression."), message)
        XCTAssertFalse(message.contains(".."), message)

        assertMacroExpansion(
            """
            #Given("I have {int} cukes$") { (count: Int) in }
            """,
            expandedSource: """
            #Given("I have {int} cukes$") { (count: Int) in }
            """,
            diagnostics: [
                DiagnosticSpec(message: message,
                               line: 1,
                               column: 8,
                               fixIts: [FixItSpec(message: "Use it as a Cucumber Expression")])
            ],
            macros: macros,
            applyFixIts: ["Use it as a Cucumber Expression"],
            fixedSource: """
            #Given("I have {int} cukes") { (count: Int) in }
            """)
    }

    func testInvalidRegularExpressionThatIsNoExpressionEitherHasNoFix() {
        // Without its anchors, "I have (a cuke" is optional text with no ')', so it is not a fix.
        assertMacroExpansion(
            """
            #Given("^I have (a cuke$") { }
            """,
            expandedSource: """
            #Given("^I have (a cuke$") { }
            """,
            diagnostics: [
                DiagnosticSpec(message: problemMessage("^I have (a cuke$"),
                               line: 1,
                               column: 8)
            ],
            macros: macros)
    }

    func testOtherSyntaxErrorsAreReportedWithoutAFix() {
        assertMacroExpansion(
            """
            #Given("I have () cukes") { }
            """,
            expandedSource: """
            #Given("I have () cukes") { }
            """,
            diagnostics: [
                DiagnosticSpec(message: problemMessage("I have () cukes"),
                               line: 1,
                               column: 8)
            ],
            macros: macros)
    }

    func testInterpolatedPatternIsAnError() {
        assertMacroExpansion(
            #"""
            #Given("I have \(count) cukes") { }
            """#,
            expandedSource: #"""
            #Given("I have \(count) cukes") { }
            """#,
            diagnostics: [
                DiagnosticSpec(message: "The step definition's pattern must be a string literal or a regex literal, so it can be checked when it compiles.",
                               line: 1,
                               column: 8)
            ],
            macros: macros)
    }

    func testAVariablePatternIsAnError() {
        assertMacroExpansion(
            """
            #Given(pattern) { }
            """,
            expandedSource: """
            #Given(pattern) { }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The step definition's pattern must be a string literal or a regex literal, so it can be checked when it compiles.",
                               line: 1,
                               column: 8)
            ],
            macros: macros)
    }

    /// The message the macro reports for a pattern that does not parse.
    private func problemMessage(_ pattern: String) -> String {
        do {
            _ = try StepPattern(pattern)
            return "expected an error"
        } catch let problem as StepPattern.Problem {
            return problem.message
        } catch {
            return "\(error)"
        }
    }
}
#endif
