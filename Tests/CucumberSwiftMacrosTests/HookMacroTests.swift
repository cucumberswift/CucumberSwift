//
//  HookMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// Each hook macro expands to the hook call it stands for, with the same arguments and closure.
final class HookMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "BeforeFeature": HookMacro.self,
        "AfterFeature": HookMacro.self,
        "BeforeScenario": HookMacro.self,
        "AfterScenario": HookMacro.self,
        "BeforeStep": HookMacro.self,
        "AfterStep": HookMacro.self
    ]

    func testExpandsToTheHookCall() {
        assertMacroExpansion(
            """
            #BeforeScenario { scenario in
                print(scenario.title)
            }
            """,
            expandedSource: """
            BeforeScenario { scenario in
                print(scenario.title)
            }
            """,
            macros: macros)
    }

    func testKeepsThePriorityAndTheTypedArgument() {
        assertMacroExpansion(
            """
            #AfterFeature(priority: 1) { (feature: Feature) in
                print(feature.title)
            }
            """,
            expandedSource: """
            AfterFeature(priority: 1) { (feature: Feature) in
                print(feature.title)
            }
            """,
            macros: macros)
    }

    func testKeepsTheFileLineAndAnAsyncThrowingMainActorClosure() {
        assertMacroExpansion(
            """
            #BeforeStep(priority: 2, file: #filePath, line: 7) { @MainActor step async throws in
                try await check(step)
            }
            """,
            expandedSource: """
            BeforeStep(priority: 2, file: #filePath, line: 7) { @MainActor step async throws in
                try await check(step)
            }
            """,
            macros: macros)
    }

    func testAClosureWithoutAnArgumentIsGivenAWildcard() {
        assertMacroExpansion(
            """
            #AfterScenario {
                reset()
            }
            """,
            expandedSource: """
            AfterScenario { _ in
                reset()
            }
            """,
            macros: macros)
    }

    func testAOneLineClosureWithoutAnArgumentIsGivenAWildcard() {
        assertMacroExpansion(
            """
            #AfterStep(priority: 3) { print("done") }
            """,
            expandedSource: """
            AfterStep(priority: 3) { _ in
                print("done")
            }
            """,
            macros: macros)
    }

    func testAnEmptyClosureIsGivenAWildcard() {
        assertMacroExpansion(
            """
            #BeforeFeature { }
            """,
            expandedSource: """
            BeforeFeature { _ in
            }
            """,
            macros: macros)
    }

    func testAWildcardGoesAfterACaptureListAndBeforeEffects() {
        assertMacroExpansion(
            """
            #AfterFeature { [weak self] in
                self?.close()
            }
            #BeforeScenario { () async throws in
                try await reset()
            }
            """,
            expandedSource: """
            AfterFeature { [weak self] _ in
                self?.close()
            }
            BeforeScenario { _ async throws in
                try await reset()
            }
            """,
            macros: macros)
    }

    func testAClosureThatUsesDollarZeroIsKept() {
        assertMacroExpansion(
            """
            #BeforeStep { print($0.keyword) }
            """,
            expandedSource: """
            BeforeStep {
                print($0.keyword)
            }
            """,
            macros: macros)
    }

    func testANestedClosuresDollarZeroIsItsOwn() {
        assertMacroExpansion(
            """
            #BeforeStep { names.forEach { print($0) } }
            """,
            expandedSource: """
            BeforeStep { _ in
                names.forEach {
                    print($0)
                }
            }
            """,
            macros: macros)
    }

    func testALabelledClosure() {
        assertMacroExpansion(
            """
            #AfterStep(priority: 1, closure: { step in print(step) })
            """,
            expandedSource: """
            AfterStep(priority: 1, closure: { step in
                    print(step)
                })
            """,
            macros: macros)
    }

    func testTheRunnersModuleNamesTheType() {
        assertMacroExpansion(
            """
            #BeforeScenario { (scenario: CucumberSwiftTesting.Scenario) in }
            #AfterScenario { (scenario: CucumberSwift.Scenario) in }
            """,
            expandedSource: """
            BeforeScenario { (scenario: CucumberSwiftTesting.Scenario) in
            }
            AfterScenario { (scenario: CucumberSwift.Scenario) in
            }
            """,
            macros: macros)
    }
}
#endif
