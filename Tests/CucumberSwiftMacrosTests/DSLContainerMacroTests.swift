//
//  DSLContainerMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
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

    /// The compiler expands a macro inside a container from the container's expansion, counting its lines from there, so
    /// the container writes onto it the position that it has in the Swift file, which it then uses. (swift-syntax 600's
    /// test context can't locate a macro inside another, so the container's side is tested by the fixture that compiles
    /// features written with the macros, and its position in the reports.)
    func testAMacroWithAPositionFromItsContainerUsesIt() {
        assertMacroExpansion(
            """
            /*cucumberswift-position:4:14:/Tests/Checkout.swift*/ #Scenario("Buy") {
                /*cucumberswift-position:5:15:/Tests/Checkout.swift*/ #Given(I: shop())
            }
            """,
            expandedSource: """
            /*cucumberswift-position:4:14:/Tests/Checkout.swift*/ Scenario("Buy", line: 4, column: 14) {
                /*cucumberswift-position:5:15:/Tests/Checkout.swift*/ #Given(I: shop())
            }
            """,
            macros: ["Scenario": DSLScenarioMacro.self])
    }

    /// A path with `/*` or `%` in it is written onto the marker encoded, so the comment stays one comment.
    func testAMarkerKeepsAFilePathWithACommentDelimiterInIt() {
        let file = "/tmp/*checkout/100%/Tests/Feature.swift"
        let encoded = PositionMarker.encoded(file)
        XCTAssertFalse(encoded.contains("/*") || encoded.contains("*/"), encoded)
        XCTAssertEqual(encoded, "/tmp/%2Acheckout/100%25/Tests/Feature.swift")
        assertMacroExpansion(
            """
            /*cucumberswift-position:4:14:\(encoded)*/ #Scenario("Buy") {
            }
            """,
            expandedSource: """
            /*cucumberswift-position:4:14:\(encoded)*/ Scenario("Buy", line: 4, column: 14) {
            }
            """,
            macros: ["Scenario": DSLScenarioMacro.self])
    }

    /// swift-syntax 600's test context can't locate a token inside a macro, so the container's side of the marker is run
    /// here with a context that can: it places each token at the line of its offset and the column 7, in a file whose path
    /// has a `*` in it. The container writes onto each macro in its contents the position that the context gives it.
    func testAContainerWritesTheFilePositionOntoEachMacroInItsContents() throws {
        let source = "#Scenario(\"Buy\") {\n    #Given(I: shop())\n    #When(I: pay())\n    #Background {\n    }\n}"
        let tree = Parser.parse(source: source)
        let found = tree.tokens(viewMode: .sourceAccurate).compactMap { $0.parent?.as(MacroExpansionExprSyntax.self) }
        let scenario = try XCTUnwrap(found.first { $0.macroName.text == "Scenario" })
        let context = LocatingContext(file: "/Pkg/*checkout/Tests/F.swift")
        let expansion = try DSLScenarioMacro.expansion(of: scenario, in: context)
        let text = expansion.description
        func marker(of name: String) throws -> String {
            let node = try XCTUnwrap(found.first { $0.macroName.text == name })
            let paren = try XCTUnwrap(node.leftParen)
            let line = paren.positionAfterSkippingLeadingTrivia.utf8Offset
            return "/*cucumberswift-position:\(line):7:/Pkg/%2Acheckout/Tests/F.swift*/ #\(name)"
        }
        XCTAssertTrue(text.contains(try marker(of: "Given")), text)
        XCTAssertTrue(text.contains(try marker(of: "When")), text)
        XCTAssertEqual(text.components(separatedBy: "/*cucumberswift-position:").count - 1, 2, "No marker on #Background: \(text)")
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

/// A context that locates any node: the line is its offset in the source, the column is 7, in `file`.
private final class LocatingContext: MacroExpansionContext {
    let file: String
    init(file: String) { self.file = file }

    var lexicalContext: [Syntax] { [] }

    func makeUniqueName(_ name: String) -> TokenSyntax { .identifier(name) }

    func diagnose(_ diagnostic: Diagnostic) {}

    func location(of node: some SyntaxProtocol, at position: PositionInSyntaxNode,
                  filePathMode: SourceLocationFilePathMode) -> AbstractSourceLocation? {
        AbstractSourceLocation(
            file: "\(literal: file)",
            line: "\(literal: node.positionAfterSkippingLeadingTrivia.utf8Offset)",
            column: "7")
    }
}
#endif
