//
//  MergedCoverageTests.swift
//  CucumberSwiftCoverageMergeTests
//
//  What mutation testing and cucumberswift coverage merge read through MergedCoverage (#515).
//

import Foundation
import XCTest
@testable import CucumberSwiftCoverageMerge

final class MergedCoverageTests: XCTestCase {
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MergedCoverageTests-\(UUID().uuidString)")
        self.folder = folder
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    /// The functions of one test binary: `add`, which scenarios run, and `unused`, which none enters.
    private func measured(spans: Bool) -> [CoverageManifest.MeasuredFunction] {
        [("add", 2), ("unused", 3)].enumerated().map { index, function in
            let first = 10 * (index + 1)
            return CoverageManifest.MeasuredFunction(binary: "MyTests",
                                                     name: "$s\(function.0)",
                                                     readableName: "Calc.\(function.0)()",
                                                     file: "/src/Calc.swift",
                                                     line: first,
                                                     regions: function.1,
                                                     spans: spans ? (0..<function.1).map { [first + $0, 5, first + $0, 20] } : nil)
        }
    }

    /// Writes a run's folder, `run-<name>`, with one scenario that ran the first region of `add`.
    private func writeRun(_ name: String, scenario: String, spans: Bool = true) throws {
        let record = CoverageManifest.ScenarioRecord(feature: "file:///b.xctest/Features/A.feature",
                                                     featureName: "A",
                                                     line: scenario == "one" ? 3 : 7,
                                                     name: scenario,
                                                     tags: [],
                                                     profiles: [],
                                                     duration: 0.1,
                                                     featureLine: 1,
                                                     issueFile: nil,
                                                     coverage: .init(regions: [0],
                                                                     backgroundRegions: [],
                                                                     steps: [],
                                                                     group: "line",
                                                                     rule: nil,
                                                                     ruleLine: nil))
        let manifest = CoverageManifest(run: name,
                                        startDate: Date(),
                                        binaries: [],
                                        scenarios: [record],
                                        measured: measured(spans: spans),
                                        settings: .init(CoverageSettings()))
        let run = folder.appendingPathComponent("run-\(name)")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: run.appendingPathComponent("manifest.json"))
    }

    func testEveryMeasuredFunctionIsListedIncludingThoseNoScenarioEntered() throws {
        try writeRun("a", scenario: "one")
        let merged = try MergedCoverage(folders: [folder])
        XCTAssertEqual(merged.functions.map(\.name), ["Calc.add()", "Calc.unused()"])
        XCTAssertEqual(merged.functions.map(\.regionCount), [2, 3])
        XCTAssertEqual(merged.functions.map(\.firstRegion), [0, 2])
        XCTAssertEqual(merged.scenarios.map(\.ran), [[MergedCoverage.Region(function: 0, index: 0)]])
    }

    func testOneCoverageFolderHoldingTheXCTestAndTheSwiftTestingRunOfOneBinaryMerges() throws {
        // `swift test` runs both runners from one test binary, and each writes a run folder in the same place.
        try writeRun("xctest", scenario: "one")
        try writeRun("swift-testing", scenario: "two")
        let merged = try MergedCoverage(folders: [folder])
        XCTAssertEqual(merged.scenarios.map(\.name).sorted(), ["one", "two"])
        XCTAssertEqual(merged.functions.count, 2)
        XCTAssertEqual(try MergedCoverage.renumbering(ofRunsIn: [folder]).runFolders.count, 2)
    }

    func testSpansAreOnePerRegionAsTheCoverageMapGivesThem() throws {
        try writeRun("a", scenario: "one")
        let functions = try MergedCoverage(folders: [folder]).functions
        XCTAssertEqual(functions.map(\.spans.count), functions.map(\.regionCount))
        XCTAssertEqual(functions[1].spans.first, MergedCoverage.Span(lineStart: 20, columnStart: 5, lineEnd: 20, columnEnd: 20))
    }

    func testAManifestWithoutSpansGivesNoSpansRatherThanMadeUpOnes() throws {
        try writeRun("a", scenario: "one", spans: false)
        XCTAssertEqual(try MergedCoverage(folders: [folder]).functions.map(\.spans), [[], []])
    }

    func testTheCoverageCommandExitsWithItsStatus() throws {
        XCTAssertEqual(CoverageCommand.run(arguments: []), 2)
        XCTAssertEqual(CoverageCommand.run(arguments: ["unknown"]), 2)
        XCTAssertEqual(CoverageCommand.run(arguments: ["merge"]), 2)
        XCTAssertEqual(CoverageCommand.run(arguments: ["--help"]), 0)
        XCTAssertEqual(CoverageCommand.run(arguments: ["merge", folder.appendingPathComponent("none").path]), 2)
        try writeRun("a", scenario: "one")
        XCTAssertEqual(CoverageCommand.run(arguments: ["merge", folder.path]), 0)
    }
}
