//
//  RegexLiteralMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// What the step definition macros with a regex literal expand to. The compiler checks the arguments
/// against the regex's output in the expansion; the macros package fixture compiles and runs these forms.
final class RegexLiteralMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Given": StepDefinitionMacro.self,
        "When": StepDefinitionMacro.self,
        "Then": StepDefinitionMacro.self,
        "ES_Dado": StepDefinitionMacro.self
    ]

    func testReadsTheArgumentsFromTheWholeOutput() {
        assertMacroExpansion(
            #"""
            #Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { (count: Substring, container: Substring) in
                print(count, container)
            }
            """#,
            expandedSource: #"""
            Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { match, _ in
                let (_, count, container): (_, Substring, Substring) = match.output
                print(count, container)
            }
            """#,
            macros: macros)
    }

    func testABareSlashLiteralAndALocalizedMacro() {
        assertMacroExpansion(
            #"""
            #ES_Dado(/^tengo (\d+) pepinos$/) { (cantidad: Substring) in
                print(cantidad)
            }
            """#,
            expandedSource: #"""
            ES_Dado(/^tengo (\d+) pepinos$/) { match, _ in
                let (_, cantidad): (_, Substring) = match.output
                print(cantidad)
            }
            """#,
            macros: macros)
    }

    func testPassesTheStepAndKeepsEffects() {
        assertMacroExpansion(
            #"""
            #Then(#/^I see (\w+)( again)?$/#) { (word: Substring, again: Substring?, step: Step) async throws in
                try await check(word, again, step)
            }
            """#,
            expandedSource: #"""
            Then(#/^I see (\w+)( again)?$/#) { (match, step) async throws in
                let (_, word, again): (_, Substring, Substring?) = match.output
                try await check(word, again, step)
            }
            """#,
            macros: macros)
    }

    func testAnArgumentWithoutANameStillCounts() {
        assertMacroExpansion(
            #"""
            #When(#/^I eat (\d+) (\w+)$/#) { (_: Substring, kind: Substring) in
                print(kind)
            }
            """#,
            expandedSource: #"""
            When(#/^I eat (\d+) (\w+)$/#) { match, _ in
                let (_, _, kind): (_, Substring, Substring) = match.output
                print(kind)
            }
            """#,
            macros: macros)
    }

    func testARegexWithoutCapturesReadsNothing() {
        assertMacroExpansion(
            """
            #When(#/^nothing happens$/#) {
                print("nothing")
            }
            #When(#/^nothing happens to the step$/#) { (step: Step) in
                print(step)
            }
            """,
            expandedSource: """
            When(#/^nothing happens$/#) { _, _ in
                print("nothing")
            }
            When(#/^nothing happens to the step$/#) { _, step in
                print(step)
            }
            """,
            macros: macros)
    }

    func testARegexTheMacroCannotReadIsLeftToTheCompiler() {
        // ICU can't read (?'name'…), so the macro doesn't trust its own count. The expansion still reads
        // the whole output, and a closure without arguments checks that there is nothing to read.
        assertMacroExpansion(
            #"""
            #Given(#/^I have (?'count'\d+) cukes$/#) { (count: Substring, step: Step) in
                print(count, step)
            }
            #Given(#/^I have (?'count'\d+) cukes$/#) {
                print("none")
            }
            """#,
            expandedSource: #"""
            Given(#/^I have (?'count'\d+) cukes$/#) { match, step in
                let (_, count): (_, Substring) = match.output
                print(count, step)
            }
            Given(#/^I have (?'count'\d+) cukes$/#) { match, _ in
                let _: Substring = match.output
                print("none")
            }
            """#,
            macros: macros)
    }

    func testAMultiLineLiteralIsReadWithExtendedSyntax() {
        assertMacroExpansion(
            #"""
            #Given(#/
                ^ I \s have \s (\d+) # the count (of cukes)
                \s cukes $
                /#) { (count: Substring) in
                print(count)
            }
            """#,
            expandedSource: #"""
            Given(#/
                ^ I \s have \s (\d+) # the count (of cukes)
                \s cukes $
                /#) { match, _ in
                let (_, count): (_, Substring) = match.output
                print(count)
            }
            """#,
            macros: macros)
    }

    // The expansions' function declarations are longer than a line may be.
    // swiftlint:disable line_length
    func testAClosureWithACaptureListIsTypedByAGenericFunction() {
        // As for a string pattern, Swift fails to type-check a closure with a capture list passed straight
        // to the step definition in an expansion. Its type names the regex's output, so a generic function
        // gives it the type.
        assertMacroExpansion(
            #"""
            #Given(#/^I have (\d+) cukes$/#) { [basket] (count: Substring) in
                basket.add(count)
            }
            #When(#/^I eat (\d+) cukes$/#) { [weak self] (count: Substring) in
                try self?.eat(count)
            }
            #Then(#/^I wait for (\d+) cukes$/#) { [weak self] (count: Substring, step: Step) in
                await self?.wait(count, step)
            }
            """#,
            expandedSource: #"""
            { () -> Given in
                func typedCallback<Output>(_: Regex<Output>, _ callback: @escaping (Regex<Output>.Match, Step) -> Void) -> (Regex<Output>.Match, Step) -> Void {
                    callback
                }
                let regex = #/^I have (\d+) cukes$/#
                let callback = typedCallback(regex) { [basket] match, _ in
                    let (_, count): (_, Substring) = match.output
                    basket.add(count)
                }
                return Given(regex, callback: callback)
            }()
            { () -> When in
                func typedCallback<Output>(_: Regex<Output>, _ callback: @escaping (Regex<Output>.Match, Step) throws -> Void) -> (Regex<Output>.Match, Step) throws -> Void {
                    callback
                }
                let regex = #/^I eat (\d+) cukes$/#
                let callback = typedCallback(regex) { [weak self] match, _ in
                    let (_, count): (_, Substring) = match.output
                    try self?.eat(count)
                }
                return When(regex, callback: callback)
            }()
            { () -> Then in
                func typedCallback<Output>(_: Regex<Output>, _ callback: @escaping @MainActor (Regex<Output>.Match, Step) async throws -> Void) -> @MainActor (Regex<Output>.Match, Step) async throws -> Void {
                    callback
                }
                let regex = #/^I wait for (\d+) cukes$/#
                let callback = typedCallback(regex) { [weak self] match, step in
                    let (_, count): (_, Substring) = match.output
                    await self?.wait(count, step)
                }
                return Then(regex, callback: callback)
            }()
            """#,
            macros: macros)
    }

    func testTheGeneratedNamesAvoidTheClosuresOwn() {
        assertMacroExpansion(
            #"""
            #Given(#/^(\d+)$/#) { [regex] (callback: Substring) in
                print(regex, callback)
            }
            """#,
            expandedSource: #"""
            { () -> Given in
                func typedCallback<Output>(_: Regex<Output>, _ callback: @escaping (Regex<Output>.Match, Step) -> Void) -> (Regex<Output>.Match, Step) -> Void {
                    callback
                }
                let regex2 = #/^(\d+)$/#
                let callback2 = typedCallback(regex2) { [regex] match, _ in
                    let (_, callback): (_, Substring) = match.output
                    print(regex, callback)
                }
                return Given(regex2, callback: callback2)
            }()
            """#,
            macros: macros)
    }
    // swiftlint:enable line_length
}
#endif
