//
//  DSLContainerMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// Each container macro of the Swift DSL expands to the call it stands for, with the same arguments and the line
/// and column of its opening parenthesis, and `#Feature` its file, before its contents.
final class DSLContainerMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "Feature": DSLFeatureMacro.self,
        "Scenario": DSLScenarioMacro.self,
        "ScenarioOutline": DSLScenarioMacro.self,
        "Rule": DSLScenarioMacro.self,
        "Background": DSLPartMacro.self,
        "Description": DSLPartMacro.self,
        "ES_Característica": DSLFeatureMacro.self
    ]

    func testAFeatureHasItsPositionAndFileBeforeItsContents() {
        assertMacroExpansion(
            """
            #Feature("Checkout", tags: ["shop"]) {
                Description("About it")
            }
            """,
            expandedSource: """
            Feature("Checkout", tags: ["shop"], line: 1, column: 9, file: "test.swift") {
                Description("About it")
            }
            """,
            macros: macros)
    }

    // One macro at a time: SwiftSyntax's test support reports a macro nested in another with the same
    // implementation as recursive, where the compiler expands an argument's macro on its own.
    func testAScenarioAndARuleHaveTheirPosition() {
        assertMacroExpansion(
            """
            #Rule("R", tags: ["rule"]) {
                Scenario("S") {
                    Given(I: start())
                }
            }
            """,
            expandedSource: """
            Rule("R", tags: ["rule"], line: 1, column: 6) {
                Scenario("S") {
                    Given(I: start())
                }
            }
            """,
            macros: macros)
        assertMacroExpansion(
            """
            #Scenario("S", description: "D") {
                Given(I: start())
            }
            """,
            expandedSource: """
            Scenario("S", description: "D", line: 1, column: 10) {
                Given(I: start())
            }
            """,
            macros: macros)
    }

    func testAnOutlinesPositionComesBeforeItsStepsAndExamples() {
        assertMacroExpansion(
            #"#ScenarioOutline({ "Buy \($0)" }, headers: Int.self, steps: { count in Given(I: buy(count)) }, examples: { [1, 2] })"#,
            expandedSource: #"""
            ScenarioOutline({
                    "Buy \($0)"
                }, headers: Int.self, line: 1, column: 17, steps: { count in
                    Given(I: buy(count))
                }, examples: {
                    [1, 2]
                })
            """#,
            macros: macros)
    }

    func testABackgroundAndADescriptionAreTheCallsAsWritten() {
        assertMacroExpansion(
            """
            #Background {
                Given(I: openTheShop())
            }
            """,
            expandedSource: """
            Background() {
                Given(I: openTheShop())
            }
            """,
            macros: macros)
        assertMacroExpansion(
            #"#Description("About it")"#,
            expandedSource: #"Description("About it")"#,
            macros: macros)
    }

    func testAStepDefinitionInAScenarioIsAnError() {
        assertMacroExpansion(
            """
            #Scenario("S") {
                #Given("I do X") { }
            }
            """,
            expandedSource: """
            Scenario("S", line: 1, column: 10) {
                #Given("I do X") {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: DSLPlacementMessage.stepDefinitionInFeature.message, line: 2, column: 5)
            ],
            macros: macros)
    }

    func testAStepDefinitionFunctionInsideAFeatureIsAnError() {
        assertMacroExpansion(
            """
            #Feature("F") {
                Scenario("S") {
                    Given("I do {int} things") { _, _ in }
                }
            }
            """,
            expandedSource: """
            Feature("F", line: 1, column: 9, file: "test.swift") {
                Scenario("S") {
                    Given("I do {int} things") { _, _ in
                    }
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: DSLPlacementMessage.stepDefinitionInFeature.message, line: 3, column: 9)
            ],
            macros: macros)
    }

    func testANestedContainerMacroReportsItsOwnStepDefinitionsOnce() {
        assertMacroExpansion(
            """
            #Feature("F") {
                #Background {
                    Then(#/^done$/#) { _, _ in }
                }
            }
            """,
            expandedSource: """
            Feature("F", line: 1, column: 9, file: "test.swift") {
                Background() {
                        Then(#/^done$/#) { _, _ in
                        }
                    }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: DSLPlacementMessage.stepDefinitionInFeature.message, line: 3, column: 9)
            ],
            macros: macros)
    }

    func testDSLStepsInAScenarioAreFine() {
        assertMacroExpansion(
            """
            #Scenario("S") {
                Given(I: doX())
                When(doY())
            }
            """,
            expandedSource: """
            Scenario("S", line: 1, column: 10) {
                Given(I: doX())
                When(doY())
            }
            """,
            macros: macros)
    }

    func testALocalizedFeatureExpandsToItsLocalizedType() {
        assertMacroExpansion(
            #"#ES_Característica("Caja") { }"#,
            // The column counts UTF-8 bytes, as the compiler's does: `í` is two.
            expandedSource: """
            ES_Característica("Caja", line: 1, column: 20, file: "test.swift") {
            }
            """,
            macros: macros)
    }
}
#endif
