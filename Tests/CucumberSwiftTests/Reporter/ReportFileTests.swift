//
//  ReportFileTests.swift
//  CucumberSwiftTests
//
//  The workers of a parallel run merge their features into one Cucumber JSON report (#385).
//

import Foundation
import XCTest
@testable import CucumberSwift

class ReportFileTests: XCTestCase {
    private var folder: URL!
    private var url: URL { folder.appendingPathComponent("report.json") }

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("ReportFileTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { [folder] in folder.map { try? FileManager.default.removeItem(at: $0) } }
    }

    private func scenario(_ name: String, line: Int) -> [String: Any] {
        ["name": name, "line": line, "id": name.lowercased(), "keyword": "Scenario", "steps": [[String: Any]]()]
    }

    private func feature(_ scenarios: [[String: Any]], name: String = "Checkout", uri: String = "Checkout.feature") -> [String: Any] {
        ["name": name, "uri": uri, "line": 1, "keyword": "Feature", "elements": scenarios]
    }

    private func names(_ features: [[String: Any]]) -> [[String]] {
        features.map { ($0["elements"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String } }
    }

    func testTwoWorkersFragmentsOfOneFeatureAreMergedInFeatureFileOrder() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("Pay by card", line: 8)])])
        file.merge([feature([scenario("Pay with a gift card", line: 3)])])

        let report = file.read()
        XCTAssertEqual(report.count, 1)
        XCTAssertEqual(names(report), [["Pay with a gift card", "Pay by card"]])
    }

    func testTheSameFeatureFromThreeWorkersHoldsEveryScenarioOnce() {
        let workers = [
            [scenario("A", line: 3), scenario("D", line: 12)],
            [scenario("B", line: 6)],
            [scenario("C", line: 9)]
        ]
        for fragment in workers {
            ReportFile(url: url).merge([feature(fragment)])
        }
        XCTAssertEqual(names(ReportFile(url: url).read()), [["A", "B", "C", "D"]])
    }

    func testAWorkerWritingAgainReplacesItsEarlierResultsForAScenario() throws {
        let file = ReportFile(url: url)
        var started = scenario("A", line: 3)
        started["steps"] = [["name": "a step", "result": ["status": "pending"]]]
        file.merge([feature([started])])
        var finished = scenario("A", line: 3)
        finished["steps"] = [["name": "a step", "result": ["status": "passed"]]]
        file.merge([feature([finished])])

        let elements = try XCTUnwrap(file.read().first?["elements"] as? [[String: Any]])
        XCTAssertEqual(elements.count, 1)
        let steps = try XCTUnwrap(elements.first?["steps"] as? [[String: Any]])
        XCTAssertEqual((steps.first?["result"] as? [String: String])?["status"], "passed")
    }

    func testScenariosWithTheSameNameOnDifferentLinesAreKeptApart() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("Pay by card", line: 11)])])
        file.merge([feature([scenario("Pay by card", line: 20)])])
        XCTAssertEqual(names(file.read()), [["Pay by card", "Pay by card"]])
    }

    func testWorkersRunningFromCopiesOfTheTestBundleMergeTheirFeature() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("A", line: 3)], uri: "file:///clone-1/Runner.app/PlugIns/Tests.xctest/Features/Checkout.feature")])
        file.merge([feature([scenario("B", line: 6)], uri: "file:///clone-2/Runner.app/PlugIns/Tests.xctest/Features/Checkout.feature")])
        XCTAssertEqual(names(file.read()), [["A", "B"]])
    }

    func testFeaturesWithTheSameNameInDifferentFilesStaySeparateInsideTheBundle() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("A", line: 3)], uri: "file:///clone-1/Tests.xctest/Features/One/Checkout.feature")])
        file.merge([feature([scenario("B", line: 3)], uri: "file:///clone-2/Tests.xctest/Features/Two/Checkout.feature")])
        XCTAssertEqual(names(file.read()), [["A"], ["B"]])
    }

    func testDifferentFeaturesStaySeparate() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("Sign in", line: 3)], name: "Accounts", uri: "Accounts.feature")])
        file.merge([feature([scenario("Pay", line: 3)], name: "Checkout", uri: "Checkout.feature")])
        XCTAssertEqual(names(file.read()), [["Sign in"], ["Pay"]])
    }

    func testAMissingReportReadsAsEmptyAndTheFirstMergeCreatesIt() {
        let file = ReportFile(url: url)
        XCTAssertEqual(file.read().count, 0)
        file.merge([feature([scenario("A", line: 3)])])
        XCTAssertEqual(names(file.read()), [["A"]])
    }

    func testAnEmptyOrUnreadableReportIsReplacedByTheMerge() throws {
        for content in ["", "not json", "{}"] {
            try Data(content.utf8).write(to: url)
            let file = ReportFile(url: url)
            XCTAssertEqual(file.read().count, 0, content)
            file.merge([feature([scenario("A", line: 3)])])
            XCTAssertEqual(names(file.read()), [["A"]], content)
        }
    }

    func testMergingNothingLeavesTheReportAlone() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("A", line: 3)])])
        file.merge([])
        XCTAssertEqual(names(file.read()), [["A"]])
    }

    func testWorkersWritingAtTheSameTimeLoseNothing() {
        let count = 12
        DispatchQueue.concurrentPerform(iterations: count) { index in
            // A file object of its own for each worker, as each worker process has.
            ReportFile(url: url).merge([feature([scenario("S\(index)", line: index + 1)])])
        }
        XCTAssertEqual(ReportFile(url: url).read().first.flatMap { ($0["elements"] as? [Any])?.count }, count)
    }

    func testTheFirstWorkerOfANewRunEmptiesAStaleReport() throws {
        ReportFile(url: url).merge([feature([scenario("Old", line: 3)])])
        let old = Date(timeIntervalSinceNow: -3_600)
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: url.path)

        let first = ReportFile(url: url)
        first.joinRun()
        XCTAssertEqual(first.read().count, 0)
    }

    func testAWorkerThatStartsInTheMiddleOfARunKeepsTheReport() {
        let first = ReportFile(url: url)
        first.joinRun()
        first.merge([feature([scenario("A", line: 3)])])

        let second = ReportFile(url: url)
        second.joinRun()
        XCTAssertEqual(names(second.read()), [["A"]])
    }

    func testAWorkerThatStartsAfterAnotherFinishedKeepsTheFreshReport() {
        let first = ReportFile(url: url)
        first.joinRun()
        first.merge([feature([scenario("A", line: 3)])])
        // The first worker has exited, so nothing holds the run: the report is still recent.
        let second = ReportFile(url: url)
        second.joinRun()
        second.merge([feature([scenario("B", line: 6)])])
        XCTAssertEqual(names(second.read()), [["A", "B"]])
    }

    /// Runs one feature through the reporter with a report at `url` that another worker already wrote to,
    /// and returns the names of the features the report holds afterwards.
    private func featureNamesAfterARunBesideAnotherWorker() throws -> [String] {
        Cucumber.shared.reset()
        Cucumber.reportPath = url.path
        addTeardownBlock { Cucumber.reportPath = nil }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        ReportFile(url: url).merge([feature([scenario("Elsewhere", line: 3)], name: "Other", uri: "Other.feature")])
        Feature("F1") {
            Scenario("S1") {
                Given(I: print(""))
            }
        }
        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()
        return ReportFile(url: url).read().compactMap { $0["name"] as? String }
    }

    func testTheReporterMergesItsFeaturesIntoTheSharedReportWhenParallelTestingIsOn() throws {
        Cucumber.parallelTesting = true
        addTeardownBlock { Cucumber.parallelTesting = nil }
        XCTAssertEqual(try featureNamesAfterARunBesideAnotherWorker().sorted(), ["F1", "Other"])
    }

    func testTheReporterReplacesTheReportWhenParallelTestingIsOff() throws {
        XCTAssertEqual(try featureNamesAfterARunBesideAnotherWorker(), ["F1"])
    }

    func testTheReporterWritesToTheReportPathSetting() throws {
        let path = folder.appendingPathComponent("elsewhere/report.json").path
        Cucumber.reportPath = path
        addTeardownBlock { Cucumber.reportPath = nil }
        let reporter = try XCTUnwrap(CucumberJSONReporter())
        XCTAssertEqual(reporter.reportURL.path, path)
        XCTAssertEqual(Reporter.reportURL?.path, path)
    }

    func testAReporterMadeWithAPathKeepsIt() {
        Cucumber.reportPath = "elsewhere/else.json"
        addTeardownBlock { Cucumber.reportPath = nil }
        XCTAssertEqual(CucumberJSONReporter(reportPath: url).reportURL, url)
    }
}
