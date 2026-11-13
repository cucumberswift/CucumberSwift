//
//  ScenarioCoverageMergeTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class ScenarioCoverageMergeTests: TemporaryFolderTestCase {
    private func function(_ name: String, lines: [Int]) -> CoverageRunFixture.Function {
        CoverageRunFixture.Function(name: name, file: "/x/Sources/Voting/Voting.swift", spans: lines.map { [$0, 1, $0, 9] })
    }

    private func scenario(_ name: String, line: Int, ran: [Int]) -> CoverageRunFixture.Scenario {
        CoverageRunFixture.Scenario(feature: "file:///t/VotingTests.xctest/Features/\(name).feature", line: line, name: name, ran: ran)
    }

    func testTheRunsOfOneTestBinaryShareItsRegions() throws {
        // `swift test` runs XCTest and Swift Testing in two processes of one binary, and each writes a run folder.
        let functions = [function("canVote", lines: [10, 14]), function("canRetire", lines: [18])]
        try CoverageRunFixture(functions: functions, scenarios: [scenario("a", line: 3, ran: [0])]).write(named: "xctest", in: folder)
        try CoverageRunFixture(functions: functions, scenarios: [scenario("b", line: 3, ran: [2])]).write(named: "swift-testing", in: folder)
        let coverage = try XCTUnwrap(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertEqual(coverage.regions.map(\.lineStart), [10, 14, 18], "Each region of the binary is kept once")
        XCTAssertEqual(coverage.scenarios.map(\.name).sorted(), ["a", "b"])
        XCTAssertEqual(coverage.scenarios(running: Mutant.fixture(line: 18, column: 5)).map(\.name), ["b"])
        XCTAssertEqual(coverage.scenarios(running: Mutant.fixture(line: 10, column: 5)).map(\.name), ["a"])
    }

    func testCodeThatTwoTestBundlesMeasureCountsTheScenariosOfBoth() throws {
        // An Xcode scheme can run two test bundles that both link the code: each binary measures its own copy.
        var first = CoverageRunFixture(functions: [function("canVote", lines: [14])], scenarios: [scenario("a", line: 3, ran: [0])])
        first.binary = "FirstTests"
        var second = CoverageRunFixture(functions: [function("canVote", lines: [14])], scenarios: [scenario("b", line: 3, ran: [0])])
        second.binary = "SecondTests"
        try first.write(named: "A", in: folder)
        try second.write(named: "B", in: folder)
        let coverage = try XCTUnwrap(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertEqual(coverage.scenarios(running: Mutant.fixture(line: 14, column: 5)).map(\.name).sorted(), ["a", "b"])
    }
}
#endif
