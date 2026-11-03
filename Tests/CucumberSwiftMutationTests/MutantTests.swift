//
//  MutantTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class MutantTests: XCTestCase {
    func testReplacesTheTextAtTheMutantsPlace() throws {
        let source = "func canVote(age: Int) -> Bool { age >= 18 }"
        let found = Mutant.fixture(file: "Sources/A.swift", replacement: ">", offset: 37)
        XCTAssertEqual(try found.applied(to: source), "func canVote(age: Int) -> Bool { age > 18 }")
    }

    func testCountsOffsetsInBytesNotCharacters() throws {
        // The é is two bytes, so the operator starts at byte 9, not at character 8.
        let source = "let é = a >= b"
        let found = Mutant.fixture(file: "Sources/A.swift", replacement: "<", offset: 11)
        XCTAssertEqual(try found.applied(to: source), "let é = a < b")
    }

    func testRefusesWhenTheFileChangedSinceTheMutantWasFound() {
        let found = Mutant.fixture(file: "Sources/A.swift", replacement: ">", offset: 37)
        XCTAssertThrowsError(try found.applied(to: "func canVote(age: Int) -> Bool { age <= 18 }")) {
            XCTAssertEqual($0 as? Mutant.ApplyError, .textChanged(expected: ">=", found: "<="))
        }
    }

    func testRefusesAPlaceOutsideTheFile() {
        let found = Mutant.fixture(file: "Sources/A.swift", replacement: ">", offset: 100)
        XCTAssertThrowsError(try found.applied(to: "short")) {
            XCTAssertEqual($0 as? Mutant.ApplyError, .outOfRange)
        }
    }

    func testRenumberingKeepsEverythingElse() {
        let found = Mutant.fixture(file: "Sources/A.swift", replacement: ">", offset: 37).numbered(7)
        XCTAssertEqual(found.id, 7)
        XCTAssertEqual(found.original, ">=")
        XCTAssertEqual(found.summary, "Sources/A.swift:1:38 RelationalOperator >= → >")
    }
}
