//
//  DiscoveryToolTests.swift
//  CucumberSwiftMutationTests
//

import Foundation
import XCTest
@testable import CucumberSwiftMutation

/// Runs the tool built next to the test bundle as a program, because linking swift-syntax into a second test target
/// breaks the macros' tests with Swift 6.2's prebuilt swift-syntax.
final class DiscoveryToolTests: XCTestCase {
    /// What the tool exited with and printed.
    private struct Launched {
        let status: Int32
        let output: String
        let error: String
    }

    private var tool: URL {
        let bundle = Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") }
        return bundle.map { $0.bundleURL.deletingLastPathComponent().appendingPathComponent("CucumberSwiftMutationTestingTool") }
            ?? URL(fileURLWithPath: "CucumberSwiftMutationTestingTool")
    }

    private func launch(_ arguments: [String], input: String = "") throws -> Launched {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        stdin.fileHandleForWriting.write(Data(input.utf8))
        try stdin.fileHandleForWriting.close()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let error = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Launched(
            status: process.terminationStatus,
            output: String(bytes: output, encoding: .utf8) ?? "",
            error: String(bytes: error, encoding: .utf8) ?? ""
        )
    }

    #if Macros
    private func mutants(in source: String) throws -> [Mutant] {
        let run = try launch(["--discover"], input: source)
        XCTAssertEqual(run.status, 0, run.error)
        return try JSONDecoder().decode([Mutant].self, from: Data(run.output.utf8))
    }

    private func changes(_ mutants: [Mutant]) -> [String] {
        mutants.map { "\($0.original)→\($0.replacement)" }
    }

    func testAComparisonGetsTheBoundaryAndTheInvertedMutant() throws {
        let found = try mutants(in: "func canVote(age: Int) -> Bool { age >= 18 }")
        XCTAssertEqual(changes(found), [">=→>", ">=→<"])
        XCTAssertEqual(found.map(\.mutator), ["RelationalOperator", "RelationalOperator"])
        XCTAssertEqual(found.first?.line, 1)
        XCTAssertEqual(found.first?.column, 38)
    }

    func testEveryRelationalOperatorHasItsReplacements() throws {
        let source = "let a = x > 1, b = x < 1, c = x <= 1, d = x == 1, e = x != 1"
        XCTAssertEqual(changes(try mutants(in: source)), [">→>=", ">→<=", "<→<=", "<→>=", "<=→<", "<=→>", "==→!=", "!=→=="])
    }

    func testLogicalOperatorsSwap() throws {
        XCTAssertEqual(changes(try mutants(in: "let a = x && y || z")), ["&&→||", "||→&&"])
    }

    func testBooleanLiteralsFlip() throws {
        XCTAssertEqual(changes(try mutants(in: "let a = true\nlet b = false")), ["true→false", "false→true"])
    }

    func testOperatorsInStringsAndCommentsAreNotMutated() throws {
        let source = """
        // a >= b && true
        let text = "a >= b && true"
        /* x == y */
        """
        XCTAssertEqual(try mutants(in: source), [])
    }

    func testGenericsAndArrowsAreNotComparisons() throws {
        let source = "let a: Array<Int> = []\nfunc f() -> Bool { return false }"
        XCTAssertEqual(changes(try mutants(in: source)), ["false→true"])
    }

    func testTheOffsetsApplyToTheSourceInBytes() throws {
        let source = "let name = \"é\"; let ok = a >= b\n"
        for mutant in try mutants(in: source) {
            XCTAssertEqual(try mutant.applied(to: source).contains(mutant.replacement), true)
            XCTAssertEqual(mutant.length, mutant.original.utf8.count)
        }
        let found = try mutants(in: source)
        XCTAssertEqual(try found.first?.applied(to: source), "let name = \"é\"; let ok = a > b\n")
    }

    func testMutantsAreInSourceOrderWithTheirLines() throws {
        let found = try mutants(in: "let a = true\nlet b = x >= 1")
        XCTAssertEqual(found.map(\.line), [1, 2, 2])
    }

    func testAnUnknownOptionIsAnErrorBeforeAnythingRuns() throws {
        let run = try launch(["--root", "/nonexistent", "--bogus"])
        XCTAssertEqual(run.status, MutationRun.Status.failed)
        XCTAssertTrue(run.error.contains("Unknown option --bogus"), run.error)
    }
    #else
    func testWithoutTheTraitTheToolSaysWhatToTurnOnAndChangesNothing() throws {
        let run = try launch(["--root", "/nonexistent"])
        XCTAssertEqual(run.status, 2)
        XCTAssertTrue(run.error.contains("Macros package trait"), run.error)
    }
    #endif
}
