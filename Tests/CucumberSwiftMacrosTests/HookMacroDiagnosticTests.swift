//
//  HookMacroDiagnosticTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// The errors the hook macros report, and what applying each fix-it produces.
final class HookMacroDiagnosticTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "BeforeFeature": HookMacro.self,
        "BeforeScenario": HookMacro.self,
        "AfterStep": HookMacro.self
    ]

    func testTooManyArgumentsOffersTheHooksArgument() {
        assertMacroExpansion(
            """
            #BeforeScenario { (scenario: Scenario, step: Step) in
                print(scenario, step)
            }
            """,
            expandedSource: """
            #BeforeScenario { (scenario: Scenario, step: Step) in
                print(scenario, step)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "BeforeScenario passes the Scenario, but the closure takes 2 arguments. "
                                   + "Give the closure one argument, the Scenario, or none.",
                               line: 1,
                               column: 19,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (scenario: Scenario)")])
            ],
            macros: macros,
            applyFixIts: ["Change the closure's parameters to (scenario: Scenario)"],
            fixedSource: """
            #BeforeScenario { (scenario: Scenario) in
                print(scenario, step)
            }
            """)
    }

    func testTooManyArgumentsWithoutTypes() {
        assertMacroExpansion(
            """
            #AfterStep { step, other in }
            """,
            expandedSource: """
            #AfterStep { step, other in }
            """,
            diagnostics: [
                DiagnosticSpec(message: "AfterStep passes the Step, but the closure takes 2 arguments. "
                                   + "Give the closure one argument, the Step, or none.",
                               line: 1,
                               column: 14,
                               fixIts: [FixItSpec(message: "Change the closure's parameters to (step: Step)")])
            ],
            macros: macros,
            applyFixIts: ["Change the closure's parameters to (step: Step)"],
            fixedSource: """
            #AfterStep { (step: Step) in }
            """)
    }

    func testWrongTypeOffersTheHooksType() {
        assertMacroExpansion(
            """
            #BeforeFeature(priority: 1) { (feature: Scenario) async in
                await open(feature)
            }
            """,
            expandedSource: """
            #BeforeFeature(priority: 1) { (feature: Scenario) async in
                await open(feature)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "BeforeFeature passes a Feature, but 'feature' is declared as Scenario.",
                               line: 1,
                               column: 41,
                               fixIts: [FixItSpec(message: "Change the type to Feature")])
            ],
            macros: macros,
            applyFixIts: ["Change the type to Feature"],
            fixedSource: """
            #BeforeFeature(priority: 1) { (feature: Feature) async in
                await open(feature)
            }
            """)
    }

    func testAFunctionIsNotAClosure() {
        assertMacroExpansion(
            """
            #BeforeScenario(priority: 1, closure: reset)
            """,
            expandedSource: """
            #BeforeScenario(priority: 1, closure: reset)
            """,
            diagnostics: [
                DiagnosticSpec(message: "The hook's body must be a closure.", line: 1, column: 1)
            ],
            macros: macros)
    }
}
#endif
