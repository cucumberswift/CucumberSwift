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
    /// A feature file's URI, as the runners give it.
    private let featureURI = FileManager.default.temporaryDirectory.appendingPathComponent("a.feature").absoluteString

    /// A function with two branches, for a scenario to run one of.
    private static func coveredHalf(of value: Int) -> Int {
        if value < 10 {
            return 1
        }
        return 2
    }

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

    func testWithScoresOffTheRecorderMeasuresNoCodeAndSaysWhy() {
        var settings = CoverageSettings()
        settings.scoresOffReason = "parallel testing"
        let recorder = CoverageRecorder(coverageFolder: folder, counters: ProfileCounters(binaries: []), settings: settings, runID: "run")
        XCTAssertNil(recorder.code)
        XCTAssertEqual(recorder.scoresProblem, "parallel testing")
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
        recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: 1, name: "S", tags: []))
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
        recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: 3, name: "S", tags: []))
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
        XCTAssertEqual(CoverageRecorder.coverageFolder(path: folder.path)?.path, folder.path)
    }

    func testAScenarioWritesAProfileForEachBinaryBuiltWithCoverage() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, runID: "run")
        recorder.scenarioStarted()
        _ = ["b", "a"].sorted()
        recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: 12, name: "Sorting", tags: ["@fast"]))
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

    func testTheCoverageMapFindsTheCodeAScenarioRanAndScoresItsFeature() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        XCTAssertEqual(counters.binaries.compactMap(\.mapProblem), [])
        // Only this file's code counts, so that the scores don't depend on the rest of the bundle.
        var settings = CoverageSettings()
        settings.sources = ["CoverageRecorderTests.swift"]
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, settings: settings, runID: "run")
        let code = try XCTUnwrap(recorder.code)
        let measured = code.functions.first { $0.name.contains("coveredHalf") }
        XCTAssertNotNil(measured, "\(code.functions.map(\.name))")

        recorder.scenarioStarted()
        let result = Self.coveredHalf(of: 3)
        recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: 4, name: "Small", tags: [], duration: 0.5))
        let scores = try XCTUnwrap(recorder.featureFinished(feature: featureURI, featureName: "A", line: 1).first?.scores)
        XCTAssertEqual(result, 1)

        // The scenario entered only `coveredHalf(of:)`: this test was running before it started. It took
        // one of the function's two branches, and the other is the function's only region that didn't run.
        let gap = try XCTUnwrap(scores.gaps.first { $0.function == measured?.name }, "\(scores.gaps)")
        XCTAssertEqual(gap.regionsNotRun, 1)
        XCTAssertEqual(gap.enteredBy, [4])
        XCTAssertEqual(scores.functionsRun, 1)
        XCTAssertEqual(scores.coveredRegions, scores.regionsInFunctionsRun - 1)
        XCTAssertEqual(recorder.manifest.features.map(\.scores), [scores])
        XCTAssertEqual(recorder.manifest.scenarios.first?.duration, 0.5)
    }

    func testEachRuleIsScoredOnItsOwnAfterTheScenariosOutsideARule() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        var settings = CoverageSettings()
        settings.sources = ["CoverageRecorderTests.swift"]
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, settings: settings, runID: "run")
        let classifying = ScenarioRule(title: "Classifying", line: 10)
        for (line, rule) in [(20, Optional(classifying)), (4, nil), (30, ScenarioRule(title: "Adding", line: 8))] {
            recorder.scenarioStarted()
            _ = Self.coveredHalf(of: line)
            recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: line, name: "S\(line)", tags: [], rule: rule))
        }
        let parts = recorder.featureFinished(feature: featureURI, featureName: "A", line: 1)
        XCTAssertEqual(parts.map(\.rule?.title), [nil, "Adding", "Classifying"])
        XCTAssertEqual(parts.map { $0.scores.scenarios.map(\.line) }, [[4], [30], [20]])
        XCTAssertEqual(recorder.manifest.features.map(\.ruleLine), [nil, 8, 10])
    }

    func testTheCodeRunBeforeTheBackgroundFinishedIsLeftOutOfTheRedundancy() throws {
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        var settings = CoverageSettings()
        settings.sources = ["CoverageRecorderTests.swift"]
        let recorder = CoverageRecorder(coverageFolder: folder, counters: counters, settings: settings, runID: "run")
        // Two scenarios that run the same branch, the first in its Background and the second in its own step.
        for (line, inBackground) in [(4, true), (9, false)] {
            recorder.scenarioStarted()
            if inBackground {
                _ = Self.coveredHalf(of: 1)
                recorder.backgroundFinished()
            } else {
                recorder.backgroundFinished()
                _ = Self.coveredHalf(of: 1)
            }
            recorder.scenarioFinished(.init(feature: featureURI, featureName: "A", line: line, name: "S\(line)", tags: []))
        }
        let scores = try XCTUnwrap(recorder.featureFinished(feature: featureURI, featureName: "A", line: 1).first?.scores)
        // The first scenario's run of the branch was setup, so the second's isn't redundant.
        XCTAssertEqual(scores.redundancy, 0)
        XCTAssertGreaterThan(scores.coveredRegions, 0)
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
