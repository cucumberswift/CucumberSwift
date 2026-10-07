//
//  StepDefinitionMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

final class StepDefinitionMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Given": StepDefinitionMacro.self,
        "When": StepDefinitionMacro.self,
        "Then": StepDefinitionMacro.self,
        "MatchAll": StepDefinitionMacro.self,
        "ES_Dado": StepDefinitionMacro.self
    ]

    func testExpandsToThePlainStepDefinition() {
        assertMacroExpansion(
            """
            #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
                print(count, container)
            }
            """,
            expandedSource: """
            Given("I have {int} cukes in my {string}" as CucumberExpression) { match, _ in
                let count: Int = try match.first(\\.int)
                let container: String = try match.first(\\.string)
                print(count, container)
            }
            """,
            macros: macros)
    }

    func testALocalizedMacroExpandsToItsOwnStepType() {
        assertMacroExpansion(
            """
            #ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
                print(cantidad)
            }
            """,
            expandedSource: """
            ES_Dado("tengo {int} pepinos" as CucumberExpression) { match, _ in
                let cantidad: Int = try match.first(\\.int)
                print(cantidad)
            }
            """,
            macros: macros)
    }

    func testRepeatedParameterTypesAreNumberedWithinTheirType() {
        assertMacroExpansion(
            """
            #When("I move {int} cukes from {string} to {int}") { (count: Int, from: String, to: Int) in
                print(count, from, to)
            }
            """,
            expandedSource: """
            When("I move {int} cukes from {string} to {int}" as CucumberExpression) { match, _ in
                let count: Int = match[\\.int, index: 0]
                let from: String = try match.first(\\.string)
                let to: Int = match[\\.int, index: 1]
                print(count, from, to)
            }
            """,
            macros: macros)
    }

    func testPassesTheStepAndKeepsEffectsAndCaptures() {
        assertMacroExpansion(
            """
            #Then("I see {word}") { [weak self] (word: String, step: Step) async throws in
                try await self?.check(word, step)
            }
            """,
            expandedSource: """
            { () -> Then in
                let callback: @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void = { [weak self] (match, step) async throws in
                    let word: String = try match.first(\\.word)
                    try await self?.check(word, step)
                }
                return Then("I see {word}" as CucumberExpression, callback: callback)
            }()
            """,
            macros: macros)
    }

    func testAClosureWithACaptureListIsTypedBeforeItIsPassed() {
        // Swift fails to type-check a closure with a capture list passed straight to the step
        // definition in an expansion, so the expansion gives it its type first.
        assertMacroExpansion(
            """
            #Given("I have {int} cukes") { [basket] (count: Int) in
                basket.add(count)
            }
            """,
            expandedSource: """
            { () -> Given in
                let callback: (CucumberSwiftExpressions.Match, Step) throws -> Void = { [basket] match, _ in
                    let count: Int = try match.first(\\.int)
                    basket.add(count)
                }
                return Given("I have {int} cukes" as CucumberExpression, callback: callback)
            }()
            """,
            macros: macros)
    }

    func testANestedCaptureListIsTypedBeforeItIsPassed() {
        assertMacroExpansion(
            """
            #When("I eat {int} cukes") { (count: Int) in
                let callback = 1
                queue.async { [count] in
                    eat(count, callback)
                }
            }
            """,
            expandedSource: """
            { () -> When in
                let callback2: (CucumberSwiftExpressions.Match, Step) throws -> Void = { match, _ in
                    let count: Int = try match.first(\\.int)
                    let callback = 1
                    queue.async { [count] in
                        eat(count, callback)
                    }
                }
                return When("I eat {int} cukes" as CucumberExpression, callback: callback2)
            }()
            """,
            macros: macros)
    }

    func testAnAsyncClosureThatDoesNotSayThrowsStillThrows() {
        // The arguments are read with `try`, so the expansion needs `throws` even when the closure
        // only says `async`.
        assertMacroExpansion(
            """
            #When("I wait for {int} cukes") { (count: Int) async in
                await wait(count)
            }
            """,
            expandedSource: """
            When("I wait for {int} cukes" as CucumberExpression) { (match, _) async throws in
                let count: Int = try match.first(\\.int)
                await wait(count)
            }
            """,
            macros: macros)
    }

    func testCustomParameterIsReadByItsKeyPath() {
        assertMacroExpansion(
            """
            #Given("a {color} cuke") { (color: Color) in
                print(color)
            }
            """,
            expandedSource: """
            Given("a {color} cuke" as CucumberExpression) { match, _ in
                let color: Color = try match.first(\\.color)
                print(color)
            }
            """,
            macros: macros)
    }

    func testRegularExpressionCaptureGroupsAreAnonymousStrings() {
        assertMacroExpansion(
            #"""
            #MatchAll("^I have (\\d+) cukes$") { (count: String) in
                print(count)
            }
            """#,
            expandedSource: #"""
            MatchAll("^I have (\\d+) cukes$" as CucumberExpression) { match, _ in
                let count: String = try match.first(\.anonymous)
                print(count)
            }
            """#,
            macros: macros)
    }

    func testNestedCaptureGroupsAreOneArgument() {
        // Only top-level groups are arguments, as at run time.
        assertMacroExpansion(
            #"""
            #Then("^I see ((\\d+) red) cukes$") { (count: String) in
                print(count)
            }
            """#,
            expandedSource: #"""
            Then("^I see ((\\d+) red) cukes$" as CucumberExpression) { match, _ in
                let count: String = try match.first(\.anonymous)
                print(count)
            }
            """#,
            macros: macros)
    }

    func testAParameterNamedMatchDoesNotHideTheMatch() {
        assertMacroExpansion(
            """
            #Given("{word}") { (match: String) in
                print(match)
            }
            """,
            expandedSource: """
            Given("{word}" as CucumberExpression) { match2, _ in
                let match: String = try match2.first(\\.word)
                print(match)
            }
            """,
            macros: macros)
    }
}
#endif
