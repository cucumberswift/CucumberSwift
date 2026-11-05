//
//  ReportTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class ReportTests: XCTestCase {
    private let cucumberReport = """
    [{"name":"Voting","uri":"file:///tmp/Voting_VotingTests.bundle/Features/Voting.feature","elements":[
      {"name":"An adult can vote","line":3,"steps":[
        {"keyword":"Given ","name":"a person aged 30","result":{"status":"passed"}},
        {"keyword":"Then ","name":"the person can vote","result":{"status":"failed"}}]},
      {"name":"A child cannot vote","line":7,"steps":[
        {"keyword":"Given ","name":"a person aged 5","result":{"status":"passed"}},
        {"keyword":"Then ","name":"the person cannot vote","result":{"status":"passed"}}]}]}]
    """

    private func results() -> [MutantResult] {
        let killedBy = ["An adult can vote :: Then the person can vote"]
        return [
            MutantResult(mutant: Mutant.fixture(id: 1, replacement: "<"), verdict: .killed(by: killedBy), duration: 3),
            MutantResult(mutant: Mutant.fixture(id: 2), verdict: .survived, duration: 3),
            MutantResult(mutant: Mutant.fixture(id: 3, replacement: "=="), verdict: .unviable, duration: 1),
            MutantResult(mutant: Mutant.fixture(id: 4, replacement: "!="), verdict: .timedOut, duration: 30)
        ]
    }

    func testTheScoreCountsKilledAndTimedOutAsDetectedAndLeavesOutWhatDidNotBuild() {
        let score = MutationScore(results())
        XCTAssertEqual(score.detected, 2)
        XCTAssertEqual(score.counted, 3)
        XCTAssertEqual(try XCTUnwrap(score.percent), 66.67, accuracy: 0.01)
    }

    func testOnlyAKilledOrTimedOutMutantIsDetected() {
        let verdicts: [Verdict] = [.killed(by: []), .timedOut, .survived, .unviable, .ignored(reason: ""), .noCoverage]
        XCTAssertEqual(verdicts.map(\.isDetected), [true, true, false, false, false, false])
    }

    func testNoScoreWhenNothingWasCounted() {
        XCTAssertNil(MutationScore([]).percent)
        XCTAssertNil(MutationScore([MutantResult(mutant: Mutant.fixture(id: 1), verdict: .unviable, duration: 1)]).percent)
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

    private func steps(of annotated: CucumberReportAnnotator.Annotated) throws -> [[String: Any]] {
        let features = try XCTUnwrap(JSONSerialization.jsonObject(with: annotated.data) as? [[String: Any]])
        return try (features[0]["elements"] as? [[String: Any]] ?? []).flatMap { try XCTUnwrap($0["steps"] as? [[String: Any]]) }
    }

    func testAKilledMutantIsNotedOnTheFailedStep() throws {
        let result = MutantResult(mutant: Mutant.fixture(id: 1, replacement: "<"), verdict: .killed(by: []), duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        XCTAssertEqual(annotated.failedSteps, ["An adult can vote :: Then the person can vote"])
        let noted = try steps(of: annotated).map { ($0["embeddings"] as? [[String: String]])?.count ?? 0 }
        XCTAssertEqual(noted, [0, 1, 0, 0])
    }

    func testTheNoteIsJSONThatNamesTheMutantItsPlaceAndItsStatus() throws {
        let result = MutantResult(mutant: Mutant.fixture(id: 1, replacement: "<"), verdict: .killed(by: []), duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        let embedding = try XCTUnwrap(try steps(of: annotated)[1]["embeddings"] as? [[String: String]])
        XCTAssertEqual(embedding[0]["mime_type"], "application/json")
        let note = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(base64Encoded: embedding[0]["data"] ?? "") ?? Data()) as? [String: Any])
        XCTAssertEqual(note["status"] as? String, "Killed")
        XCTAssertEqual(note["change"] as? String, ">= → <")
        XCTAssertEqual(note["location"] as? String, "Sources/Voting/Voting.swift:1:45")
        XCTAssertEqual(note["mutant"] as? Int, 1)
    }

    func testTheFailedScenariosAreNamedByTheirFeatureInsideTheBundleAndTheirLine() throws {
        let result = MutantResult(mutant: Mutant.fixture(id: 1, replacement: "<"), verdict: .killed(by: []), duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        XCTAssertEqual(annotated.failedScenarios, [ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")])
        XCTAssertEqual(annotated.failedScenarios.first?.id, "Features/Voting.feature:3")
    }

    func testAScenarioIsNamedByItsFeaturesPathInsideTheTestBundle() {
        XCTAssertEqual(ScenarioID.feature(ofURI: "file:///tmp/Shop_ShopTests.bundle/Features/Basket.feature"), "Features/Basket.feature")
        XCTAssertEqual(ScenarioID.feature(ofURI: "/Users/me/DerivedData/ShopTests.xctest/Features/Basket.feature"), "Features/Basket.feature")
        XCTAssertEqual(ScenarioID.feature(ofURI: "file:///tmp/My%20Tests.xctest/Features/My%20Basket.feature"), "Features/My Basket.feature")
        XCTAssertEqual(ScenarioID.feature(ofURI: "/tmp/Features/Basket.feature"), "/tmp/Features/Basket.feature")
    }

    func testTheStrykerReportNamesTheScenariosThatKilledAndRanEachMutant() throws {
        let adult = ScenarioID(feature: "Features/Voting.feature", line: 3, name: "An adult can vote")
        let child = ScenarioID(feature: "Features/Voting.feature", line: 7, name: "A child cannot vote")
        let results = [
            MutantResult(mutant: Mutant.fixture(id: 1), verdict: .killed(by: []), duration: 1, coveredBy: [child, adult], killedBy: [adult]),
            MutantResult(mutant: Mutant.fixture(id: 2), verdict: .survived, duration: 1, coveredBy: [child])
        ]
        let data = try StrykerReport(results: results, sources: [:]).encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let mutants = try XCTUnwrap((json["files"] as? [String: [String: Any]])?["Sources/Voting/Voting.swift"]?["mutants"] as? [[String: Any]])
        XCTAssertEqual(mutants[0]["killedBy"] as? [String], ["Features/Voting.feature:3"])
        XCTAssertEqual(mutants[0]["coveredBy"] as? [String], ["Features/Voting.feature:7", "Features/Voting.feature:3"])
        XCTAssertNil(mutants[1]["killedBy"])
        let tests = try XCTUnwrap((json["testFiles"] as? [String: [String: Any]])?["Features/Voting.feature"]?["tests"] as? [[String: Any]])
        XCTAssertEqual(tests.compactMap { $0["id"] as? String }, ["Features/Voting.feature:3", "Features/Voting.feature:7"])
        XCTAssertEqual(tests.first?["name"] as? String, "An adult can vote")
    }

    func testTheReportListsEveryScenarioOfTheRunWithoutAChange() throws {
        let ran = try XCTUnwrap(CucumberReportAnnotator.scenarios(in: Data(cucumberReport.utf8)))
        XCTAssertEqual(ran.map(\.id), ["Features/Voting.feature:3", "Features/Voting.feature:7"])
        let data = try StrykerReport(results: [], sources: [:], ran: ran).encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let tests = try XCTUnwrap((json["testFiles"] as? [String: [String: Any]])?["Features/Voting.feature"]?["tests"] as? [[String: Any]])
        XCTAssertEqual(tests.compactMap { $0["id"] as? String }, ["Features/Voting.feature:3", "Features/Voting.feature:7"])
        XCTAssertNil(CucumberReportAnnotator.scenarios(in: Data("not json".utf8)))
    }

    func testAStrykerReportWithoutScenariosHasNoTestFiles() throws {
        let data = try StrykerReport(results: results(), sources: [:]).encoded()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(json["testFiles"])
    }

    func testASurvivorIsNotedOnTheLastStepOfEachScenarioThatRan() throws {
        let result = MutantResult(mutant: Mutant.fixture(id: 2), verdict: .survived, duration: 1)
        let annotated = try XCTUnwrap(CucumberReportAnnotator.annotate(Data(cucumberReport.utf8), result: result))
        let noted = try steps(of: annotated).map { ($0["embeddings"] as? [[String: String]])?.count ?? 0 }
        XCTAssertEqual(noted, [0, 1, 0, 1])
    }

    func testAReportThatIsNotCucumberJSONIsLeftAlone() {
        let result = MutantResult(mutant: Mutant.fixture(id: 1), verdict: .survived, duration: 1)
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
