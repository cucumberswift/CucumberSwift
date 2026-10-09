//
//  RegexLiteralConversionTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// A regex literal becomes the string regular expression the macros take, with its capture groups as `String`.
final class RegexLiteralConversionTests: ConverterTestCase {
    func testConvertsARegexLiteralToAStringRegularExpression() {
        assertConverts(#"""
            Given(#/^I have (\d+) cukes in (\w+)$/#) { match, _ in
                let count = match.1
                let box: Substring = match.output.2
                use(count, box)
            }
            """#, to: #"""
            #Given("^I have (\\d+) cukes in (\\w+)$") { (count: String, box: String) in
                use(count, box)
            }
            """#)
    }

    func testAnchorsAPatternThatDoesNotStartAndEndWithAnchors() {
        // A regex literal has to match the whole step, and a string regular expression has to say so.
        assertConverts(#"""
            Given(#/I have (\d+) cukes/#) { match, _ in
                let count = match.1
                use(count)
            }
            """#, to: #"""
            #Given("^(?:I have (\\d+) cukes)$") { (count: String) in
                use(count)
            }
            """#)
        assertConverts(#"""
            Given(#/^I have (\d+) cukes/#) { match, _ in
                let count = match.1
                use(count)
            }
            """#, to: #"""
            #Given("^(?:^I have (\\d+) cukes)$") { (count: String) in
                use(count)
            }
            """#)
        assertConverts(#"""
            Given(#/cost \$/#) { _, _ in
                use()
            }
            """#, to: #"""
            #Given("^(?:cost \\$)$") {
                use()
            }
            """#)
    }

    func testEscapesQuotesInThePattern() {
        assertConverts(#"""
            Given(#/I say "(\w+)"/#) { match, _ in
                let word = match.1
                use(word)
            }
            """#, to: #"""
            #Given("^(?:I say \"(\\w+)\")$") { (word: String) in
                use(word)
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
            #Given("^(\\d+) of (\\d+) of (\\d+)$") { (first: String, _: String, last: String) in
                use(first, last)
            }
            """#)
    }

    func testAllowsANonCapturingGroupAroundACaptureGroup() {
        assertConverts(#"""
            Given(#/^I have (?:about (\d+)|no) cukes$/#) { match, _ in
                let count = match.1
                use(count)
            }
            """#, to: #"""
            #Given("^I have (?:about (\\d+)|no) cukes$") { (count: String) in
                use(count)
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
            #Then("^I see (\\w+)$") { [weak self] (word: String, step: Step) async throws in
                try await self?.check(word, step)
            }
            """#)
    }
}
#endif
