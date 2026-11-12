//
//  CoverageMergeTests.swift
//  CucumberSwiftTests
//
//  cucumberswift coverage merge scores the scenarios of several runs, such as a parallel run's workers or a
//  suite's shards, as one run (#515).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageMergeTests: CoverageMergeTestCase {
    func testAParallelRunsWorkersMergedScoreAsOneRunOfAllTheirScenarios() throws {
        let serial = serialParts(scenarios)
        // Two workers, each with the scenarios Xcode gave it, in the order it ran them. The second numbers the
        // functions in another order.
        let merged = try CoverageMerge(runs: [
            run(manifest([scenarios[4], scenarios[1], scenarios[2]], order: functions)),
            run(manifest([scenarios[3], scenarios[0]], order: functions.reversed()))
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
            run(manifest([scenarios[1], scenarios[2]], order: functions, settings: settings)),
            run(manifest([scenarios[0], scenarios[3], scenarios[4]], order: functions, settings: settings))
        ])
        var lines = [String]()
        XCTAssertTrue(merged.report { lines.append($0) })

        var expected = ["CucumberSwift coverage: 5 scenarios from 2 runs scored as one run"]
        for part in serialParts(scenarios, settings: settings) {
            let report = CoverageReport.report(part,
                                               featureName: "Arithmetic",
                                               featureLine: 1,
                                               file: URL(string: issueFile),
                                               settings: settings)
            expected.append(report.summary)
            expected += report.issues.map { "/src/Arithmetic.feature:\($0.line): \($0.severity == .warning ? "warning" : "error"): \($0.message)" }
        }
        XCTAssertEqual(lines, expected)
        XCTAssertTrue(lines.contains { $0.hasPrefix("/src/Arithmetic.feature:1: error: Feature coverage") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.hasPrefix("/src/Arithmetic.feature:20: error: Rule coverage") }, "\(lines)")
    }

    func testWithoutAnErrorTheReportSaysThereIsNone() throws {
        let merged = try CoverageMerge(runs: [run(manifest(scenarios, order: functions))])
        XCTAssertFalse(merged.report { _ in
            // Only the result matters here.
        })
    }

    func testAScenarioThatRanInTwoRunsIsScoredOnce() throws {
        let merged = try CoverageMerge(runs: [
            run(manifest(scenarios, order: functions)),
            run(manifest([scenarios[0]], order: functions))
        ])
        XCTAssertEqual(merged.features.map(\.part), serialParts(scenarios))
        XCTAssertEqual(merged.repeatedCount, 1)
        var lines = [String]()
        _ = merged.report { lines.append($0) }
        XCTAssertEqual(lines.first, "CucumberSwift coverage: 5 scenarios from 2 runs scored as one run, 1 scenario that ran again scored once")
    }

    func testAFeatureInAnotherSimulatorsTestBundleIsTheSameFeature() throws {
        let other = feature.replacingOccurrences(of: "/Devices/A/", with: "/Devices/B/")
        let merged = try CoverageMerge(runs: [
            run(manifest(Array(scenarios[..<2]), order: functions)),
            run(manifest(Array(scenarios[2...]), order: functions, uri: other))
        ])
        XCTAssertEqual(merged.features.map(\.part), serialParts(scenarios))
        XCTAssertEqual(CoverageMerge.featureKey(feature), "MyTests.xctest/Features/Arithmetic.feature")
        XCTAssertEqual(CoverageMerge.featureKey(issueFile), issueFile)
    }

    func testTheSameFilePathInTwoTestBundlesIsTwoFeatures() throws {
        let other = feature.replacingOccurrences(of: "MyTests.xctest", with: "OtherTests.xctest")
        let merged = try CoverageMerge(runs: [
            run(manifest(scenarios, order: functions)),
            run(manifest(scenarios, order: functions, uri: other))
        ])
        XCTAssertEqual(merged.scenarioCount, 10)
        XCTAssertEqual(merged.repeatedCount, 0)
        XCTAssertEqual(merged.features.count, 4)
    }

    func testRunsOfDifferentBuildsAreNotMerged() {
        let changed = [Function(name: "add", regions: 3)] + functions.dropFirst()
        XCTAssertThrowsError(try CoverageMerge(runs: [
            run(manifest(scenarios, order: functions)),
            run(manifest(scenarios, order: changed))
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentBuilds("Calc.add()"))
        }
    }

    func testRunsOfFunctionsWithTheSameRegionCountAtOtherPlacesAreNotMerged() {
        var base = manifest(scenarios, order: functions)
        base.measured?[0].spans = [[1, 1, 1, 9], [2, 1, 2, 9]]
        var other = base
        other.measured?[0].spans = [[1, 1, 1, 9], [5, 1, 5, 9]]
        XCTAssertThrowsError(try CoverageMerge(runs: [
            run(base),
            run(other)
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentBuilds("Calc.add()"))
        }
    }

    func testFunctionsNothingTellsApartAreRefusedNotMatchedByOrder() {
        var manifest = manifest(scenarios, order: functions)
        // Two functions with one mangled name, file name and line, in two folders.
        manifest.measured = manifest.measured?.enumerated().map { index, function in
            var function = function
            if index < 2 {
                function.name = "$s5Calc4same"
                function.line = 10
                function.file = "/src/\(index)/Calc.swift"
            }
            return function
        }
        XCTAssertThrowsError(try CoverageMerge(runs: [run(manifest)])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .ambiguous("Calc.classify()"))
        }
    }

    func testAFunctionSharingItsNameInOneRunOnlyIsStillRefusedWhenItsRegionsDiffer() {
        func function(_ line: Int, regions: Int, file: String) -> CoverageManifest.MeasuredFunction {
            .init(binary: "MyTests", name: "$s5Calc1f", readableName: "Calc.f()", file: file, line: line, regions: regions, spans: nil)
        }
        XCTAssertThrowsError(try CoverageMerge.renumber([
            [function(10, regions: 2, file: "/a/F.swift")],
            [function(10, regions: 3, file: "/a/F.swift"), function(20, regions: 1, file: "/b/F.swift")]
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentBuilds("Calc.f()"))
        }
    }

    func testTheSameBuildInAnotherCheckoutFolderIsTheSameBuild() throws {
        // Both runs also measure a file outside the checkout, so the folders they share is only the root.
        func build(_ scenarios: [Ran], checkout: String) -> CoverageManifest {
            var manifest = manifest(scenarios, order: functions)
            manifest.measured = manifest.measured?.enumerated().map { index, function in
                var function = function
                function.file = index == 2 ? "/opt/shared/Generated.swift" : "\(checkout)/Calc.swift"
                return function
            }
            return manifest
        }
        let merged = try CoverageMerge(runs: [
            run(build(Array(scenarios[..<2]), checkout: "/src")),
            run(build(Array(scenarios[2...]), checkout: "/agent-b/repo"))
        ])
        XCTAssertEqual(merged.code.functions.count, 3)
        XCTAssertEqual(merged.features.map(\.part), serialParts(scenarios))
    }

    func testFunctionsOfTheSameNameInFilesOfTheSameNameStayApartWhateverOrderARunListsThem() throws {
        func build(_ scenarios: [Ran], reversed: Bool) -> CoverageManifest {
            var manifest = manifest(scenarios, order: functions)
            // The first two functions now share a mangled name and a file name, in two folders, and are told
            // apart by their lines.
            manifest.measured = manifest.measured?.enumerated().map { index, function in
                var function = function
                if index < 2 {
                    function.name = "$s5Calc4same"
                    function.file = "/src/\(index)/Calc.swift"
                }
                return function
            }
            if reversed { manifest.measured?.swapAt(0, 1) }
            return manifest
        }
        let merged = try CoverageMerge(runs: [
            run(build(Array(scenarios[..<2]), reversed: false)),
            run(build(Array(scenarios[2...]), reversed: true))
        ])
        XCTAssertEqual(merged.code.functions.count, 3)
        XCTAssertEqual(merged.code.functions.map(\.line), [10, 20, 30])
    }

    func testRunsThatMeasureOtherSourcesAreNotMerged() {
        var settings = CoverageSettings()
        settings.sources = ["Sources/B"]
        XCTAssertThrowsError(try CoverageMerge(runs: [
            run(manifest(scenarios, order: functions), at: "/a"),
            run(manifest(scenarios, order: functions, settings: settings), at: "/b")
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentSettings("/a", "/b"))
        }
    }

    func testRunsWithDifferentLevelsAreNotMerged() {
        var settings = CoverageSettings()
        settings.warningLevel = 50
        XCTAssertThrowsError(try CoverageMerge(runs: [
            run(manifest(scenarios, order: functions), at: "/a"),
            run(manifest(scenarios, order: functions, settings: settings), at: "/b")
        ])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .differentSettings("/a", "/b"))
        }
    }

    func testARunWithoutTheCodeItMeasuredIsNotMergedAndSaysWhy() {
        var old = manifest(scenarios, order: functions)
        old.measured = nil
        old.scoresProblem = nil
        XCTAssertThrowsError(try CoverageMerge(runs: [run(old, at: "/a")])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError,
                           .notMeasured("/a", "its manifest is from a version of CucumberSwift that doesn't record what the scores need"))
        }
        var failed = manifest(scenarios, order: functions)
        failed.problem = "No binary in the test process was built with code coverage."
        XCTAssertThrowsError(try CoverageMerge(runs: [run(failed, at: "/a")])) {
            XCTAssertEqual($0 as? CoverageMerge.MergeError, .notMeasured("/a", "No binary in the test process was built with code coverage."))
        }
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
