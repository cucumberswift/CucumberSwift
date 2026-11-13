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

    func testReadsTheManifestOfARun() throws {
        let canVote = CoverageRunFixture.Function(name: "canVote", file: "/copy/Sources/Voting/Voting.swift", spans: [[1, 40, 1, 52]])
        let adult = CoverageRunFixture.Scenario(feature: "file:///t/VotingTests.xctest/Features/Voting.feature", line: 4, name: "An adult can vote", ran: [0])
        try CoverageRunFixture(functions: [canVote], scenarios: [adult]).write(named: "ABC", in: folder)
        let read = try XCTUnwrap(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertEqual(read.scenarios.map(\.name), ["An adult can vote"])
        XCTAssertEqual(read.scenarios(running: mutant(line: 1, column: 45)), [ScenarioID(feature: "Features/Voting.feature", line: 4, name: "An adult can vote")])
    }

    func testNoFinishedRunMeansNoCoverage() throws {
        XCTAssertNil(try ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertNil(try ScenarioCoverage.read(inRunsUnder: folder.appendingPathComponent("missing")))
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("run-empty"), withIntermediateDirectories: true)
        XCTAssertNil(try ScenarioCoverage.read(inRunsUnder: folder), "A run folder without a manifest didn't finish")
    }

    func testARunThatMeasuredNoCodeMeansNoCoverage() throws {
        let adult = CoverageRunFixture.Scenario(feature: "Voting.feature", line: 4, name: "An adult can vote", ran: [])
        try CoverageRunFixture(functions: [], scenarios: [adult]).write(named: "ABC", in: folder)
        XCTAssertNil(try ScenarioCoverage.read(inRunsUnder: folder), "Without measured code, every mutant is tested")
    }

    func testARunWithoutThePlacesOfItsRegionsIsAnError() throws {
        let canVote = CoverageRunFixture.Function(name: "canVote", file: "/copy/Sources/Voting/Voting.swift", spans: nil, regionCount: 2)
        try CoverageRunFixture(functions: [canVote], scenarios: []).write(named: "ABC", in: folder)
        XCTAssertThrowsError(try ScenarioCoverage.read(inRunsUnder: folder)) { error in
            XCTAssertEqual(error as? ScenarioCoverage.ReadError, .noRegionPlaces(file: "/copy/Sources/Voting/Voting.swift"))
        }
    }
}
#endif
