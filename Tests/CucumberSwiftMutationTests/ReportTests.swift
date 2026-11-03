//
//  ReportTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class ReportTests: XCTestCase {
    private func mutant(_ id: Int, replacement: String = ">") -> Mutant {
        Mutant(id: id, file: "Sources/Voting/Voting.swift", line: 1, column: 45, endLine: 1, endColumn: 47, offset: 44, length: 2,
               original: ">=", replacement: replacement, mutator: "RelationalOperator")
    }

    private func results() -> [MutantResult] {
        [MutantResult(mutant: mutant(1, replacement: "<"), verdict: .killed(by: ["An adult can vote :: Then the person can vote"]), duration: 3),
         MutantResult(mutant: mutant(2), verdict: .survived, duration: 3),
         MutantResult(mutant: mutant(3, replacement: "=="), verdict: .unviable, duration: 1),
         MutantResult(mutant: mutant(4, replacement: "!="), verdict: .timedOut, duration: 30)]
    }

    func testTheScoreCountsKilledAndTimedOutAsDetectedAndLeavesOutWhatDidNotBuild() {
        let score = MutationScore(results())
        XCTAssertEqual(score.detected, 2)
        XCTAssertEqual(score.counted, 3)
        XCTAssertEqual(try XCTUnwrap(score.percent), 66.67, accuracy: 0.01)
    }

    func testNoScoreWhenNothingWasCounted() {
        XCTAssertNil(MutationScore([]).percent)
        XCTAssertNil(MutationScore([MutantResult(mutant: mutant(1), verdict: .unviable, duration: 1)]).percent)
    }

    func testTheStrykerReportHasTheFieldsItsSchemaRequires() throws {
        let data = try StrykerReport(results: results(), sources: ["Sources/Voting/Voting.swift": "source"]).encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? String, "2")
        XCTAssertEqual((json["thresholds"] as? [String: Int])?["high"], 80)
        let framework = try XCTUnwrap(json["framework"] as? [String: Any])
        XCTAssertNotNil((framework["branding"] as? [String: String])?["homepageUrl"], "The schema requires the branding's homepage")
        let file = try XCTUnwrap((json["files"] as? [String: [String: Any]])?["Sources/Voting/Voting.swift"])
        XCTAssertEqual(file["language"] as? String, "swift")
        XCTAssertEqual(file["source"] as? String, "source")
        let mutants = try XCTUnwrap(file["mutants"] as? [[String: Any]])
        XCTAssertEqual(mutants.compactMap { $0["status"] as? String }, ["Killed", "Survived", "CompileError", "Timeout"])
        XCTAssertEqual(mutants.first?["id"] as? String, "1")
        XCTAssertEqual(mutants.first?["statusReason"] as? String, "An adult can vote :: Then the person can vote")
        let start = try XCTUnwrap((mutants.first?["location"] as? [String: [String: Int]])?["start"])
        XCTAssertEqual(start, ["line": 1, "column": 45])
    }

    private let cucumberReport = """
    [{"name":"Voting","elements":[
      {"name":"An adult can vote","steps":[
        {"keyword":"Given ","name":"a person aged 30","result":{"status":"passed"}},
        {"keyword":"Then ","name":"the person can vote","result":{"status":"failed"}}]},
      {"name":"A child cannot vote","steps":[
        {"keyword":"Given ","name":"a person aged 5","result":{"status":"passed"}},
        {"keyword":"Then ","name":"the person cannot vote","result":{"status":"passed"}}]}]}]
    """

    private func steps(of annotated: CucumberReportAnnotator.Annotated) throws -> [[String: Any]] {
        let features = try XCTUnwrap(JSONSerialization.jsonObject(with: annotated.data) as? [[String: Any]])
        return try (features[0]["elements"] as? [[String: Any]] ?? []).flatMap { try XCTUnwrap($0["steps"] as? [[String: Any]]) }
    }

    func testAKilledMutantIsNotedOnTheFailedStep() throws {
        let result = MutantResult(mutant: mutant(1, replacement: "<"), verdict: .killed(by: []), duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        XCTAssertEqual(annotated.failedSteps, ["An adult can vote :: Then the person can vote"])
        let noted = try steps(of: annotated).map { ($0["embeddings"] as? [[String: String]])?.count ?? 0 }
        XCTAssertEqual(noted, [0, 1, 0, 0])
    }

    func testTheNoteIsJSONThatNamesTheMutantItsPlaceAndItsStatus() throws {
        let result = MutantResult(mutant: mutant(1, replacement: "<"), verdict: .killed(by: []), duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        let embedding = try XCTUnwrap(try steps(of: annotated)[1]["embeddings"] as? [[String: String]])
        XCTAssertEqual(embedding[0]["mime_type"], "application/json")
        let note = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(base64Encoded: embedding[0]["data"] ?? "") ?? Data()) as? [String: Any])
        XCTAssertEqual(note["status"] as? String, "Killed")
        XCTAssertEqual(note["change"] as? String, ">= → <")
        XCTAssertEqual(note["location"] as? String, "Sources/Voting/Voting.swift:1:45")
        XCTAssertEqual(note["mutant"] as? Int, 1)
    }

    func testASurvivorIsNotedOnTheLastStepOfEachScenarioThatRan() throws {
        let result = MutantResult(mutant: mutant(2), verdict: .survived, duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        let noted = try steps(of: annotated).map { ($0["embeddings"] as? [[String: String]])?.count ?? 0 }
        XCTAssertEqual(noted, [0, 1, 0, 1])
    }

    func testAReportThatIsNotCucumberJSONIsLeftAlone() {
        let result = MutantResult(mutant: mutant(1), verdict: .survived, duration: 1)
        XCTAssertNil(CucumberReportAnnotator.annotate(Data("not json".utf8), result: result))
        XCTAssertNil(CucumberReportAnnotator.annotate(Data("{}".utf8), result: result))
    }

    func testTheSummaryListsTheSurvivorsWithTheirPlace() {
        let text = MutationSummary.text(results: results(), duration: 41)
        XCTAssertTrue(text.contains("Mutation score: 66.7% (2 of 3 mutants detected)"), text)
        XCTAssertTrue(text.contains("Killed 1, timed out 1, survived 1, did not build 1"), text)
        XCTAssertTrue(text.contains("Sources/Voting/Voting.swift:1:45 RelationalOperator >= → >"), text)
    }
}
