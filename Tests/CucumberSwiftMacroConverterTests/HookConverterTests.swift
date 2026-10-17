//
//  HookConverterTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// Hook calls become their macros, which take the same arguments and expand back to the call.
final class HookConverterTests: ConverterTestCase {
    private let macros: [String: Macro.Type] = [
        "BeforeFeature": HookMacro.self,
        "AfterFeature": HookMacro.self,
        "BeforeScenario": HookMacro.self,
        "AfterScenario": HookMacro.self,
        "BeforeStep": HookMacro.self,
        "AfterStep": HookMacro.self
    ]

    /// Converts the hook, checks what came out, and that it expands to exactly the hook it replaced.
    private func assertConvertsAndExpandsBack(_ before: String, to after: String, file: StaticString = #filePath, line: UInt = #line) {
        assertConverts(before, to: after, file: file, line: line)
        assertMacroExpansion(after, expandedSource: before, macros: macros, file: file, line: line)
    }

    // MARK: Converted

    func testConvertsEachHook() {
        assertConvertsAndExpandsBack("""
            BeforeFeature { feature in
                print(feature.title)
            }
            AfterFeature { _ in
                close()
            }
            BeforeScenario { scenario in
                reset(scenario)
            }
            AfterScenario { _ in
                reset()
            }
            BeforeStep { step in
                print(step.keyword)
            }
            AfterStep { _ in
                count += 1
            }
            """, to: """
            #BeforeFeature { feature in
                print(feature.title)
            }
            #AfterFeature { _ in
                close()
            }
            #BeforeScenario { scenario in
                reset(scenario)
            }
            #AfterScenario { _ in
                reset()
            }
            #BeforeStep { step in
                print(step.keyword)
            }
            #AfterStep { _ in
                count += 1
            }
            """)
    }

    func testKeepsThePriorityFileLineAndAnAsyncClosure() {
        assertConvertsAndExpandsBack("""
            BeforeScenario(priority: 1, file: #filePath, line: 12) { @MainActor scenario async throws in
                try await app.launch(for: scenario)
            }
            """, to: """
            #BeforeScenario(priority: 1, file: #filePath, line: 12) { @MainActor scenario async throws in
                try await app.launch(for: scenario)
            }
            """)
    }

    func testALabelledClosure() {
        assertConvertsAndExpandsBack("""
            AfterStep(priority: 2, closure: { step in
                    print(step.keyword)
                })
            """, to: """
            #AfterStep(priority: 2, closure: { step in
                    print(step.keyword)
                })
            """)
    }

    func testReportsTheHookWithItsArguments() {
        let result = convert("""
            BeforeScenario { _ in }
            AfterStep(priority: 2) { _ in }
            """)
        XCTAssertEqual(result.converted, [
            .init(line: 3, stepDefinition: "BeforeScenario", reason: nil),
            .init(line: 4, stepDefinition: "AfterStep(priority: 2)", reason: nil)
        ])
    }

    func testAddsTheMacrosImportForTheSwiftTestingRunner() {
        let result = convert(source: """
            import CucumberSwiftTesting

            BeforeScenario { _ in }
            """)
        XCTAssertEqual(result.source, """
            import CucumberSwiftTesting
            import CucumberSwiftTestingMacros

            #BeforeScenario { _ in }
            """)
    }

    func testConvertsHooksAndStepDefinitionsTogether() {
        assertConverts("""
            BeforeScenario { _ in
                basket.empty()
            }
            Given("I have {int} cukes") { match, _ in
                let count = try match.first(\\.int)
                basket.add(count)
            }
            """, to: """
            #BeforeScenario { _ in
                basket.empty()
            }
            #Given("I have {int} cukes") { (count: Int) in
                basket.add(count)
            }
            """)
    }

    // MARK: Left unchanged

    func testAFunctionIsLeftUnchanged() {
        assertLeftUnchanged("""
            BeforeScenario(priority: 1, closure: reset)
            """, because: "it passes a function, and the macros take a closure")
    }

    func testAnArgumentTheMacrosDoNotTakeIsLeftUnchanged() {
        assertLeftUnchanged("""
            BeforeScenario(tags: ["@smoke"]) { _ in }
            """, because: "it passes `tags:`, which the macros don't take")
    }

    func testAHookDeclaredInTheFileIsLeftUnchanged() {
        assertLeftUnchanged("""
            func BeforeStep(closure: (Int) -> Void) { }
            func setUp() {
                BeforeStep { _ in }
            }
            """, because: "a `BeforeStep` declared in this file is in scope, so the call may not be a hook", marked: false)
    }

    func testAMacroIsLeftAsItIs() {
        let source = """
            #BeforeScenario { _ in }
            """
        let result = convert(source)
        XCTAssertEqual(result.source, header + source)
        XCTAssertEqual(result.converted, [])
        XCTAssertEqual(result.leftUnchanged, [])
    }
}
#endif
