//
//  MutationReporterTests.swift
//  CucumberSwiftTests
//
//  With mutation testing on, the coverage reporter matches each mutant of the report to the scenarios that ran
//  its code, and records an error for each one that survived (#518). The tests that match code need this bundle
//  built with code coverage, as our CI's iOS job builds it, and are skipped otherwise.
//

import Foundation
import XCTest
@testable import CucumberSwift

@MainActor
final class MutationReporterTests: XCTestCase {
    /// What a run recorded and printed, and the line of its scenario.
    private struct Run {
        let issues: [CoverageIssue]
        let output: [String]
        let scenarioLine: Int
    }

    private var folder = FileManager.default.temporaryDirectory
    /// The code a mutant changes: the `>=` on the line after `adultLine`.
    private let adultLine = #line
    private func isAdult(_ age: Int) -> Bool { age >= 18 }

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MutationReporterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    private func settings(report: String?) -> CoverageSettings {
        var settings = CoverageSettings()
        settings.sources = ["MutationReporterTests.swift"]
        settings.isMutationTesting = true
        settings.mutationReport = report
        return settings
    }

    /// A report with one mutant at the `>=` of `isAdult(_:)`, with `status`.
    private func writeReport(status: String) throws -> String {
        let line = adultLine + 1
        let text = "    private func isAdult(_ age: Int) -> Bool { age >= 18 }"
        let source = String(repeating: "\n", count: line - 1) + text + "\n"
        // The `>=`, not the `>` of the `->` before it.
        let column = text.range(of: ">=").map { text.utf8.distance(from: text.startIndex, to: $0.lowerBound) + 1 } ?? 0
        let json = """
        {"schemaVersion": "2", "files": {"Tests/CucumberSwiftTests/Coverage/MutationReporterTests.swift": {"language": "swift",
         "source": \(String(reflecting: source)), "mutants": [{"id": "1", "mutatorName": "RelationalOperator", "replacement": ">",
         "status": "\(status)", "location": {"start": {"line": \(line), "column": \(column)}, "end": {"line": \(line), "column": \(column + 2)}}}]}}}
        """
        let path = folder.appendingPathComponent("mutation-report.json").path
        try json.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    /// Runs one scenario that calls `isAdult(_:)` through a reporter, and returns what it recorded and printed.
    private func run(settings: CoverageSettings) throws -> Run {
        var issues = [CoverageIssue]()
        var output = [String]()
        let path = folder.appendingPathComponent("coverage").path
        let reporter = CoverageReporter(isEnabled: { true },
                                        coveragePath: { path },
                                        settings: { settings },
                                        record: { issues.append($0) },
                                        output: { output.append($0) })
        let cucumber = Cucumber(withString: """
        Feature: Voting
            Scenario: An adult can vote
                Given a person aged 30
        """)
        let feature = try XCTUnwrap(cucumber.features.first)
        let scenario = try XCTUnwrap(feature.scenarios.first)
        let duration = Measurement(value: 1, unit: UnitDuration.seconds)
        reporter.didStart(scenario: scenario, at: Date())
        XCTAssertTrue(isAdult(30))
        reporter.didFinish(scenario: scenario, result: .passed, duration: duration)
        reporter.didFinish(feature: feature, result: .passed, duration: duration)
        return Run(issues: issues, output: output, scenarioLine: Int(scenario.location.line))
    }

    private func skipWithoutCoverage() throws {
        let probe = CoverageRecorder(coverageFolder: folder, settings: settings(report: nil))
        try XCTSkipIf(probe.code?.functions.isEmpty ?? true, "This test file wasn't built with code coverage.")
    }

    func testASurvivingMutantInTheCodeAScenarioRanFailsTheMutationTest() throws {
        try skipWithoutCoverage()
        let run = try run(settings: settings(report: try writeReport(status: "Survived")))
        XCTAssertEqual(run.issues.map(\.line), [1, run.scenarioLine])
        XCTAssertTrue(run.issues.allSatisfy { $0.kind == .mutation && $0.severity == .error })
        XCTAssertTrue(run.issues[1].message.hasPrefix("This scenario still passes when >= at MutationReporterTests.swift:"), run.issues[1].message)
        XCTAssertTrue(run.output.contains("CucumberSwift mutation: Voting: its scenarios missed 1 of 1 mutants in the code they run"), "\(run.output)")
    }

    func testADetectedMutantRecordsNothing() throws {
        try skipWithoutCoverage()
        let run = try run(settings: settings(report: try writeReport(status: "Killed")))
        XCTAssertEqual(run.issues, [])
        XCTAssertTrue(run.output.contains("CucumberSwift mutation: Voting: its scenarios detected all 1 mutants in the code they run"), "\(run.output)")
    }

    func testWithoutAReportTheMutationTestFails() throws {
        try skipWithoutCoverage()
        let run = try run(settings: settings(report: nil))
        XCTAssertEqual(run.issues.map(\.severity), [.error])
        XCTAssertTrue(run.issues.first?.message.contains("no mutation report is set") ?? false, "\(run.issues)")
    }

    func testAReportThatCantBeReadFailsTheMutationTest() throws {
        try skipWithoutCoverage()
        let run = try run(settings: settings(report: folder.appendingPathComponent("missing.json").path))
        XCTAssertEqual(run.issues.map(\.severity), [.error])
        XCTAssertTrue(run.issues.first?.message.contains("no mutation report at") ?? false, "\(run.issues)")
    }

    func testWithMutationTestingOffNothingIsRecorded() throws {
        try skipWithoutCoverage()
        var settings = settings(report: try writeReport(status: "Survived"))
        settings.isMutationTesting = false
        let run = try run(settings: settings)
        XCTAssertFalse(run.issues.contains { $0.kind == .mutation })
        XCTAssertFalse(run.output.contains { $0.hasPrefix("CucumberSwift mutation") })
    }

    func testARegionHoldsAPositionByLineAndColumn() {
        let region = CoverageMap.Region(counter: .zero, lineStart: 3, lineEnd: 5, columnStart: 10, columnEnd: 4)
        XCTAssertTrue(region.contains(line: 4, column: 1))
        XCTAssertTrue(region.contains(line: 3, column: 10))
        XCTAssertFalse(region.contains(line: 3, column: 9))
        XCTAssertFalse(region.contains(line: 5, column: 5))
        XCTAssertFalse(region.contains(line: 6, column: nil))
        XCTAssertTrue(region.contains(line: 3, column: nil))
        let unknownColumns = CoverageMap.Region(counter: .zero, lineStart: 3, lineEnd: 3)
        XCTAssertTrue(unknownColumns.contains(line: 3, column: 1))
    }
}
