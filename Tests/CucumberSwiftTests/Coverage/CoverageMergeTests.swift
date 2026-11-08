//
//  CoverageMergeTests.swift
//  CucumberSwiftTests
//
//  cucumberswift-coverage-merge scores the scenarios of several runs, such as a parallel run's workers or a
//  suite's shards, as one run (#515).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageMergeTests: XCTestCase {
    /// A function of the code under test: its key in every run, and its regions.
    private struct Function {
        let name: String
        let regions: Int
    }

    /// A scenario, and the regions it ran, by function and region within it.
    private struct Ran {
        let line: Int
        let name: String
        var rule: ScenarioRule?
        var group: String?
        var background = [(String, Int)]()
        var steps = [(line: Int, regions: [(String, Int)])]()
        var duration = 0.25

        init(line: Int, name: String, rule: ScenarioRule? = nil, group: String? = nil,
             background: [(String, Int)] = [], steps: [(line: Int, regions: [(String, Int)])]) {
            self.line = line
            self.name = name
            self.rule = rule
            self.group = group
            self.background = background
            self.steps = steps
        }

        var regions: [(String, Int)] { background + steps.flatMap(\.regions) }
    }

    private let functions = [Function(name: "add", regions: 2), Function(name: "classify", regions: 4), Function(name: "unused", regions: 3)]
    private let feature = "file:///Users/me/Library/Developer/CoreSimulator/Devices/A/App.app/PlugIns/MyTests.xctest/Features/Arithmetic.feature"
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CoverageMergeTests-\(UUID().uuidString)")
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    private var scenarios: [Ran] {
        let rule = ScenarioRule(title: "Naming numbers", line: 20)
        return [
            Ran(line: 4, name: "Adding", background: [("classify", 0)], steps: [(5, [("add", 0)])]),
            Ran(line: 8, name: "Adding again", background: [("classify", 0)], steps: [(9, [("add", 0)])]),
            Ran(line: 12, name: "Adding more", background: [("classify", 0)], steps: [(13, [("add", 1)])]),
            Ran(line: 23, name: "Naming seven", rule: rule, group: "24", steps: [(24, [("classify", 0), ("classify", 1)])]),
            Ran(line: 30, name: "Naming eight", rule: rule, group: "24", steps: [(24, [("classify", 0), ("classify", 2)])])
        ]
    }

    /// The run's manifest, which numbers the functions' regions in the order `order` lists them.
    private func manifest(_ scenarios: [Ran], order: [Function], settings: CoverageSettings = CoverageSettings(), uri: String? = nil) -> CoverageManifest {
        var first = [String: Int]()
        var next = 0
        for function in order {
            first[function.name] = next
            next += function.regions
        }
        func numbers(_ regions: [(String, Int)]) -> [Int] {
            regions.compactMap { name, index in first[name].map { $0 + index } }.sorted()
        }
        let records = scenarios.map { ran in
            CoverageManifest.ScenarioRecord(
                feature: uri ?? feature,
                featureName: "Arithmetic",
                line: ran.line,
                name: ran.name,
                tags: [],
                profiles: [],
                duration: ran.duration,
                featureLine: 1,
                issueFile: "file:///src/Arithmetic.feature",
                coverage: .init(regions: numbers(ran.regions),
                                backgroundRegions: numbers(ran.background),
                                steps: ran.steps.map { .init(line: $0.line, regions: numbers($0.regions)) },
                                group: ran.group ?? "line \(ran.line)",
                                rule: ran.rule?.title,
                                ruleLine: ran.rule?.line))
        }
        return CoverageManifest(
            run: UUID().uuidString,
            startDate: Date(),
            binaries: [],
            scenarios: records,
            scoresProblem: "parallel testing",
            measured: order.enumerated().map { index, function in
                .init(binary: "MyTests", name: "$s5Calc\(function.name)", readableName: "Calc.\(function.name)()", file: "/src/Calc.swift",
                      line: 10 * (index + 1), regions: function.regions)
            },
            settings: .init(settings))
    }

    /// The parts that a run of all `scenarios`, one at a time, scores, as the recorder scores them.
    private func serialParts(_ scenarios: [Ran], settings: CoverageSettings = CoverageSettings()) throws -> [CoverageScores.Part] {
        var first = [String: Int]()
        var measured = [MeasuredCode.Function]()
        for (index, function) in functions.enumerated() {
            let start = measured.last?.regions.upperBound ?? 0
            first[function.name] = start
            measured.append(.init(name: "Calc.\(function.name)()", file: "/src/Calc.swift", line: 10 * (index + 1), regions: start..<start + function.regions))
        }
        func numbers(_ regions: [(String, Int)]) -> Set<Int> {
            Set(regions.compactMap { name, index in first[name].map { $0 + index } })
        }
        let ran = scenarios.map { ran in
            (rule: ran.rule,
             scenario: CoverageScores.Scenario(name: ran.name, line: ran.line, tags: [], duration: ran.duration, regions: numbers(ran.regions), group: ran.group)
                .with(backgroundRegions: numbers(ran.background))
                .with(steps: ran.steps.map { CoverageScores.StepRun(line: $0.line, regions: numbers($0.regions)) }))
        }
        return CoverageScores.parts(of: ran, code: MeasuredCode(functions: measured), isRedundancy: settings.isRedundancy)
    }

    func testAParallelRunsWorkersMergedScoreAsOneRunOfAllTheirScenarios() throws {
        let serial = try serialParts(scenarios)
        // Two workers, each with the scenarios Xcode gave it, in the order it ran them. The second numbers the
        // functions in another order.
        let merged = try CoverageMerge(runs: [
            .init(folder: folder, manifest: manifest([scenarios[4], scenarios[1], scenarios[2]], order: functions)),
            .init(folder: folder, manifest: manifest([scenarios[3], scenarios[0]], order: functions.reversed()))
        ])
        XCTAssertEqual(merged.features.map(\.part), serial)
        XCTAssertEqual(merged.features.map(\.part.rule?.title), [nil, "Naming numbers"])
        XCTAssertEqual(merged.scenarioCount, 5)

        let all = try XCTUnwrap(serial.first?.scores)
        // "Adding again" is redundant: "Adding" runs its code first. "Adding more" runs a region of its own.
        XCTAssertEqual(all.scenarios.map(\.line), [4, 8, 12])
        XCTAssertEqual(all.scenarios.map(\.addsNothing), [false, true, false])
        XCTAssertEqual(all.measuredRegions, 9)
        XCTAssertEqual(all.redundantSteps.map(\.line), [5, 9])
    }

    func testTheSummaryAndIssuesAreTheOnesARunPrints() throws {
        var settings = CoverageSettings()
        settings.errorLevel = 90
        let merged = try CoverageMerge(runs: [
            .init(folder: folder, manifest: manifest([scenarios[1], scenarios[2]], order: functions, settings: settings)),
            .init(folder: folder, manifest: manifest([scenarios[0], scenarios[3], scenarios[4]], order: functions, settings: settings))
        ])
        var lines = [String]()
        XCTAssertTrue(merged.report { lines.append($0) })

        var expected = ["CucumberSwift coverage: 5 scenarios from 2 runs scored as one run"]
        for part in try serialParts(scenarios, settings: settings) {
            let report = CoverageReport.report(part, featureName: "Arithmetic", featureLine: 1,
                                               file: URL(string: "file:///src/Arithmetic.feature"), settings: settings)
            expected.append(report.summary)
            expected += report.issues.map { "/src/Arithmetic.feature:\($0.line): \($0.severity == .warning ? "warning" : "error"): \($0.message)" }
        }
        XCTAssertEqual(lines, expected)
        XCTAssertTrue(lines.contains { $0.hasPrefix("/src/Arithmetic.feature:1: error: Feature coverage") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.hasPrefix("/src/Arithmetic.feature:20: error: Rule coverage") }, "\(lines)")
    }

    func testWithoutAnErrorTheReportSaysThereIsNone() throws {
        let merged = try CoverageMerge(runs: [.init(folder: folder, manifest: manifest(scenarios, order: functions))])
        XCTAssertFalse(merged.report { _ in
            // Only the result matters here.
        })
    }

    func testAScenarioThatRanInTwoRunsIsScoredOnce() throws {
        let merged = try CoverageMerge(runs: [
            .init(folder: folder, manifest: manifest(scenarios, order: functions)),
            .init(folder: folder, manifest: manifest([scenarios[0]], order: functions))
        ])
        XCTAssertEqual(merged.features.map(\.part), try serialParts(scenarios))
        XCTAssertEqual(merged.repeatedCount, 1)
        var lines = [String]()
        _ = merged.report { lines.append($0) }
        XCTAssertEqual(lines.first, "CucumberSwift coverage: 5 scenarios from 2 runs scored as one run, 1 scenario that ran again scored once")
    }

    func testAFeatureInAnotherSimulatorsTestBundleIsTheSameFeature() throws {
        let other = feature.replacingOccurrences(of: "/Devices/A/", with: "/Devices/B/")
        let merged = try CoverageMerge(runs: [
            .init(folder: folder, manifest: manifest(Array(scenarios[..<2]), order: functions)),
            .init(folder: folder, manifest: manifest(Array(scenarios[2...]), order: functions, uri: other))
        ])
        XCTAssertEqual(merged.features.map(\.part), try serialParts(scenarios))
        XCTAssertEqual(CoverageMerge.featureKey(feature), "Features/Arithmetic.feature")
        XCTAssertEqual(CoverageMerge.featureKey("file:///src/Arithmetic.feature"), "file:///src/Arithmetic.feature")
    }

    func testRunsOfDifferentBuildsAreNotMerged() {
        let changed = [Function(name: "add", regions: 3)] + functions.dropFirst()
        XCTAssertThrowsError(try CoverageMerge(runs: [
            .init(folder: folder, manifest: manifest(scenarios, order: functions)),
            .init(folder: folder, manifest: manifest(scenarios, order: changed))
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentBuilds("Calc.add()"))
        }
    }

    func testRunsWithDifferentLevelsAreNotMerged() {
        var settings = CoverageSettings()
        settings.warningLevel = 50
        XCTAssertThrowsError(try CoverageMerge(runs: [
            .init(folder: URL(fileURLWithPath: "/a"), manifest: manifest(scenarios, order: functions)),
            .init(folder: URL(fileURLWithPath: "/b"), manifest: manifest(scenarios, order: functions, settings: settings))
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentSettings("/a", "/b"))
        }
    }

    func testARunWithoutTheCodeItMeasuredIsNotMergedAndSaysWhy() {
        var old = manifest(scenarios, order: functions)
        old.measured = nil
        old.scoresProblem = nil
        XCTAssertThrowsError(try CoverageMerge(runs: [.init(folder: URL(fileURLWithPath: "/a"), manifest: old)])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError,
                           .notMeasured("/a", "its manifest is from a version of CucumberSwift that doesn't record what the scores need"))
        }
        var failed = manifest(scenarios, order: functions)
        failed.problem = "No binary in the test process was built with code coverage."
        XCTAssertThrowsError(try CoverageMerge(runs: [.init(folder: URL(fileURLWithPath: "/a"), manifest: failed)])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .notMeasured("/a", "No binary in the test process was built with code coverage."))
        }
    }

    func testTheRunsAreReadFromTheirFoldersOrTheFolderThatHoldsThem() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        for (name, ran) in [("run-a", Array(scenarios[..<3])), ("run-b", Array(scenarios[3...]))] {
            let run = folder.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
            try encoder.encode(manifest(ran, order: functions)).write(to: run.appendingPathComponent("manifest.json"))
        }
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("run-empty"), withIntermediateDirectories: true)

        XCTAssertEqual(CoverageMerge.runFolders(in: [folder]).map(\.lastPathComponent), ["run-a", "run-b"])
        XCTAssertEqual(CoverageMerge.runFolders(in: [folder.appendingPathComponent("run-b")]).map(\.lastPathComponent), ["run-b"])
        let merged = try CoverageMerge(runs: CoverageMerge.read([folder]))
        XCTAssertEqual(merged.features.map(\.part), try serialParts(scenarios))

        XCTAssertThrowsError(try CoverageMerge.read([folder.appendingPathComponent("run-empty")])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .noRuns([folder.appendingPathComponent("run-empty").path]))
        }
    }

    func testAManifestOfAnotherVersionIsRefused() throws {
        var newer = manifest(scenarios, order: functions)
        newer.version = 2
        let run = folder.appendingPathComponent("run-a")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(newer).write(to: run.appendingPathComponent("manifest.json"))
        let found = try XCTUnwrap(CoverageMerge.runFolders(in: [folder]).first)
        XCTAssertThrowsError(try CoverageMerge.read([folder])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .unreadable(found.path, "its version is 2, and this reads version 1"))
        }
    }

    func testRenumberingGivesEachFunctionOnePlaceWhateverOrderARunListsItsFunctionsIn() throws {
        func listed(_ order: [Function]) -> [CoverageManifest.MeasuredFunction] {
            order.map { .init(binary: "MyTests", name: "$s5Calc\($0.name)", readableName: "Calc.\($0.name)()", file: "/src/Calc.swift",
                              line: 1, regions: $0.regions, spans: (0..<$0.regions).map { [$0 + 1, 1, $0 + 1, 9] }) }
        }
        let renumbering = try CoverageMerge.renumber([listed(functions), listed(functions.reversed()), []])
        XCTAssertEqual(renumbering.functions.map(\.name), ["Calc.add()", "Calc.classify()", "Calc.unused()"])
        XCTAssertEqual(renumbering.functions.map(\.regions), [0..<2, 2..<6, 6..<9])
        XCTAssertEqual(renumbering.maps, [Array(0..<9), [6, 7, 8, 2, 3, 4, 5, 0, 1], []])
        XCTAssertEqual(renumbering.spans.first??.first, [1, 1, 1, 9])
        XCTAssertThrowsError(try CoverageMerge.renumber([listed(functions), listed([Function(name: "add", regions: 3)])])) {
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

    func testEachPartScoresItsScenariosInTheOrderOfTheFeatureFile() {
        let code = MeasuredCode(functions: [.init(name: "f", file: "/f.swift", line: 1, regions: 0..<2)])
        let first = CoverageScores.Scenario(name: "First", line: 3, tags: [], duration: 0, regions: [0])
        let second = CoverageScores.Scenario(name: "Second", line: 7, tags: [], duration: 0, regions: [0])
        let parts = CoverageScores.parts(of: [(nil, second), (nil, first)], code: code, isRedundancy: true)
        // The two run the same code, and the later one in the file is the redundant one, whichever ran first.
        XCTAssertEqual(parts.first?.scores.scenarios.map(\.line), [3, 7])
        XCTAssertEqual(parts.first?.scores.scenarios.map(\.addsNothing), [false, true])
    }
}
