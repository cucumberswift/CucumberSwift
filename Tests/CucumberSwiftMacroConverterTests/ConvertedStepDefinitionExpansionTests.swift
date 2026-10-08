//
//  ConvertedStepDefinitionExpansionTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// A converted step definition has to expand to the step definition it replaced. Each test converts one,
/// expands the macro that came out, and compares the result with the original written the way the macro
/// writes it: the pattern `as CucumberExpression`, and each read with its type.
final class ConvertedStepDefinitionExpansionTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Given": StepDefinitionMacro.self,
        "Then": StepDefinitionMacro.self,
        "ES_Dado": StepDefinitionMacro.self
    ]

    private func assertExpansion(of original: String, is expected: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let result = try ConverterTool.convert("import CucumberSwiftMacros\n" + original)
        XCTAssertEqual(result.leftUnchanged, [], file: file, line: line)
        XCTAssertEqual(result.converted.count, 1, file: file, line: line)
        let converted = result.source.replacingOccurrences(of: "import CucumberSwiftMacros\n", with: "")
        assertMacroExpansion(converted, expandedSource: expected, macros: macros, file: file, line: line)
    }

    func testTheIssuesStepDefinition() throws {
        try assertExpansion(of: """
            Given("I have {int} cukes in my {string}") { match, _ in
                let count = try match.first(\\.int)
                let container = try match.first(\\.string)
                basket.add(count, to: container)
            }
            """, is: """
            Given("I have {int} cukes in my {string}" as CucumberExpression) { match, _ in
                let count: Int = try match.first(\\.int)
                let container: String = try match.first(\\.string)
                basket.add(count, to: container)
            }
            """)
    }

    func testAParameterTypeTheExpressionHasMoreThanOnce() throws {
        try assertExpansion(of: """
            Then("I have {int} cukes and {int} tomatoes") { match, step in
                let cukes = match[\\.int, index: 0]
                let tomatoes = match[\\.int, index: 1]
                XCTAssertEqual(cukes + tomatoes, step.dataTable?.rows.count)
            }
            """, is: """
            Then("I have {int} cukes and {int} tomatoes" as CucumberExpression) { match, step in
                let cukes: Int = match[\\.int, index: 0]
                let tomatoes: Int = match[\\.int, index: 1]
                XCTAssertEqual(cukes + tomatoes, step.dataTable?.rows.count)
            }
            """)
    }

    // A closure with a capture list is typed as a constant before it is passed, as the macro does since #274.
    func testACaptureListAndAsyncAndThrows() throws {
        try assertExpansion(of: """
            Given("I have {int} cukes") { [weak self] (match, _) async throws in
                let count = try match.first(\\.int)
                try await self?.basket.waitForCount(count)
            }
            """, is: """
            { () -> Given in
                let callback: @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void = { [weak self] (match, _) async throws in
                    let count: Int = try match.first(\\.int)
                    try await self?.basket.waitForCount(count)
                }
                return Given("I have {int} cukes" as CucumberExpression, callback: callback)
            }()
            """)
    }

    func testALocalizedStepDefinition() throws {
        try assertExpansion(of: """
            ES_Dado("tengo {int} pepinos") { match, _ in
                let cantidad = try match.first(\\.int)
                cesta.añadir(cantidad)
            }
            """, is: """
            ES_Dado("tengo {int} pepinos" as CucumberExpression) { match, _ in
                let cantidad: Int = try match.first(\\.int)
                cesta.añadir(cantidad)
            }
            """)
    }

    func testAnAsyncStepDefinitionWithoutParameters() throws {
        try assertExpansion(of: """
            Given("I wait") { (_, _) async throws in
                try await wait()
            }
            """, is: """
            Given("I wait" as CucumberExpression) { (_, _) async throws in
                try await wait()
            }
            """)
    }

    func testAPatternCastAsACucumberExpression() throws {
        try assertExpansion(of: """
            Given("I have {int} cukes" as CucumberExpression) { match, _ in
                let count = try match.first(\\.int)
                use(count)
            }
            """, is: """
            Given("I have {int} cukes" as CucumberExpression) { match, _ in
                let count: Int = try match.first(\\.int)
                use(count)
            }
            """)
    }

    func testARegexLiteral() throws {
        try assertExpansion(of: """
            Given(#/^I have (\\d+) cukes$/#) { match, _ in
                let count = match.1
                use(count)
            }
            """, is: """
            Given("^I have (\\\\d+) cukes$" as CucumberExpression) { match, _ in
                let count: String = try match.first(\\.anonymous)
                use(count)
            }
            """)
    }

    func testAStepDefinitionWithoutParameters() throws {
        try assertExpansion(of: """
            Given("I log in") { _, _ in
                login()
            }
            """, is: """
            Given("I log in" as CucumberExpression) { _, _ in
                login()
            }
            """)
    }
}
#endif
