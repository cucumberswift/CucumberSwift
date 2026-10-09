//
//  RegexLiteralConversionTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// A regex literal stays as it is, and its capture groups become the closure's arguments, each with its type in
/// the regex's `Output`: `Substring`, or `Substring?` for a group that may not take part in the match.
final class RegexLiteralConversionTests: ConverterTestCase {
    func testKeepsTheRegexLiteralAndGivesEachCaptureGroupItsType() {
        assertConverts(#"""
            Given(#/^I have (\d+) cukes in (\w+)$/#) { match, _ in
                let count = match.1
                let box: Substring = match.output.2
                use(count, box)
            }
            """#, to: #"""
            #Given(#/^I have (\d+) cukes in (\w+)$/#) { (count: Substring, box: Substring) in
                use(count, box)
            }
            """#)
    }

    func testAPatternWithoutAnchorsStaysAsItIs() {
        // A regex literal matches the whole step, with or without the anchors, and so does the macro's.
        assertConverts(#"""
            Given(#/I say "(\w+)"/#) { match, _ in
                let word = match.1
                use(word)
            }
            """#, to: #"""
            #Given(#/I say "(\w+)"/#) { (word: Substring) in
                use(word)
            }
            """#)
    }

    func testABareSlashRegexLiteral() {
        assertConverts(#"""
            Given(/^I have (\d+) cukes$/) { match, _ in
                let count = match.1
                use(count)
            }
            """#, to: #"""
            #Given(/^I have (\d+) cukes$/) { (count: Substring) in
                use(count)
            }
            """#)
    }

    func testReadsCaptureGroupsInAnyOrderAndLeavesOutTheOnesItDoesNotRead() {
        assertConverts(#"""
            Given(#/^(\d+) of (\d+) of (\d+)$/#) { match, _ in
                let last = match.3
                let first = match.1
                use(first, last)
            }
            """#, to: #"""
            #Given(#/^(\d+) of (\d+) of (\d+)$/#) { (first: Substring, _: Substring, last: Substring) in
                use(first, last)
            }
            """#)
    }

    func testAGroupThatMayNotTakePartInTheMatchIsOptional() {
        assertConverts(#"""
            When(#/^I take (\d+) cukes?( slowly)?$/#) { match, _ in
                let count = match.1
                let slowly: Substring? = match.2
                use(count, slowly)
            }
            """#, to: #"""
            #When(#/^I take (\d+) cukes?( slowly)?$/#) { (count: Substring, slowly: Substring?) in
                use(count, slowly)
            }
            """#)
        assertConverts(#"""
            When(#/^I (?:eat (\d+)|drink (\d+)) cukes$/#) { match, _ in
                let eaten = match.1
                use(eaten)
            }
            """#, to: #"""
            #When(#/^I (?:eat (\d+)|drink (\d+)) cukes$/#) { (eaten: Substring?, _: Substring?) in
                use(eaten)
            }
            """#)
    }

    func testReadsANamedGroupByItsNameOrItsNumber() {
        assertConverts(#"""
            Given(#/^(\d+) cukes from (?<city>\w+) in (?<box>\w+)$/#) { match, _ in
                let count = match.1
                let city = match.city
                let container = match.output.box
                use(count, city, container)
            }
            """#, to: #"""
            #Given(#/^(\d+) cukes from (?<city>\w+) in (?<box>\w+)$/#) { (count: Substring, city: Substring, container: Substring) in
                use(count, city, container)
            }
            """#)
        assertConverts(#"""
            Given(#/^from (?<city>\w+)$/#) { match, _ in
                let city = match.1
                use(city)
            }
            """#, to: #"""
            #Given(#/^from (?<city>\w+)$/#) { (city: Substring) in
                use(city)
            }
            """#)
    }

    /// Syntax that a string regular expression doesn't read alike, which the macros take as Swift's `Regex` does.
    func testKeepsSyntaxOnlySwiftsRegexReads() {
        let cases: [(pattern: String, arguments: String)] = [
            (#"(?i)I (\w+)"#, "(word: Substring)"),
            (#"I (\p{L}+)"#, "(word: Substring)"),
            (#"I ((\d)+)"#, "(word: Substring, _: Substring)"),
            (#"I (\w)\1"#, "(word: Substring)"),
            (#"I ([[:alpha:]]+)"#, "(word: Substring)"),
            (#"I ([a-z--[b]]+)"#, "(word: Substring)")
        ]
        for item in cases {
            assertConverts("""
                Given(#/\(item.pattern)/#) { match, _ in
                    let word = match.1
                    use(word)
                }
                """, to: """
                #Given(#/\(item.pattern)/#) { \(item.arguments) in
                    use(word)
                }
                """)
        }
    }

    func testAMultiLineRegexLiteral() {
        assertConverts(##"""
            Given(#/
                ^ I \s have \s (\d+) \s cukes $   # extended syntax
            /#) { match, _ in
                let count = match.1
                use(count)
            }
            """##, to: ##"""
            #Given(#/
                ^ I \s have \s (\d+) \s cukes $   # extended syntax
            /#) { (count: Substring) in
                use(count)
            }
            """##)
    }

    func testAPatternWithoutCaptureGroups() {
        assertConverts(#"""
            When(#/^nothing happens$/#) { _, _ in
                use()
            }
            """#, to: #"""
            #When(#/^nothing happens$/#) {
                use()
            }
            """#)
    }

    func testKeepsTheStepAndEffects() {
        assertConverts(#"""
            Then(#/^I see (\w+)$/#) { [weak self] (match, step) async throws in
                let word = match.1
                try await self?.check(word, step)
            }
            """#, to: #"""
            #Then(#/^I see (\w+)$/#) { [weak self] (word: Substring, step: Step) async throws in
                try await self?.check(word, step)
            }
            """#)
    }
}
#endif
