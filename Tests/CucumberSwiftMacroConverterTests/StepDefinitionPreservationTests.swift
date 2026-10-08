//
//  StepDefinitionPreservationTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

final class StepDefinitionPreservationTests: ConverterTestCase {
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

    func testAddsNoImportToAFileThatImportsTheMacrosModuleAlready() {
        assertConverts("""
            Given("I log in") { _, _ in
                login()
            }
            """,
            to: """
            #Given("I log in") {
                login()
            }
            """,
            header: "import CucumberSwiftMacros\n")
        assertConverts("""
            Given("I log in") { _, _ in
                login()
            }
            """,
            to: """
            #Given("I log in") {
                login()
            }
            """,
            header: "import CucumberSwiftTestingMacros\n")
    }

    func testKeepsTheRunnersImportAndAddsTheMacrosModuleAfterIt() {
        let result = convert(source: """
            import XCTest
            @testable import CucumberSwift
            import Foundation

            Given("I log in") { _, _ in }
            """)
        XCTAssertEqual(result.source, """
            import XCTest
            @testable import CucumberSwift
            import CucumberSwiftMacros
            import Foundation

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
        let result = convert(source: source)
        XCTAssertEqual(result.converted, [])
        XCTAssertFalse(result.source.contains("import CucumberSwiftMacros"))
    }

    func testALocalizedStepDefinitionIsLeftUnchangedForTheSwiftTestingRunner() {
        assertLeftUnchanged("""
            ES_Dado("tengo {int} pepinos") { match, _ in
                let cantidad = try match.first(\\.int)
                use(cantidad)
            }
            """,
            because: "has no localized macros",
            header: "import CucumberSwiftTestingMacros\n")
    }
}
#endif
