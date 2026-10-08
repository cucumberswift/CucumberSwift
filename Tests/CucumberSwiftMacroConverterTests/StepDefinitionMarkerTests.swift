//
//  StepDefinitionMarkerTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// A step definition the converter leaves gets a `#warning`, so the compiler points to it.
final class StepDefinitionMarkerTests: ConverterTestCase {
    func testMarksAStepDefinitionItLeavesAtItsIndentationBelowItsComments() {
        let result = convert("""
            func setup() {
                // Adds cukes.
                Given("I have {int} cukes") { match, _ in
                    helper(match)
                }
            }
            """)
        XCTAssertEqual(result.source, header + """
            func setup() {
                // Adds cukes.
                #warning("Convert to Gherkin Macros by hand: it passes match on to other code")
                Given("I have {int} cukes") { match, _ in
                    helper(match)
                }
            }
            """)
    }

    func testMarksAStepDefinitionAtTheTopOfAFile() {
        let result = convert("""
            Given("I have {int} cukes") { match, _ in
                helper(match)
            }
            """)
        XCTAssertEqual(result.source, header + """
            #warning("Convert to Gherkin Macros by hand: it passes match on to other code")
            Given("I have {int} cukes") { match, _ in
                helper(match)
            }
            """)
    }

    func testMarksEachStepDefinitionItLeavesAndStillConvertsTheOthers() {
        let result = convert("""
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            When("I eat {int} cukes") { match, _ in
                eat(match)
            }
            Then("I have \\(left) left") { _, _ in
                use()
            }
            """)
        XCTAssertEqual(result.converted.count, 1)
        XCTAssertEqual(result.leftUnchanged.count, 2)
        XCTAssertEqual(result.source.components(separatedBy: Self.marker).count - 1, 2)
        XCTAssertTrue(result.source.contains("#Given(\"I have {int} cukes\")"))
    }

    func testRunningItAgainAddsNoSecondMarkerAndChangesNothing() {
        let once = convert("""
            Given("I have {int} cukes") { match, _ in
                helper(match)
            }
            """)
        let twice = convert(source: once.source)
        XCTAssertEqual(twice.source, once.source)
        XCTAssertEqual(twice.leftUnchanged.count, 1)
        XCTAssertEqual(once.source.components(separatedBy: Self.marker).count - 1, 1)
    }

    func testWritesAReasonThatHasQuotesAndBackslashesAsAStringLiteral() {
        let result = convert("""
            Given("I have {int} cukes and {int} tomatoes") { match, _ in
                let cukes = try match.first(\\.int)
                use(cukes)
            }
            """)
        // The reason names `first(\\.int)`, whose backslash the marker's string has to escape.
        XCTAssertTrue(result.source.contains("first(\\\\.int)"), result.source)
        XCTAssertEqual(result.leftUnchanged.count, 1)
    }

    func testDoesNotMarkACallThatIsNotAStatement() {
        assertLeftUnchanged("""
            let step = Given("I have {int} cukes") { match, _ in
                helper(match)
            }
            """,
            because: "it passes match on to other code",
            marked: false)
    }

    func testDoesNotMarkACallWhoseKeywordIsShadowed() {
        assertLeftUnchanged("""
            func Given(_ text: String, _ body: (Match, Step) throws -> Void) {}
            Given("I have {int} cukes") { match, _ in
                helper(match)
            }
            """,
            because: "declared in this file is in scope",
            marked: false)
    }
}
#endif
