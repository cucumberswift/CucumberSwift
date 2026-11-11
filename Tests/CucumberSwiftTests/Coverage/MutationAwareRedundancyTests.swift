//
//  MutationAwareRedundancyTests.swift
//  CucumberSwiftTests
//
//  The redundancy has two modes (#518). Without mutation testing it judges the scenarios by the code they run,
//  and of two that run the same code, the one that runs more wins. With mutation testing it judges them by the
//  mutants they detect too: the weaker scenario is redundant, and two scenarios that each check something the
//  other doesn't are both reported, so that one takes the best of both.
//

import Foundation
import XCTest
@testable import CucumberSwift

final class MutationAwareRedundancyTests: XCTestCase {
    /// One function, `total`, with regions 0 to 3.
    private let code = MeasuredCode(functions: [
        MeasuredCode.Function(name: "Basket.total", file: "/tmp/Sources/Shop/Basket.swift", line: 10, regions: 0..<4)
    ])
    private let boundary = ">= at Basket.swift:21 is changed to >"

    private func scenario(_ line: Int, _ regions: Set<Int>, group: String? = nil) -> CoverageScores.Scenario {
        CoverageScores.Scenario(name: "Scenario \(line)", line: line, tags: [], duration: 1, regions: regions, group: group)
    }

    private func detections(_ kills: [Int: Set<String>]) -> CoverageScores.Detections {
        CoverageScores.Detections(kills: kills, changes: ["m1": boundary, "m2": "+ at Basket.swift:22 is changed to -"])
    }

    private func redundant(_ scores: CoverageScores) -> [Int] {
        scores.scenarios.filter(\.addsNothing).map(\.line)
    }

    // MARK: Simple mode

    func testWithoutMutationTestingTheScenarioThatRunsMoreCodeWinsWhereverItIs() {
        // The first runs regions 0 and 1, which the second runs too, with region 2; the third runs region 2.
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1, 2]), scenario(14, [2])],
                                    code: code,
                                    isRedundancy: true)
        XCTAssertEqual(redundant(scores), [4, 14])
        XCTAssertFalse(scores.isMutationAware)
    }

    func testWithoutMutationTestingWhatAScenarioDetectsIsIgnored() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [0, 1])], code: code, isRedundancy: true)
        XCTAssertEqual(redundant(scores), [9])
        XCTAssertNil(scores.scenarios[1].overlap)
    }

    // MARK: Mutation-aware mode

    func testOfTwoScenariosThatRunTheSameCodeTheOneThatDetectsLessIsRedundant() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([9: ["m1"]]))
        XCTAssertEqual(redundant(scores), [4])
        XCTAssertEqual(scores.scenarios.compactMap(\.overlap), [])
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 50)
        XCTAssertTrue(scores.isMutationAware)
    }

    func testOfTwoScenariosThatRunTheSameCodeAndDetectTheSameMutantsTheLaterIsRedundant() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([4: ["m1"], 9: ["m1"]]))
        XCTAssertEqual(redundant(scores), [9])
    }

    func testAScenarioThatRunsLessCodeAndDetectsNothingMoreIsRedundant() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([4: ["m1", "m2"], 9: ["m1"]]))
        XCTAssertEqual(redundant(scores), [9])
        XCTAssertEqual(scores.scenarios.compactMap(\.overlap), [])
    }

    func testAScenarioWithMoreCodeAndOneThatDetectsAMutantItMissesBothOverlap() throws {
        // The first runs 3 of the 4 regions; the second runs 2 of them, but alone fails when `>=` becomes `>`.
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([9: ["m1"]]))
        XCTAssertEqual(redundant(scores), [])
        XCTAssertEqual(scores.scenarios[0].overlap,
                       CoverageScores.Overlap(line: 9, regionsHere: 1, regionsThere: 0, detectsHere: [], detectsThere: [boundary]))
        XCTAssertEqual(scores.scenarios[1].overlap,
                       CoverageScores.Overlap(line: 4, regionsHere: 0, regionsThere: 1, detectsHere: [boundary], detectsThere: []))
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 100, "Both scenarios need work")
        XCTAssertEqual(scores.wastedTime, 0, "Removing either would lose something")
    }

    func testAScenarioThatRunsCodeOfItsOwnAndDetectsNothingNewOverlapsNothing() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [2, 3])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([4: ["m1"]]))
        XCTAssertEqual(redundant(scores), [])
        XCTAssertEqual(scores.scenarios.compactMap(\.overlap), [])
        XCTAssertEqual(scores.redundancy, 0)
    }

    func testAnOutlinesExamplesDetectWhatAnyOfThemDetects() {
        // The examples at lines 12 and 13 are one Scenario Outline; the one at line 13 fails on the mutant.
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(12, [0, 1], group: "outline"), scenario(13, [0, 1], group: "outline")],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([13: ["m1"]]))
        XCTAssertEqual(redundant(scores), [4])
    }

    func testWithMutationTestingButNoMutantDetectedTheRedundancyIsByCode() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([:]))
        XCTAssertEqual(redundant(scores), [9])
        XCTAssertTrue(scores.isMutationAware)
    }

    // MARK: Messages

    func testTheOverlappingScenariosEachGetAWarningThatSaysWhatTheOtherAdds() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([9: ["m1"]]))
        let issues = CoverageReport(scores: scores, settings: CoverageSettings()).issues(file: nil, line: 1, subject: "Feature")
        let overlaps = issues.filter { $0.message.hasPrefix("Scenario overlaps") }
        XCTAssertEqual(overlaps.map(\.line), [4, 9])
        XCTAssertTrue(overlaps.allSatisfy { $0.severity == .warning && $0.kind == .redundancy })
        XCTAssertEqual(overlaps[0].message, "Scenario overlaps the scenario at line 9. This scenario runs 1 region that one doesn't. "
            + "Only that one fails when >= at Basket.swift:21 is changed to >. "
            + "Combine the best of both into one scenario, or into a Scenario Outline for different values.")
        XCTAssertEqual(overlaps[1].message, "Scenario overlaps the scenario at line 4. That scenario runs 1 region this one doesn't. "
            + "Only this one fails when >= at Basket.swift:21 is changed to >. "
            + "Combine the best of both into one scenario, or into a Scenario Outline for different values.")
        XCTAssertTrue(issues.contains { $0.message.contains("are redundant or overlap another, by the code they run after the Background and the mutants they detect") })
    }

    func testAMutationAwareRedundantScenarioSaysItDetectsNothingNew() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([9: ["m1"]]))
        let report = CoverageReport(scores: scores, settings: CoverageSettings())
        let warning = report.issues(file: nil, line: 1, subject: "Feature").first { $0.line == 4 }
        XCTAssertEqual(warning?.message, "Scenario adds nothing of its own: other scenarios run all the code it runs after the Background, "
            + "and fail on every mutant it fails on. It took 1.0 s. Consider a Scenario Outline for other values, or remove it.")
        XCTAssertTrue(report.summary(name: "Basket").contains("Scenario 4 (line 4, adds nothing of its own)"))
    }

    func testAMessageListsThreeChangesAndCountsTheRest() {
        let overlap = CoverageScores.Overlap(line: 4, regionsHere: 0, regionsThere: 0, detectsHere: ["a", "b", "c", "d", "e"], detectsThere: [])
        XCTAssertTrue(CoverageReport.message(for: overlap).contains("Only this one fails when a, b, c or 2 other changes."))
        let two = CoverageScores.Overlap(line: 4, regionsHere: 0, regionsThere: 0, detectsHere: ["a", "b"], detectsThere: [])
        XCTAssertTrue(CoverageReport.message(for: two).contains("Only this one fails when a or b."))
    }

    // MARK: Manifests

    func testAManifestFromBeforeMutationTestingReadsAsNotMutationAware() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])],
                                    code: code,
                                    isRedundancy: true,
                                    detections: detections([9: ["m1"]]))
        let data = try JSONEncoder().encode(scores)
        XCTAssertEqual(try JSONDecoder().decode(CoverageScores.self, from: data), scores, "The field is written and read back")
        // CucumberSwift 6.8 wrote the scores without the field.
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["isMutationAware"] = nil
        let older = try JSONDecoder().decode(CoverageScores.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(older.isMutationAware)
        XCTAssertEqual(older.scenarios, scores.scenarios)
    }
}
