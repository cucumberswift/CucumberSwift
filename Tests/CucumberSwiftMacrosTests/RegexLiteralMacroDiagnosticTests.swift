//
//  RegexLiteralMacroDiagnosticTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// The errors the step definition macros report for a regex literal, and what applying each fix-it produces.
/// What the macros leave to the compiler expands as usual.
final class RegexLiteralMacroDiagnosticTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["Given": StepDefinitionMacro.self]

    func testTooFewArgumentsOffersOnePerCapture() {
        assertMacroExpansion(
            #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)( today)?$/#) { (count: Substring) in
                print(count)
            }
            """#,
            expandedSource: #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)( today)?$/#) { (count: Substring) in
                print(count)
            }
            """#,
            diagnostics: [
                DiagnosticSpec(message: "The pattern has 3 capture groups, but the closure takes 1 argument. "
                                   + "Give the closure one argument per capture group, in order, optionally followed by the Step.",
                               line: 1,
                               column: 69,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (count: Substring, container: Substring, group: Substring?)")])
            ],
            macros: macros,
            applyFixIts: ["Change the closure's parameters to (count: Substring, container: Substring, group: Substring?)"],
            fixedSource: #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)( today)?$/#) { (count: Substring, container: Substring, group: Substring?) in
                print(count)
            }
            """#)
    }

    func testEveryNestedGroupIsAnArgument() {
        // Unlike a regular expression in a string, a regex literal's output has every group, nested or not.
        assertMacroExpansion(
            #"""
            #Given(#/^I see ((\d+) red) cukes$/#) { (count: Substring) in
                print(count)
            }
            """#,
            expandedSource: #"""
            #Given(#/^I see ((\d+) red) cukes$/#) { (count: Substring) in
                print(count)
            }
            """#,
            diagnostics: [
                DiagnosticSpec(message: "The pattern has 2 capture groups, but the closure takes 1 argument. "
                                   + "Give the closure one argument per capture group, in order, optionally followed by the Step.",
                               line: 1,
                               column: 41,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (count: Substring, group: Substring)")])
            ],
            macros: macros)
    }

    func testAWrongTypeOffersTheCapturesType() {
        assertMacroExpansion(
            #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)?$/#) { (count: Int, container: String) in
                print(count, container)
            }
            """#,
            expandedSource: #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)?$/#) { (count: Int, container: String) in
                print(count, container)
            }
            """#,
            diagnostics: [
                DiagnosticSpec(message: "A capture group gives Substring, but 'count' is declared as Int.",
                               line: 1,
                               column: 69,
                               fixIts: [FixItSpec(message: "Change the type to Substring")]),
                DiagnosticSpec(message: "The capture group 'container' gives Substring?, but 'container' is declared as String.",
                               line: 1,
                               column: 85,
                               fixIts: [FixItSpec(message: "Change the type to Substring?")])
            ],
            macros: macros,
            applyFixIts: ["Change the type to Substring", "Change the type to Substring?"],
            fixedSource: #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)?$/#) { (count: Substring, container: Substring?) in
                print(count, container)
            }
            """#)
    }

    func testWhetherACaptureIsOptionalIsLeftToTheCompiler() {
        // The expansion's type annotation fails to compile if `Substring` and `Substring?` are swapped.
        assertMacroExpansion(
            #"""
            #Given(#/^I have (\d+)?$/#) { (count: Swift.Substring) in
                print(count)
            }
            """#,
            expandedSource: #"""
            Given(#/^I have (\d+)?$/#) { match, _ in
                let (_, count): (_, Swift.Substring) = match.output
                print(count)
            }
            """#,
            macros: macros)
    }

    func testAWrongNumberOfArgumentsForARegexTheMacroCannotReadIsLeftToTheCompiler() {
        assertMacroExpansion(
            #"""
            #Given(#/^(?'count'\d+) (\w+)$/#) { (count: Int) in
                print(count)
            }
            """#,
            expandedSource: #"""
            Given(#/^(?'count'\d+) (\w+)$/#) { match, _ in
                let (_, count): (_, Int) = match.output
                print(count)
            }
            """#,
            macros: macros)
    }

    func testARegexVariableIsAnError() {
        assertMacroExpansion(
            """
            #Given(regex) { (count: Substring) in
                print(count)
            }
            """,
            expandedSource: """
            #Given(regex) { (count: Substring) in
                print(count)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The step definition's pattern must be a string literal or a regex literal, so it can be checked when it compiles.",
                               line: 1,
                               column: 8)
            ],
            macros: macros)
    }
}
#endif
