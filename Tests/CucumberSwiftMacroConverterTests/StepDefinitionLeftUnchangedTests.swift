//
//  StepDefinitionLeftUnchangedTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

final class StepDefinitionLeftUnchangedTests: ConverterTestCase {
    // MARK: Left unchanged, with the reason

    func testLeavesAStepDefinitionThatPassesMatchOn() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                helper(match, count)
            }
            """, because: "passes match on to other code")
    }

    func testLeavesAStepDefinitionThatReadsAllParameters() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let counts = try match.allParameters(\\.int)
                use(counts)
            }
            """, because: "match.allParameters")
    }

    func testLeavesARegexLiteralWhoseCaptureGroupsItCannotRead() {
        // Syntax that changes what captures or how groups are numbered, which only Swift works out.
        let patterns = [
            "#/(?x) I (\\w+)/#",
            "#/(?n)I (\\w+)/#",
            "#/I (?|(a)|(b))/#",
            "#/I (\\u{1F600})/#"
        ]
        for pattern in patterns {
            assertLeftUnchanged("""
                Given(\(pattern)) { match, _ in
                    let word = match.1
                    use(word)
                }
                """, because: "its regex literal has syntax the command doesn't read")
        }
    }

    func testLeavesARegexLiteralThatDeclaresACaptureWithAnotherType() {
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                let count: String = String(match.1)
                use(count)
            }
            """, because: "it reads match after other code")
        assertLeftUnchanged("""
            Given(#/^I have (\\d+)? cukes$/#) { match, _ in
                let count: Substring = match.1
                use(count)
            }
            """, because: "it declares capture group 1 as Substring, and the macro gives it as Substring?")
    }

    func testLeavesARegexLiteralThatReadsItsMatchInAnotherWay() {
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                use(match)
            }
            """, because: "it passes match on to other code")
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                use(match.output)
            }
            """, because: "after other code, or in another form")
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                let count = match.1
                use(count, match.0)
            }
            """, because: "after other code, or in another form")
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                let count = match.2
                use(count)
            }
            """, because: "capture group 2, and its pattern has 1")
        assertLeftUnchanged("""
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                let count = match.1
                let again = match.1
                use(count, again)
            }
            """, because: "capture group 1 more than once")
    }

    func testLeavesTheDeprecatedStringArrayClosure() {
        assertLeftUnchanged("""
            Given("^I have (\\\\d+) cukes$") { (matches: [String], _) in
                use(matches[1])
            }
            """, because: "deprecated [String] closure")
    }

    func testLeavesTheStringArrayClosureWithoutTypes() {
        assertLeftUnchanged("""
            Given("^I have (\\\\d+) cukes$") { matches, _ in
                use(matches[1])
            }
            """, because: "deprecated [String] closure")
    }

    func testLeavesAPatternThatIsNotAStringLiteral() {
        assertLeftUnchanged("""
            Given(pattern) { _, _ in
                use()
            }
            """, because: "isn't a string literal")
        assertLeftUnchanged("""
            Given(pattern as CucumberExpression) { _, _ in
                use()
            }
            """, because: "isn't a string literal")
        assertLeftUnchanged("""
            Given("I have \\(count) cukes") { _, _ in
                use()
            }
            """, because: "isn't a string literal")
    }

    func testLeavesAPatternTheMacroWouldReject() {
        assertLeftUnchanged("""
            Given("I have {int cukes") { _, _ in
                use()
            }
            """, because: "a mistake the macro would report")
    }

    func testLeavesAFunctionPassedInPlaceOfAClosure() {
        assertLeftUnchanged("""
            Given("I have {int} cukes", callback: addCukes)
            """, because: "passes a function")
    }

    func testLeavesASelectorStepDefinition() {
        assertLeftUnchanged("""
            Given("I have {int} cukes", class: Steps.self, selector: #selector(Steps.addCukes))
            """, because: "selector")
    }

    func testLeavesAClosureThatUsesAnonymousArguments() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") {
                use($0, $1)
            }
            """, because: "$0 and $1")
    }

    func testLeavesAStepDefinitionThatReadsInADifferentOrder() {
        assertLeftUnchanged("""
            Given("I have {int} cukes in my {string}") { match, _ in
                let container = try match.first(\\.string)
                let count = try match.first(\\.int)
                use(count, container)
            }
            """, because: "different order")
    }

    func testLeavesAReadAfterOtherCode() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                prepare()
                let count = try match.first(\\.int)
                use(count)
            }
            """, because: "after other code")
    }

    func testLeavesAReadThatDoesNotMatchTheMacrosExpansion() {
        assertLeftUnchanged("""
            Given("I have {int} cukes and {int} tomatoes") { match, _ in
                let cukes = try match.first(\\.int)
                use(cukes)
            }
            """, because: "by position")
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let cukes = match[\\.int, index: 0]
                use(cukes)
            }
            """, because: "first(\\.int)")
    }

    func testLeavesAReadWithAnotherType() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let count: Double = try match.first(\\.int)
                use(count)
            }
            """, because: "declares {int} as Double")
    }

    func testLeavesACustomParameterTheClosureDoesNotRead() {
        assertLeftUnchanged("""
            Given("I have a {color} cuke") { match, _ in
                use(match)
            }
            """, because: "match on")
        assertLeftUnchanged("""
            Given("I have a {color} cuke") { _, _ in
                use()
            }
            """, because: "custom parameter type")
    }

    func testLeavesAClosureThatUsesTheNameTheExpansionGivesMatch() {
        // The parameter is called match, so the expansion's own Match is match2.
        assertLeftUnchanged("""
            Given("I have {string} cukes") { m, _ in
                let match = try m.first(\\.string)
                use(match, match2)
            }
            """, because: "hide behind its own `match2`")
    }

    func testLeavesAFileThatImportsNeitherRunner() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """,
            because: "neither CucumberSwift nor CucumberSwiftTesting",
            header: "import XCTest\n")
    }

    func testLeavesAFileThatImportsBothRunners() {
        assertLeftUnchanged("""
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """,
            because: "both CucumberSwift and CucumberSwiftTesting",
            header: "import CucumberSwift\nimport CucumberSwiftTesting\n")
    }

    func testIgnoresCallsThatAreNotStepDefinitions() {
        let source = header + """
            Given(I: "have cukes") { _ in }
            let step = Given
            Given("no closure")
            """
        let result = convert(source: source)
        XCTAssertEqual(result.source, source)
        XCTAssertEqual(result.converted, [])
        XCTAssertEqual(result.leftUnchanged, [])
    }

    func testReportsEachStepDefinitionWithItsLine() {
        let result = convert("""
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            When("I eat {int} cukes") { match, _ in
                eat(match)
            }
            """)
        XCTAssertEqual(result.converted, [.init(line: 3, stepDefinition: "Given(\"I have {int} cukes\")", reason: nil)])
        XCTAssertEqual(result.leftUnchanged.map(\.line), [7])
        XCTAssertEqual(result.leftUnchanged.map(\.stepDefinition), ["When(\"I eat {int} cukes\")"])
    }
}
#endif
