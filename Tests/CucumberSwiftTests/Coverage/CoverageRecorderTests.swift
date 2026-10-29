//
//  CoverageRecorderTests.swift
//  CucumberSwiftTests
//
//  Each scenario's coverage is what the counters gained while it ran, written without changing the counters'
//  totals (#502). The tests that write profiles need this bundle built with code coverage, as our CI's iOS
//  job builds it, and are skipped otherwise.
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageRecorderTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("CoverageRecorderTests-\(UUID().uuidString)")
        addTeardownBlock { [folder] in try? FileManager.default.removeItem(at: folder!) }
    }

    private func counts(_ values: [UInt64]) -> [UInt8] {
        values.withUnsafeBytes { Array($0) }
    }

    func testTheDifferenceIsWrittenAndTheTotalsComeBack() {
        var live: [UInt64] = [5, 7, 2]
        let before = counts([3, 7, 0])
        live.withUnsafeMutableBytes { ProfileCounters.subtract(before, from: $0) }
        XCTAssertEqual(live, [2, 0, 2])
        live.withUnsafeMutableBytes { ProfileCounters.add(before, to: $0) }
        XCTAssertEqual(live, [5, 7, 2])
    }

    func testACounterBelowItsSnapshotCountsAsZero() {
        var live: [UInt64] = [1]
        live.withUnsafeMutableBytes { ProfileCounters.subtract(counts([4]), from: $0) }
        XCTAssertEqual(live, [0])
    }

    func testWithoutCoverageTheManifestSaysWhyAndListsNoScenarios() throws {
        let recorder = CoverageRecorder(coverageFolder: folder, counters: ProfileCounters(binaries: []), runID: "run")
        recorder.scenarioStarted()
        recorder.scenarioFinished(feature: "file:///Features/a.feature", featureName: "A", line: 3, name: "S", tags: [])
        let url = try XCTUnwrap(recorder.writeManifest())
        XCTAssertEqual(url.path, folder.appendingPathComponent("run-run/manifest.json").path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(CoverageRecorder.Manifest.self, from: Data(contentsOf: url))
        XCTAssertEqual(manifest.version, 1)
        XCTAssertEqual(manifest.scenarios, [])
        XCTAssertEqual(manifest.problem, "No binary in the test process was built with code coverage. Turn on code coverage for the test target.")
    }

    func testTheDefaultFolderIsInTheDocumentsFolder() throws {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        XCTAssertEqual(CoverageRecorder.coverageFolder(path: nil), documents.appendingPathComponent("_cucumberCoverage", isDirectory: true))
        XCTAssertEqual(CoverageRecorder.coverageFolder(path: "/tmp/coverage")?.path, "/tmp/coverage")
    }

    func testAScenarioWritesAProfileForEachBinaryBuiltWithCoverage() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, runID: "run")
        recorder.scenarioStarted()
        _ = ["b", "a"].sorted()
        recorder.scenarioFinished(feature: "file:///Features/a.feature", featureName: "A", line: 12, name: "Sorting", tags: ["@fast"])
        recorder.writeManifest()

        let manifest = recorder.manifest
        XCTAssertNil(manifest.problem)
        XCTAssertEqual(manifest.scenarios.count, 1)
        let scenario = try XCTUnwrap(manifest.scenarios.first)
        XCTAssertEqual(scenario.line, 12)
        XCTAssertEqual(scenario.tags, ["@fast"])
        XCTAssertEqual(scenario.profiles.count, counters.binaries.count)
        for profile in scenario.profiles {
            XCTAssertTrue(profile.hasPrefix("S0001-L12-"), profile)
            let size = try FileManager.default.attributesOfItem(atPath: recorder.folder.appendingPathComponent(profile).path)[.size] as? Int
            XCTAssertGreaterThan(size ?? 0, 0, profile)
        }
        XCTAssertEqual(manifest.binaries.map(\.path), counters.binaries.map(\.path))
    }

    func testWritingAProfileKeepsTheCountersTotals() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let before = counters.snapshot()
        _ = try counters.writeProfiles(named: "totals", in: folder, since: before)
        let after = counters.snapshot()
        // Counters only grow while the test runs, so none may be smaller than before the write.
        for (old, new) in zip(before.countsForTesting, after.countsForTesting) {
            let oldValues = old.withUnsafeBytes { Array($0.bindMemory(to: UInt64.self)) }
            let newValues = new.withUnsafeBytes { Array($0.bindMemory(to: UInt64.self)) }
            XCTAssertFalse(zip(oldValues, newValues).contains { $1 < $0 })
        }
    }

    func testContinuousModeIsRefusedRatherThanWrittenToTheWrongFile() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        XCTAssertThrowsError(try counters.writeProfiles(named: "c", in: folder, since: counters.snapshot(),
                                                        environment: ["LLVM_PROFILE_FILE": "%c%p.profraw"])) {
            XCTAssertEqual($0 as? ProfileCounters.WriteError, .continuousMode)
        }
    }
}
