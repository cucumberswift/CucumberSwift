//
//  ScenarioCoverageTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class ScenarioCoverageTests: TemporaryFolderTestCase {
    /// `canVote` is one region on line 1. Its body has an `if` on lines 3 to 5 that only the second scenario entered.
    private let coverage = ScenarioCoverage(
        regions: [
            .init(file: "/copy/Sources/Voting/Voting.swift", lineStart: 1, columnStart: 40, lineEnd: 1, columnEnd: 52),
            .init(file: "/copy/Sources/Voting/Voting.swift", lineStart: 2, columnStart: 30, lineEnd: 6, columnEnd: 2),
            .init(file: "/copy/Sources/Voting/Voting.swift", lineStart: 3, columnStart: 20, lineEnd: 5, columnEnd: 6)
        ],
        scenarios: [
            .init(feature: "Voting.feature", line: 4, name: "An adult can vote", ran: [0, 1]),
            .init(feature: "Voting.feature", line: 8, name: "A child cannot vote", ran: [0, 1, 2])
        ]
    )

    private func mutant(line: Int, column: Int) -> Mutant {
        Mutant.fixture(line: line, column: column)
    }

    func testEveryScenarioThatRanTheRegionRunsTheMutant() {
        XCTAssertEqual(coverage.scenarios(running: mutant(line: 1, column: 45)).map(\.line), [4, 8])
    }

    func testTheInnermostRegionDecides() {
        // Line 4 is inside the `if`, which only the second scenario entered, although both ran the function.
        XCTAssertEqual(coverage.scenarios(running: mutant(line: 4, column: 10)).map(\.line), [8])
        // Line 2 is outside the `if`.
        XCTAssertEqual(coverage.scenarios(running: mutant(line: 2, column: 35)).map(\.line), [4, 8])
    }

    func testCodeOutsideTheMeasuredRegionsHasNoScenario() {
        XCTAssertEqual(coverage.scenarios(running: mutant(line: 1, column: 10)), [])
        XCTAssertEqual(coverage.scenarios(running: mutant(line: 40, column: 1)), [])
        let elsewhere = Mutant.fixture(file: "Sources/Other.swift", line: 1, column: 45)
        XCTAssertEqual(coverage.scenarios(running: elsewhere), [])
    }

    func testReadsTheRegionsFileOfARun() throws {
        let run = folder.appendingPathComponent("run-ABC")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        let json = """
        {"version": 1,
         "regions": [{"file": "/copy/Sources/Voting/Voting.swift", "lineStart": 1, "columnStart": 40, "lineEnd": 1, "columnEnd": 52}],
         "scenarios": [{"feature": "Voting.feature", "line": 4, "name": "An adult can vote", "ran": [0]}]}
        """
        try json.write(to: run.appendingPathComponent("regions.json"), atomically: true, encoding: .utf8)
        let read = try XCTUnwrap(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertEqual(read.scenarios.map(\.name), ["An adult can vote"])
        XCTAssertEqual(read.scenarios(running: mutant(line: 1, column: 45)).map(\.line), [4])
    }

    func testNoRegionsFileMeansNoCoverage() {
        XCTAssertNil(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertNil(ScenarioCoverage.read(inRunsUnder: folder.appendingPathComponent("missing")))
    }
}
#endif
