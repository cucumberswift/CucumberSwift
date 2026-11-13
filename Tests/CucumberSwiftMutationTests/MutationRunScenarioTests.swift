//
//  MutationRunScenarioTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

/// Which scenarios a mutant's run tests: only the ones that run the mutant's code.
final class MutationRunScenarioTests: TemporaryFolderTestCase {
    private var root: URL!
    private var output: URL!
    private var log = [String]()

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = try makePackage()
        output = folder.appendingPathComponent("reports")
    }

    private func run(_ runner: FakeRunner) -> Int32 {
        var options = MutationOptions(root: root)
        options.output = output
        options.workDirectory = folder.appendingPathComponent("work")
        options.minimumTimeout = 5
        return MutationRun(options: options, discoverer: FakeDiscoverer(), runner: runner) { [weak self] in self?.log.append($0) }.run()
    }

    func testAMutantRunsOnlyTheScenariosThatRunItsCodeAndTheLogCountsThem() throws {
        // Two scenarios ran: the first ran the code of both mutants, the second ran none of it.
        let fake = FakeRunner { call in
            if call.arguments.first == "build" { return .finished(0) }
            if let folder = call.environment["CUCUMBER_COVERAGE_PATH"], call.environment["CUCUMBER_COVERAGE"] == "YES" {
                let voting = CoverageRunFixture.Function(name: "canVote", file: "/x/Sources/Voting/Voting.swift", spans: [[1, 1, 1, 99]])
                let scenarios = [CoverageRunFixture.Scenario(feature: "Voting.feature", line: 4, name: "An adult can vote", ran: [0]),
                                 CoverageRunFixture.Scenario(feature: "Voting.feature", line: 8, name: "A child cannot", ran: [])]
                try? CoverageRunFixture(functions: [voting], scenarios: scenarios).write(named: "1", in: URL(fileURLWithPath: folder))
            }
            return .finished(0, output: "Executed 2 tests")
        }
        XCTAssertEqual(run(fake), MutationRun.Status.completed, log.joined(separator: "\n"))
        let tests = fake.calls.filter { $0.arguments.first == "test" }
        let mutants = tests.filter { $0.environment["CUCUMBERSWIFT_MUTANT"] != nil }
        XCTAssertEqual(mutants.count, 2)
        XCTAssertTrue(mutants.allSatisfy { $0.environment["CUCUMBER_SCENARIOS"] == "Voting.feature:4" })
        XCTAssertTrue(tests.filter { $0.environment["CUCUMBERSWIFT_MUTANT"] == nil }.allSatisfy { $0.environment["CUCUMBER_SCENARIOS"] == nil },
                      "The baseline runs every scenario")
        let lines = log.filter { $0.contains("Survived") }
        XCTAssertEqual(lines.count, 2, log.joined(separator: "\n"))
        XCTAssertTrue(lines.allSatisfy { $0.contains(", 1 of 2 scenarios)") }, lines.joined(separator: "\n"))
    }

    func testAMutantWithoutCoverageRunsEveryScenario() {
        let fake = FakeRunner { call in call.arguments.first == "build" ? .finished(0) : .finished(0, output: "Executed 2 tests") }
        _ = run(fake)
        let mutants = fake.calls.filter { $0.environment["CUCUMBERSWIFT_MUTANT"] != nil }
        XCTAssertFalse(mutants.isEmpty)
        XCTAssertTrue(mutants.allSatisfy { $0.environment["CUCUMBER_SCENARIOS"] == nil })
        XCTAssertFalse(log.contains { $0.contains(" scenarios)") }, "No count: every scenario ran")
    }
}
