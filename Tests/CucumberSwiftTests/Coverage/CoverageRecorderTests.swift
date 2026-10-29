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
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CoverageRecorderTests-\(UUID().uuidString)")
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    private func counts(_ values: [UInt64]) -> [UInt8] {
        values.withUnsafeBytes { Array($0) }
    }

    func testTheDifferenceIsTheCountsThatGrew() {
        XCTAssertEqual(ProfileCounters.difference(counts([5, 7, 2]), minus: counts([3, 7, 0])), counts([2, 0, 2]))
    }

    func testACounterBelowItsSnapshotCountsAsZero() {
        XCTAssertEqual(ProfileCounters.difference(counts([1]), minus: counts([4])), counts([0]))
    }

    func testAVersionIsWrittenOnlyWhenItIsTheSupportedOneWhateverItsFlags() {
        var counters = ProfileCounters(binaries: [])
        XCTAssertTrue(counters.accept(version: ProfileCounters.supportedVersion))
        XCTAssertTrue(counters.accept(version: ProfileCounters.supportedVersion | (1 << 56)))
        XCTAssertFalse(counters.accept(version: 11 | (1 << 56)))
        XCTAssertEqual(counters.unsupportedVersions, [11])
    }

    func testAnUnsupportedVersionIsTheManifestsProblem() {
        let recorder = CoverageRecorder(
            coverageFolder: folder,
            counters: ProfileCounters(binaries: [], unsupportedVersions: [11]),
            runID: "run"
        )
        XCTAssertEqual(recorder.manifest.problem, "The profile format of this test process is version 11, and CucumberSwift writes version 10, the one of Xcode 26.")
    }

    func testAFolderThatCantBeMadeIsTheManifestsProblem() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("file")
        try Data().write(to: file)
        let recorder = CoverageRecorder(coverageFolder: file, counters: ProfileCounters(binaries: []), runID: "run")
        XCTAssertEqual(recorder.manifest.problem?.hasPrefix("Couldn't create"), true)
    }

    func testAProfileThatCantBeWrittenIsTheManifestsProblem() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, runID: "run")
        recorder.scenarioStarted()
        try FileManager.default.removeItem(at: recorder.folder)
        recorder.scenarioFinished(feature: "file:///a.feature", featureName: "A", line: 1, name: "S", tags: [])
        XCTAssertEqual(recorder.manifest.problem?.hasPrefix("Couldn't write the scenario's coverage"), true)
        XCTAssertEqual(recorder.manifest.scenarios, [])
    }

    func testWritingToAFolderThatDoesNotExistThrows() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        XCTAssertThrowsError(try counters.writeProfiles(named: "x", in: folder.appendingPathComponent("missing"), since: counters.snapshot())) {
            guard case .writeFailed = $0 as? ProfileCounters.WriteError else { return XCTFail("\($0)") }
        }
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

    // Xcode runs tests with the profile runtime's continuous mode, `%c` in LLVM_PROFILE_FILE, and
    // `swift test` without it. The profile is written to memory in both, then to the scenario's file.
    func testAProfileIsARawProfileWhateverTheRunsProfileFile() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let files = try counters.writeProfiles(named: "raw", in: folder, since: counters.snapshot())
        let file = try XCTUnwrap(files.first)
        let data = try Data(contentsOf: folder.appendingPathComponent(file))
        // The raw profile's header starts with its magic number, `\xFFlprofr\x81`, and its version.
        let words = data.prefix(16).withUnsafeBytes { Array($0.bindMemory(to: UInt64.self)).map { UInt64(littleEndian: $0) } }
        XCTAssertEqual(words[0], 0xFF6C_7072_6F66_7281)
        XCTAssertEqual(words[1] & 0xFFFF_FFFF, ProfileCounters.supportedVersion)
    }
}
