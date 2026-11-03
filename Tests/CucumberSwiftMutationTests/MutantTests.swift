//
//  MutantTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class MutantTests: XCTestCase {
    private func mutant(original: String, replacement: String, offset: Int) -> Mutant {
        Mutant(id: 1, file: "Sources/A.swift", line: 1, column: offset + 1, endLine: 1, endColumn: offset + 1 + original.utf8.count,
               offset: offset, length: original.utf8.count, original: original, replacement: replacement, mutator: "RelationalOperator")
    }

    func testReplacesTheTextAtTheMutantsPlace() throws {
        let source = "func canVote(age: Int) -> Bool { age >= 18 }"
        let found = mutant(original: ">=", replacement: ">", offset: 37)
        XCTAssertEqual(try found.applied(to: source), "func canVote(age: Int) -> Bool { age > 18 }")
    }

    func testCountsOffsetsInBytesNotCharacters() throws {
        // The é is two bytes, so the operator starts at byte 9, not at character 8.
        let source = "let é = a >= b"
        let found = mutant(original: ">=", replacement: "<", offset: 11)
        XCTAssertEqual(try found.applied(to: source), "let é = a < b")
    }

    func testRefusesWhenTheFileChangedSinceTheMutantWasFound() {
        let found = mutant(original: ">=", replacement: ">", offset: 37)
        XCTAssertThrowsError(try found.applied(to: "func canVote(age: Int) -> Bool { age <= 18 }")) {
            XCTAssertEqual($0 as? Mutant.ApplyError, .textChanged(expected: ">=", found: "<="))
        }
    }

    func testRefusesAPlaceOutsideTheFile() {
        let found = mutant(original: ">=", replacement: ">", offset: 100)
        XCTAssertThrowsError(try found.applied(to: "short")) {
            XCTAssertEqual($0 as? Mutant.ApplyError, .outOfRange)
        }
    }

    func testRenumberingKeepsEverythingElse() {
        let found = mutant(original: ">=", replacement: ">", offset: 37).numbered(7)
        XCTAssertEqual(found.id, 7)
        XCTAssertEqual(found.original, ">=")
        XCTAssertEqual(found.summary, "Sources/A.swift:1:38 RelationalOperator >= → >")
    }
}
