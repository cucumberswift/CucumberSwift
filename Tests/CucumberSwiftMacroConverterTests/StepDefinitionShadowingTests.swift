//
//  StepDefinitionShadowingTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// A call is not a step definition when something in the file called `Given`, `When` and so on is in scope.
final class StepDefinitionShadowingTests: ConverterTestCase {
    func testLeavesACallToAFunctionThatShadowsTheKeyword() {
        assertLeftUnchanged("""
            func Given(_ text: String, _ body: (Match, Step) throws -> Void) {}

            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """,
            because: "a `Given` declared in this file is in scope",
            marked: false)
        assertLeftUnchanged("""
            func setup() {
                func When(_ text: String, _ body: (Match, Step) throws -> Void) {}
                When("I have {int} cukes") { match, _ in
                    let count = try match.first(\\.int)
                    use(count)
                }
            }
            """,
            because: "a `When` declared in this file is in scope",
            marked: false)
        assertLeftUnchanged("""
            final class Steps {
                func Then(_ text: String, _ body: (Match, Step) throws -> Void) {}
                func setup() {
                    Then("I have {int} cukes") { match, _ in
                        let count = try match.first(\\.int)
                        use(count)
                    }
                }
            }
            """,
            because: "a `Then` declared in this file is in scope",
            marked: false)
    }

    func testConvertsACallWhenAFunctionWithAnotherNameIsDeclared() {
        let result = convert("""
            func helper() {}

            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """)
        XCTAssertEqual(result.leftUnchanged, [])
        XCTAssertEqual(result.converted.count, 1)
    }

    func testLeavesACallToAParameterThatShadowsTheKeyword() {
        assertLeftUnchanged("""
            func setup(Given: (String, (Match, Step) throws -> Void) -> Void) {
                Given("I have {int} cukes") { match, _ in
                    let count = try match.first(\\.int)
                    use(count)
                }
            }
            """,
            because: "a `Given` declared in this file is in scope",
            marked: false)
        assertLeftUnchanged("""
            let register = { (When: (String, (Match, Step) throws -> Void) -> Void) in
                When("I have {int} cukes") { match, _ in
                    let count = try match.first(\\.int)
                    use(count)
                }
            }
            """,
            because: "a `When` declared in this file is in scope",
            marked: false)
        assertLeftUnchanged("""
            final class Steps {
                init(Then: (String, (Match, Step) throws -> Void) -> Void) {
                    Then("I have {int} cukes") { match, _ in
                        let count = try match.first(\\.int)
                        use(count)
                    }
                }
            }
            """,
            because: "a `Then` declared in this file is in scope",
            marked: false)
    }
}
#endif
