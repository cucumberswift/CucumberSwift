//
//  ScenarioCoverageMergeTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class ScenarioCoverageMergeTests: TemporaryFolderTestCase {
    private func writeRun(_ name: String, regions: String, scenarios: String) throws {
        let run = folder.appendingPathComponent("run-\(name)")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        try #"{"version": 1, "regions": [\#(regions)], "scenarios": [\#(scenarios)]}"#.write(to: run.appendingPathComponent("regions.json"), atomically: true, encoding: .utf8)
    }

    private func region(_ line: Int) -> String {
        #"{"file": "/x/Voting.swift", "lineStart": \#(line), "columnStart": 1, "lineEnd": \#(line), "columnEnd": 9}"#
    }

    func testMergesTheRunsOfSeveralTestBundles() throws {
        // The first bundle's process numbered the regions of lines 10 and 14. The second's numbered 14 and 18.
        let first = #"{"feature": "A.feature", "line": 3, "name": "a", "ran": [0]}"#
        let second = #"{"feature": "B.feature", "line": 3, "name": "b", "ran": [1]}"#
        try writeRun("A", regions: "\(region(10)), \(region(14))", scenarios: first)
        try writeRun("B", regions: "\(region(14)), \(region(18))", scenarios: second)
        let coverage = try XCTUnwrap(ScenarioCoverage.read(inRunsUnder: folder))
        XCTAssertEqual(coverage.regions.map(\.lineStart), [10, 14, 18], "The region of line 14 is kept once")
        XCTAssertEqual(coverage.scenarios.map(\.name), ["a", "b"])
        XCTAssertEqual(coverage.scenarios.map(\.ran), [[0], [2]], "The second run's region 1 is the merged region 2, line 18")
    }

    func testIgnoresAFolderWithoutRegionsAndReturnsNilWhenNoRunHasAny() throws {
        XCTAssertNil(ScenarioCoverage.read(inRunsUnder: folder))
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("run-empty"), withIntermediateDirectories: true)
        XCTAssertNil(ScenarioCoverage.read(inRunsUnder: folder))
        try writeRun("A", regions: region(10), scenarios: #"{"feature": "A.feature", "line": 3, "name": "a", "ran": [0]}"#)
        XCTAssertEqual(ScenarioCoverage.read(inRunsUnder: folder)?.scenarios.count, 1)
    }
}
#endif
