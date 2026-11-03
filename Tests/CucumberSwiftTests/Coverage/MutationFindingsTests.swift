//
//  MutationFindingsTests.swift
//  CucumberSwiftTests
//
//  With a mutation report, each feature gets a Mutation score: of the mutants in the code that its
//  scenarios run, the share that a test detected, and a warning on each scenario that runs a survivor.
//

import Foundation
import XCTest
@testable import CucumberSwift

final class MutationFindingsTests: XCTestCase {
    private let featureFile = URL(string: "file:///tmp/Voting.feature")

    /// A report in the format `swift package mutation-test` writes: three mutants on line 2 of Voting.swift, and one in
    /// another file.
    private func writeReport(_ statuses: [String] = ["Killed", "Survived", "Killed"]) throws -> String {
        let source = "public struct Voter {\n    var canVote: Bool { age >= 18 && isRegistered }\n}\n"
        let mutants = zip(statuses, [(29, 31, "<"), (29, 31, ">"), (35, 37, "||")]).enumerated().map { index, entry in
            let (status, (start, end, replacement)) = entry
            return """
            {"id": "\(index + 1)", "mutatorName": "RelationalOperator", "replacement": "\(replacement)", "status": "\(status)",
             "location": {"start": {"line": 2, "column": \(start)}, "end": {"line": 2, "column": \(end)}}}
            """
        }
        let json = """
        {"schemaVersion": "2", "files": {
          "Sources/Voting/Voting.swift": {"language": "swift", "source": \(String(reflecting: source)), "mutants": [\(mutants.joined(separator: ","))]},
          "Sources/Other/Other.swift": {"language": "swift", "source": "let a = b > c\\n", "mutants": [
            {"id": "9", "mutatorName": "RelationalOperator", "replacement": ">=", "status": "Survived",
             "location": {"start": {"line": 1, "column": 11}, "end": {"line": 1, "column": 12}}}]}}}
        """
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("mutation-report-\(UUID().uuidString).json").path
        try json.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private func report(_ statuses: [String] = ["Killed", "Survived", "Killed"]) throws -> MutationReport {
        let path = try writeReport(statuses)
        defer { try? FileManager.default.removeItem(atPath: path) }
        guard case .success(let report) = MutationReport.read(path: path) else { throw XCTSkip("unreadable report") }
        return report
    }

    private func scenario(_ name: String, line: Int, regions: Set<Int>) -> CoverageScores.Scenario {
        CoverageScores.Scenario(name: name, line: line, tags: [], duration: 1, regions: regions)
    }

    /// Region 7 is line 2 of Voting.swift; Other.swift is code that no scenario runs.
    private func regions(file: String, line: Int) -> Set<Int> {
        file.hasSuffix("Voting.swift") && line == 2 ? [7] : []
    }

    private func findings(_ statuses: [String] = ["Killed", "Survived", "Killed"], scenarios: [CoverageScores.Scenario]) throws -> MutationFindings? {
        MutationFindings.make(report: try report(statuses), scenarios: scenarios, regions: regions, file: featureFile, featureLine: 1)
    }

    func testReadsEachMutantsFileLineChangeAndStatus() throws {
        let read = try report()
        let voting = read.mutants.filter { $0.file == "Sources/Voting/Voting.swift" }
        XCTAssertEqual(voting.map(\.change), [">= to <", ">= to >", "&& to ||"])
        XCTAssertEqual(voting.map(\.status), ["Killed", "Survived", "Killed"])
        XCTAssertEqual(voting.map(\.line), [2, 2, 2])
        XCTAssertNotNil(read.date)
    }

    func testAMissingOrForeignReportIsAnErrorThatSaysWhy() throws {
        guard case .failure(let missing) = MutationReport.read(path: "/nonexistent/mutation-report.json") else { return XCTFail("read a missing report") }
        XCTAssertTrue(missing.message.contains("no mutation report"), missing.message)
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("not-a-report.json").path
        try "[1, 2]".write(toFile: path, atomically: true, encoding: .utf8)
        guard case .failure(let foreign) = MutationReport.read(path: path) else { return XCTFail("read a foreign file") }
        XCTAssertTrue(foreign.message.contains("Stryker"), foreign.message)
    }

    func testTheScoreCountsOnlyTheMutantsInTheCodeTheFeaturesScenariosRun() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7, 8])]
        let findings = try XCTUnwrap(try findings(scenarios: scenarios))
        // The survivor in Other.swift is in code that no scenario runs, so it doesn't count.
        XCTAssertEqual(findings.counted, 3)
        XCTAssertEqual(findings.detected, 2)
        XCTAssertEqual(findings.percent, 200.0 / 3, accuracy: 0.01)
    }

    func testASurvivorGetsAWarningOnEachScenarioThatRunsItsCode() throws {
        let scenarios = [
            scenario("A registered adult can vote", line: 4, regions: [7]),
            scenario("A child cannot vote", line: 8, regions: [7]),
            scenario("Elsewhere", line: 12, regions: [3])
        ]
        let findings = try XCTUnwrap(try findings(scenarios: scenarios))
        XCTAssertEqual(findings.issues.map(\.line), [1, 4, 8], "The feature line, then the 2 scenarios that run line 2")
        XCTAssertTrue(findings.issues.allSatisfy { $0.kind == .mutation && $0.severity == .warning && $0.file == featureFile })
        XCTAssertTrue(findings.issues[0].message.hasPrefix("Mutation score 67%: its scenarios detected 2 of the 3 mutants"), findings.issues[0].message)
        XCTAssertTrue(findings.issues[1].message.contains("changing >= to > at Voting.swift:2"), findings.issues[1].message)
    }

    func testNoIssuesWhenEveryMutantInTheFeaturesCodeWasDetected() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7])]
        let findings = try XCTUnwrap(try findings(["Killed", "Timeout", "Killed"], scenarios: scenarios))
        XCTAssertEqual(findings.percent, 100)
        XCTAssertEqual(findings.issues, [])
    }

    func testAMutantThatDidNotBuildIsLeftOut() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7])]
        let findings = try XCTUnwrap(try findings(["Killed", "CompileError", "Killed"], scenarios: scenarios))
        XCTAssertEqual(findings.counted, 2)
        XCTAssertEqual(findings.issues, [])
    }

    func testAFeatureWhoseScenariosRunNoMutantsCodeHasNoScore() throws {
        let scenarios = [scenario("Elsewhere", line: 4, regions: [3])]
        XCTAssertNil(try findings(scenarios: scenarios))
    }

    func testTheSettingReadsTheStaticVariableThenTheEnvironmentVariable() {
        XCTAssertNil(CoverageSettings.read(environment: [:]).mutationReport)
        XCTAssertNil(CoverageSettings.read(environment: ["CUCUMBER_MUTATION_REPORT": "  "]).mutationReport)
        XCTAssertEqual(CoverageSettings.read(environment: ["CUCUMBER_MUTATION_REPORT": "/a.json"]).mutationReport, "/a.json")
        Cucumber.mutationReport = "/b.json"
        defer { Cucumber.mutationReport = nil }
        XCTAssertEqual(CoverageSettings.read(environment: ["CUCUMBER_MUTATION_REPORT": "/a.json"]).mutationReport, "/b.json")
    }
}
