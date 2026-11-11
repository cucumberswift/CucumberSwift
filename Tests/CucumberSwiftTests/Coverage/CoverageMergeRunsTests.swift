//
//  CoverageMergeRunsTests.swift
//  CucumberSwiftTests
//
//  How cucumberswift coverage merge finds and reads the runs, and numbers their regions again (#515).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageMergeRunsTests: CoverageMergeTestCase {
    private func write(_ manifest: CoverageManifest, in name: String) throws {
        let run = folder.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: run.appendingPathComponent("manifest.json"))
    }

    func testTheRunsAreReadFromTheirFoldersOrTheFolderThatHoldsThem() throws {
        try write(manifest(Array(scenarios[..<3]), order: functions), in: "run-a")
        try write(manifest(Array(scenarios[3...]), order: functions), in: "run-b")
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("run-empty"), withIntermediateDirectories: true)

        XCTAssertEqual(CoverageMerge.runFolders(in: [folder]).map(\.lastPathComponent), ["run-a", "run-b"])
        XCTAssertEqual(CoverageMerge.runFolders(in: [folder.appendingPathComponent("run-b")]).map(\.lastPathComponent), ["run-b"])
        let merged = try CoverageMerge(runs: CoverageMerge.read([folder]))
        XCTAssertEqual(merged.features.map(\.part), serialParts(scenarios))

        let empty = folder.appendingPathComponent("run-empty")
        XCTAssertThrowsError(try CoverageMerge.read([empty])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .noRuns([empty.path]))
        }
    }

    func testARunThatStoppedBeforeItsManifestIsReportedNotLeftOut() throws {
        try write(manifest(scenarios, order: functions), in: "run-a")
        let stopped = folder.appendingPathComponent("run-b")
        try FileManager.default.createDirectory(at: stopped, withIntermediateDirectories: true)
        try Data("profile".utf8).write(to: stopped.appendingPathComponent("scenario.profraw"))
        let found = try XCTUnwrap(CoverageMerge.incompleteRunFolders(in: [folder]).first)
        XCTAssertEqual(found.lastPathComponent, "run-b")
        XCTAssertThrowsError(try CoverageMerge.read([folder])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .incomplete(found.path))
        }
    }

    func testARunFolderSuppliedDirectlyThatStoppedBeforeItsManifestIsReported() throws {
        let stopped = folder.appendingPathComponent("run-c")
        try FileManager.default.createDirectory(at: stopped, withIntermediateDirectories: true)
        try Data("profile".utf8).write(to: stopped.appendingPathComponent("scenario.profraw"))
        XCTAssertThrowsError(try CoverageMerge.read([stopped])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .incomplete(stopped.path))
        }
        // Beside a run that finished, it still isn't left out.
        try write(manifest(scenarios, order: functions), in: "run-a")
        let finished = folder.appendingPathComponent("run-a")
        XCTAssertThrowsError(try CoverageMerge.read([finished, stopped])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .incomplete(stopped.path))
        }
    }

    func testAManifestOfAnotherVersionIsRefused() throws {
        var newer = manifest(scenarios, order: functions)
        newer.version = 2
        try write(newer, in: "run-a")
        let found = try XCTUnwrap(CoverageMerge.runFolders(in: [folder]).first)
        XCTAssertThrowsError(try CoverageMerge.read([folder])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .unreadable(found.path, "its version is 2, and this reads version 1"))
        }
    }

    func testRenumberingGivesEachFunctionOnePlaceWhateverOrderARunListsItsFunctionsIn() throws {
        let renumbering = try CoverageMerge.renumber([measured(functions), measured(functions.reversed()), []])
        XCTAssertEqual(renumbering.functions.map(\.name), ["Calc.add()", "Calc.classify()", "Calc.unused()"])
        XCTAssertEqual(renumbering.functions.map(\.regions), [0..<2, 2..<6, 6..<9])
        XCTAssertEqual(renumbering.maps, [Array(0..<9), [6, 7, 8, 2, 3, 4, 5, 0, 1], []])
        XCTAssertEqual(renumbering.spans.first??.first, [10, 1, 10, 9])
        let changed = measured([Function(name: "add", regions: 3)])
        XCTAssertThrowsError(try CoverageMerge.renumber([measured(functions), changed])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentBuilds("Calc.add()"))
        }
    }

    func testAManifestFromBeforeTheSpansWereRecordedStillDecodes() throws {
        let json = #"{"binary":"B","name":"n","readableName":"r","file":"/f.swift","line":1,"regions":2}"#
        let function = try JSONDecoder().decode(CoverageManifest.MeasuredFunction.self, from: Data(json.utf8))
        XCTAssertNil(function.spans)
        XCTAssertEqual(function.regions, 2)
    }

    func testTheLevelsRoundTripThroughTheManifest() {
        var settings = CoverageSettings()
        settings.warningLevel = .off
        settings.errorLevel = 60
        settings.isRedundancy = false
        settings.redundancyErrorLevel = 1
        settings.redundantStepWarningLevel = .off
        let back = CoverageManifest.Settings(settings).coverageSettings
        XCTAssertEqual(back.warningLevel, .off)
        XCTAssertEqual(back.errorLevel, 60)
        XCTAssertFalse(back.isRedundancy)
        XCTAssertEqual(back.redundancyWarningLevel, 30)
        XCTAssertEqual(back.redundancyErrorLevel, 1)
        XCTAssertEqual(back.redundantStepWarningLevel, .off)
    }

    func testAManifestThatIsNotJSONIsUnreadable() throws {
        let run = folder.appendingPathComponent("run-a")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: run.appendingPathComponent("manifest.json"))
        XCTAssertThrowsError(try CoverageMerge.read([folder])) {
            guard case .unreadable(let path, _) = $0 as? CoverageMerge.MergeError else { return XCTFail("\($0)") }
            XCTAssertEqual(URL(fileURLWithPath: path).lastPathComponent, "run-a")
        }
    }

    func testEveryErrorSaysWhatToDo() {
        let errors: [CoverageMerge.MergeError] = [
            .noRuns(["/a", "/b"]),
            .unreadable("/a", "it ends early"),
            .notMeasured("/a", "no binary"),
            .differentBuilds("Calc.add()"),
            .differentSettings("/a", "/b"),
            .incomplete("/a/run-1")
        ]
        XCTAssertEqual(errors.map(\.description), [
            "no run folder, run-<id> with a manifest.json, in /a, /b",
            "can't read the manifest of /a: it ends early",
            "/a has no code coverage to score: no binary",
            "the runs measured different builds: Calc.add() has other regions in each. Merge only the runs of one build.",
            "/b checks the scores against other levels, or measures other sources, than /a. Set the same for every run.",
            "/a/run-1 has files but no manifest.json, so its run stopped before it finished. Run it again, or leave it out."
        ])
    }
}
