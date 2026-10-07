//
//  StepDefinitionConverterTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

final class StepDefinitionConverterTests: ConverterTestCase {
    // MARK: Converted

    func testConvertsTheStepDefinitionInTheIssue() {
        assertConverts("""
            Given("I have {int} cukes in my {string}") { match, _ in
                let count = try match.first(\\.int)
                let container = try match.first(\\.string)
                basket.add(count, to: container)
            }
            """, to: """
            #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
                basket.add(count, to: container)
            }
            """)
    }

    func testKeepsDeclaredTypesAndTheStep() {
        assertConverts("""
            When("I eat {int} cukes") { m, step in
                let count: Int = try m.first(\\.int)
                XCTAssertNotNil(step.dataTable)
                basket.eat(count)
            }
            """, to: """
            #When("I eat {int} cukes") { (count: Int, step: Step) in
                XCTAssertNotNil(step.dataTable)
                basket.eat(count)
            }
            """)
    }

    func testReadsAParameterTypeThePatternHasMoreThanOnceByPosition() {
        assertConverts("""
            Then("I have {int} cukes and {int} tomatoes") { match, _ in
                let cukes = match[\\.int, index: 0]
                let tomatoes = match[\\.int, index: 1]
                XCTAssertEqual(cukes + tomatoes, basket.count)
            }
            """, to: """
            #Then("I have {int} cukes and {int} tomatoes") { (cukes: Int, tomatoes: Int) in
                XCTAssertEqual(cukes + tomatoes, basket.count)
            }
            """)
    }

    func testAParameterTheClosureDoesNotReadBecomesAnUnderscore() {
        assertConverts("""
            Given("I have {int} cukes in my {string}") { match, _ in
                let container = try match.first(\\.string)
                print(container)
            }
            """, to: """
            #Given("I have {int} cukes in my {string}") { (_: Int, container: String) in
                print(container)
            }
            """)
    }

    func testAStepDefinitionWithoutParametersLosesItsSignature() {
        assertConverts("""
            Given("I log in") { _, _ in
                login()
            }
            """, to: """
            #Given("I log in") {
                login()
            }
            """)
    }

    func testAStepDefinitionWithoutParametersKeepsTheStep() {
        assertConverts("""
            Given("I log in") { _, step in
                login(step.dataTable)
            }
            """, to: """
            #Given("I log in") { (step: Step) in
                login(step.dataTable)
            }
            """)
    }

    func testConvertsEveryEnglishKeyword() {
        for keyword in ["Given", "When", "Then", "And", "But", "MatchAll"] {
            assertConverts("""
                \(keyword)("I have {int} cukes") { match, _ in
                    let count = try match.first(\\.int)
                    use(count)
                }
                """, to: """
                #\(keyword)("I have {int} cukes") { (count: Int) in
                    use(count)
                }
                """)
        }
    }

    func testConvertsALocalizedStepDefinition() {
        assertConverts("""
            ES_Dado("tengo {int} pepinos") { match, _ in
                let cantidad = try match.first(\\.int)
                cesta.añadir(cantidad)
            }
            """, to: """
            #ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
                cesta.añadir(cantidad)
            }
            """)
    }

    func testConvertsACustomParameterTypeWhenTheClosureDeclaresItsType() {
        assertConverts("""
            Given("I have a {color} cuke") { match, _ in
                let color: Color = try match.first(\\.color)
                paint(color)
            }
            """, to: """
            #Given("I have a {color} cuke") { (color: Color) in
                paint(color)
            }
            """)
    }

    func testConvertsARegularExpressionStringByCaptureGroupPosition() {
        // The macro reads a capture group as {anonymous}.
        assertConverts("""
            Given("^I have (\\\\d+) cukes$") { match, _ in
                let count: String = try match.first(\\.anonymous)
                use(count)
            }
            """, to: """
            #Given("^I have (\\\\d+) cukes$") { (count: String) in
                use(count)
            }
            """)
    }

    func testConvertsTheCallbackLabelForm() {
        assertConverts("""
            Given("I have {int} cukes", callback: { match, _ in
                let count = try match.first(\\.int)
                use(count)
            })
            """, to: """
            #Given("I have {int} cukes", { (count: Int) in
                use(count)
            })
            """)
    }

    func testConvertsStepDefinitionsInsideCucumberExtensions() {
        let result = convert("""
            extension Cucumber: StepImplementation {
                public func setupSteps() {
                    Given("I have {int} cukes") { match, _ in
                        let count = try match.first(\\.int)
                        use(count)
                    }
                    When("I wait") { _, _ in
                        wait()
                    }
                }
            }
            """)
        XCTAssertEqual(result.converted.map(\.line), [5, 9])
        XCTAssertEqual(result.source, header + """
            extension Cucumber: StepImplementation {
                public func setupSteps() {
                    #Given("I have {int} cukes") { (count: Int) in
                        use(count)
                    }
                    #When("I wait") {
                        wait()
                    }
                }
            }
            """)
    }

    // MARK: Preserved

    func testKeepsCommentsAndFormatting() {
        assertConverts("""
            Given("I have {int} cukes in my {string}") { match, _ in
                // The count of cukes
                let count = try match.first(\\.int)   // trailing
                /* The container */
                let container = try match.first(\\.string)

                // Add them
                basket.add(count,
                           to: container)   // keeps its alignment
            }
            """, to: """
            #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
                // The count of cukes
                // trailing
                /* The container */

                // Add them
                basket.add(count,
                           to: container)   // keeps its alignment
            }
            """)
    }

    func testKeepsACaptureList() {
        assertConverts("""
            Given("I have {int} cukes") { [weak self] match, _ in
                let count = try match.first(\\.int)
                self?.basket.add(count)
            }
            """, to: """
            #Given("I have {int} cukes") { [weak self] (count: Int) in
                self?.basket.add(count)
            }
            """)
    }

    func testKeepsAsyncAndThrows() {
        assertConverts("""
            Then("I have {int} cukes") { [weak self] (match, _) async throws in
                let count = try match.first(\\.int)
                try await self?.basket.waitForCount(count)
            }
            """, to: """
            #Then("I have {int} cukes") { [weak self] (count: Int) async throws in
                try await self?.basket.waitForCount(count)
            }
            """)
    }

    func testKeepsAttributesOnTheClosure() {
        assertConverts("""
            Given("I have {int} cukes") { @MainActor match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """, to: """
            #Given("I have {int} cukes") { @MainActor (count: Int) in
                use(count)
            }
            """)
    }

    func testKeepsTheIndentationOfANestedStepDefinition() {
        assertConverts("""
            struct Steps {
                func setup() {
                    Given("I have {int} cukes") { match, _ in
                        let count = try match.first(\\.int)
                        use(count)
                    }
                }
            }
            """, to: """
            struct Steps {
                func setup() {
                    #Given("I have {int} cukes") { (count: Int) in
                        use(count)
                    }
                }
            }
            """)
    }

    // MARK: Imports

    func testImportsTheMacrosModuleWhenTheFileHasNotImportedIt() {
        let result = convert(source: """
            import XCTest
            import CucumberSwift

            Given("I log in") { _, _ in }
            """)
        XCTAssertEqual(result.source, """
            import XCTest
            import CucumberSwift
            import CucumberSwiftMacros

            #Given("I log in") {}
            """)
    }

    func testUsesTheSwiftTestingMacrosForTheSwiftTestingRunner() {
        let result = convert(source: """
            import CucumberSwiftTesting

            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """)
        XCTAssertEqual(result.source, """
            import CucumberSwiftTesting
            import CucumberSwiftTestingMacros

            #Given("I have {int} cukes") { (count: Int) in
                use(count)
            }
            """)
    }

    func testDoesNotImportTheMacrosModuleWhenNothingConverts() {
        let source = """
            import CucumberSwift

            Given("I have {int} cukes") { match, _ in
                use(match)
            }
            """
        XCTAssertEqual(convert(source: source).source, source)
    }

    func testALocalizedStepDefinitionIsLeftUnchangedForTheSwiftTestingRunner() {
        assertLeftUnchanged("""
            ES_Dado("tengo {int} pepinos") { match, _ in
                let cantidad = try match.first(\\.int)
                use(cantidad)
            }
            """, because: "has no localized macros", header: "import CucumberSwiftTestingMacros\n")
    }
}
#endif
