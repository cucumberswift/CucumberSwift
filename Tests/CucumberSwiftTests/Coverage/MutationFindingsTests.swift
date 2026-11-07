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

    /// A report in the format `cucumberswift-mutation-test` writes: three mutants on line 2 of Voting.swift, and one in
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
    private func regions(file: String, line: Int, column _: Int?) -> Set<Int> {
        file.hasSuffix("Voting.swift") && line == 2 ? [7] : []
    }

    /// The findings, with each file reading as `current` returns: as the report recorded it by default.
    private func findings(_ statuses: [String] = ["Killed", "Survived", "Killed"],
                          scenarios: [CoverageScores.Scenario],
                          current: @escaping (String, MutationReport) -> String? = { file, report in report.sources[file] }) throws -> MutationFindings? {
        let report = try report(statuses)
        let code = MutationFindings.CodeLookup(regions: regions) { file in current(file, report) }
        return MutationFindings.make(report: report, scenarios: scenarios, code: code, file: featureFile, featureLine: 1)
    }

    func testReadsEachMutantsFileLineChangeAndStatus() throws {
        let read = try report()
        let voting = read.mutants.filter { $0.file == "Sources/Voting/Voting.swift" }
        XCTAssertEqual(voting.map(\.original), [">=", ">=", "&&"])
        XCTAssertEqual(voting.map(\.replacement), ["<", ">", "||"])
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
        XCTAssertEqual(findings.survived, 1)
    }

    func testASurvivorIsAnErrorOnTheFeatureAndOnEachScenarioThatRunsItsCode() throws {
        let scenarios = [
            scenario("A registered adult can vote", line: 4, regions: [7]),
            scenario("A child cannot vote", line: 8, regions: [7]),
            scenario("Elsewhere", line: 12, regions: [3])
        ]
        let findings = try XCTUnwrap(try findings(scenarios: scenarios))
        XCTAssertEqual(findings.issues.map(\.line), [1, 4, 8], "The feature line, then the 2 scenarios that run line 2")
        // Errors, so that the feature's Mutation test fails.
        XCTAssertTrue(findings.issues.allSatisfy { $0.kind == .mutation && $0.severity == .error && $0.file == featureFile })
        XCTAssertTrue(findings.issues[0].message.hasPrefix("Mutation testing: the scenarios still pass after 1 of the 3 changes"), findings.issues[0].message)
        XCTAssertEqual(findings.issues[1].message, "This scenario still passes when >= at Voting.swift:2 is changed to >. Add a step that checks this code.")
    }

    func testNoIssuesWhenEveryMutantInTheFeaturesCodeWasDetected() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7])]
        let findings = try XCTUnwrap(try findings(["Killed", "Timeout", "Killed"], scenarios: scenarios))
        XCTAssertEqual(findings.survived, 0)
        XCTAssertEqual(findings.issues, [], "Nothing to fail: the Mutation test passes")
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

    func testAFileThatChangedSinceTheReportMakesItsMutantsAnOutOfDateError() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7])]
        let findings = try XCTUnwrap(try findings(scenarios: scenarios) { file, report in
            (report.sources[file] ?? "") + (file.hasSuffix("Voting.swift") ? "// edited\n" : "")
        })
        // Nothing is scored from a report about other code: one error that says to run it again.
        XCTAssertEqual(findings.counted, 0)
        XCTAssertEqual(findings.issues.count, 1)
        XCTAssertEqual(findings.issues.first?.severity, .error)
        XCTAssertTrue(findings.issues.first?.message.hasPrefix("The mutation report is out of date: Voting.swift changed after it was written") ?? false,
                      "\(findings.issues)")
    }

    func testAFileThatCantBeReadCountsAsUnchanged() throws {
        let scenarios = [scenario("A registered adult can vote", line: 4, regions: [7])]
        let findings = try XCTUnwrap(try findings(scenarios: scenarios) { _, _ in "" })
        // An empty text is a file that reads differently. A file that can't be read at all is nil.
        XCTAssertEqual(findings.counted, 0)
        let unreadable = try XCTUnwrap(try self.findings(scenarios: scenarios) { _, _ in nil })
        XCTAssertEqual(unreadable.counted, 3)
    }

    func testAMutantsTextCanSpanLines() {
        let source = "let a = 1\nsave(\n    order)\n"
        XCTAssertEqual(MutationReport.text(in: source, from: (2, 1), to: (3, 11)), "save(\n    order)")
        XCTAssertEqual(MutationReport.text(in: source, from: (1, 5), to: (1, 6)), "a")
        XCTAssertEqual(MutationReport.text(in: source, from: (9, 1), to: (9, 2)), "", "A line that isn't there")
        XCTAssertEqual(MutationReport.text(in: source, from: (1, 6), to: (1, 5)), "", "An end before its start")
    }

    func testAKillCountsForTheScenariosTheReportNamesOrForEveryScenarioThatRunsTheCode() throws {
        let source = "public struct Voter {\n    var canVote: Bool { age >= 18 && isRegistered }\n}\n"
        func mutant(_ id: String, _ column: Int, killedBy: [String]?) -> [String: Any] {
            let location = ["start": ["line": 2, "column": column], "end": ["line": 2, "column": column + 2]]
            var entry: [String: Any] = ["id": id, "mutatorName": "RelationalOperator", "replacement": "<", "status": "Killed", "location": location]
            entry["killedBy"] = killedBy
            return entry
        }
        // The first names the scenario at line 4, the second names none, as when the change crashed the tests, and the
        // third names a scenario of another feature.
        let mutants = [
            mutant("1", 29, killedBy: ["Features/Voting.feature:4"]),
            mutant("2", 35, killedBy: nil),
            mutant("3", 29, killedBy: ["Features/Other.feature:4"])
        ]
        let file: [String: Any] = ["language": "swift", "source": source, "mutants": mutants]
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("kills-\(UUID().uuidString).json").path
        try JSONSerialization.data(withJSONObject: ["schemaVersion": "2", "files": ["Sources/Voting/Voting.swift": file]])
            .write(to: URL(fileURLWithPath: path))
        defer { try? FileManager.default.removeItem(atPath: path) }
        guard case .success(let report) = MutationReport.read(path: path) else { return XCTFail("unreadable") }
        XCTAssertEqual(report.mutants.first?.killedBy, [MutationReport.Scenario(feature: "Features/Voting.feature", line: 4)])
        let code = MutationFindings.CodeLookup(regions: regions) { report.sources[$0] }
        let findings = try XCTUnwrap(MutationFindings.make(report: report,
                                                           scenarios: [scenario("Adult", line: 4, regions: [7]), scenario("Child", line: 9, regions: [7])],
                                                           code: code,
                                                           file: featureFile,
                                                           featureLine: 1,
                                                           feature: MutationReport.feature(ofURI: "file:///tmp/Voting_VotingTests.bundle/Features/Voting.feature")))
        XCTAssertEqual(findings.kills, [4: ["1", "2"], 9: ["2"]])
        XCTAssertEqual(findings.changes["1"], ">= at Voting.swift:2 is changed to <")
        XCTAssertFalse(findings.isOutOfDate)
    }

    /// The findings for `scenarios` of the feature at `feature`, from a report whose run tested `ran`.
    private func findings(ran: [String], feature: String, scenarios: [CoverageScores.Scenario]) throws -> MutationFindings? {
        let source = "let a = b > c\n"
        let location = ["start": ["line": 1, "column": 11], "end": ["line": 1, "column": 12]]
        let mutant: [String: Any] = ["id": "1", "mutatorName": "RelationalOperator", "replacement": ">=", "status": "Killed", "location": location]
        let tests = ran.map { ["id": $0, "name": $0] }
        let file: [String: Any] = ["language": "swift", "source": source, "mutants": [mutant]]
        let json: [String: Any] = ["schemaVersion": "2", "files": ["Sources/Voting/Voting.swift": file], "testFiles": ["Features": ["tests": tests]]]
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ran-\(UUID().uuidString).json").path
        try JSONSerialization.data(withJSONObject: json).write(to: URL(fileURLWithPath: path))
        defer { try? FileManager.default.removeItem(atPath: path) }
        guard case .success(let report) = MutationReport.read(path: path) else { throw XCTSkip("unreadable report") }
        let code = MutationFindings.CodeLookup(regions: { _, _, _ in [7] }, currentSource: { report.sources[$0] })
        return MutationFindings.make(report: report, scenarios: scenarios, code: code, file: featureFile, featureLine: 1, feature: feature)
    }

    func testAReportFromARunWithOtherTagsFailsTheMutationTest() throws {
        // The command ran the @before scenarios of Basket.feature; the tests run the @after ones of Basket-killed.feature.
        let found = try XCTUnwrap(try findings(ran: ["Features/Basket.feature:5", "Features/Basket.feature:9"],
                                               feature: "Features/Basket-killed.feature",
                                               scenarios: [scenario("Two items", line: 5, regions: [7]), scenario("Three items", line: 9, regions: [7])]))
        XCTAssertTrue(found.isOutOfDate, "The redundancy compares the scenarios by code alone")
        XCTAssertEqual(found.counted, 0)
        XCTAssertEqual(found.issues.map(\.severity), [.error])
        XCTAssertEqual(found.issues.first?.line, 1)
        XCTAssertTrue(found.issues.first?.message.hasPrefix("The mutation report is from a run of other scenarios: the scenarios at lines 5, 9 weren't in it") ?? false,
                      "\(found.issues)")
        XCTAssertTrue(found.issues.first?.message.hasSuffix("Run `cucumberswift-mutation-test` with the same CUCUMBER_TAGS as these tests.") ?? false)
    }

    func testAReportMissingOneOfTheFeaturesScenariosNamesIt() throws {
        let found = try XCTUnwrap(try findings(ran: ["Features/Basket.feature:5"],
                                               feature: "Features/Basket.feature",
                                               scenarios: [scenario("Two items", line: 5, regions: [7]), scenario("Three items", line: 9, regions: [7])]))
        XCTAssertTrue(found.issues.first?.message.contains("the scenario at line 9 wasn't in it") ?? false, "\(found.issues)")
    }

    func testAReportFromARunOfTheSameScenariosIsScored() throws {
        let found = try XCTUnwrap(try findings(ran: ["Features/Basket.feature:5", "Features/Basket.feature:9", "Features/Other.feature:3"],
                                               feature: "Features/Basket.feature",
                                               scenarios: [scenario("Two items", line: 5, regions: [7]), scenario("Three items", line: 9, regions: [7])]))
        XCTAssertFalse(found.isOutOfDate)
        XCTAssertEqual(found.counted, 1)
        XCTAssertEqual(found.issues, [])
    }

    func testAReportThatDoesntListItsScenariosIsScored() throws {
        let found = try XCTUnwrap(try findings(ran: [], feature: "Features/Basket.feature", scenarios: [scenario("Two items", line: 5, regions: [7])]))
        XCTAssertEqual(found.counted, 1)
    }

    func testARemovedCallIsDescribedAsRemoved() throws {
        let source = "func checkout() {\n    save(order)\n}\n"
        let location = ["start": ["line": 2, "column": 5], "end": ["line": 2, "column": 16]]
        let mutant: [String: Any] = ["id": "1", "mutatorName": "RemoveCall", "replacement": "", "status": "Survived", "location": location]
        let file: [String: Any] = ["language": "swift", "source": source, "mutants": [mutant]]
        let json: [String: Any] = ["schemaVersion": "2", "files": ["Sources/Shop/Shop.swift": file]]
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("remove-\(UUID().uuidString).json").path
        try JSONSerialization.data(withJSONObject: json).write(to: URL(fileURLWithPath: path))
        defer { try? FileManager.default.removeItem(atPath: path) }
        guard case .success(let report) = MutationReport.read(path: path) else { return XCTFail("unreadable") }
        let code = MutationFindings.CodeLookup(regions: { _, _, _ in [1] }, currentSource: { report.sources[$0] })
        let findings = MutationFindings.make(report: report,
                                             scenarios: [scenario("Checking out", line: 3, regions: [1])],
                                             code: code,
                                             file: featureFile,
                                             featureLine: 1)
        XCTAssertEqual(findings?.issues.last?.message, "This scenario still passes when save(order) at Shop.swift:2 is removed. Add a step that checks this code.")
    }

    func testMutationTestingIsAnOptInOfItsOwn() {
        XCTAssertFalse(CoverageSettings.read(environment: [:]).isMutationTesting)
        XCTAssertTrue(CoverageSettings.read(environment: ["CUCUMBER_MUTATION_TESTING": "YES"]).isMutationTesting)
        Cucumber.mutationTesting = false
        defer { Cucumber.mutationTesting = nil }
        XCTAssertFalse(CoverageSettings.read(environment: ["CUCUMBER_MUTATION_TESTING": "YES"]).isMutationTesting)
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
