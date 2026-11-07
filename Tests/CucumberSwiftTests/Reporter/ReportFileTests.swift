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

    /// The URI of a feature file as a worker running from `copy` of the test bundle reads it.
    private func bundleURI(copy: String, folder: [String] = [], file: String = "Checkout.feature") -> String {
        ([copy, "Tests.xctest", "Features"] + folder + [file]).joined(separator: "/")
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
        file.merge([feature([scenario("A", line: 3)], uri: bundleURI(copy: "clone-1"))])
        file.merge([feature([scenario("B", line: 6)], uri: bundleURI(copy: "clone-2"))])
        XCTAssertEqual(names(file.read()), [["A", "B"]])
    }

    func testFeaturesWithTheSameNameInDifferentFilesStaySeparateInsideTheBundle() {
        let file = ReportFile(url: url)
        file.merge([feature([scenario("A", line: 3)], uri: bundleURI(copy: "clone-1", folder: ["One"]))])
        file.merge([feature([scenario("B", line: 3)], uri: bundleURI(copy: "clone-2", folder: ["Two"]))])
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

    /// Swift Testing runs scenarios of one process side by side: they share the process's one `ReportFile`
    /// for the report (`ReportFile.at`), not a file object each as separate workers do (#420).
    func testWritersInOneProcessSharingTheReportFileLoseNothingAndWriteEachScenarioOnce() {
        let count = 24
        let file = ReportFile.at(url)
        DispatchQueue.concurrentPerform(iterations: count * 2) { index in
            // Each scenario is written twice, as a scenario is when it starts and when it finishes.
            let scenarioIndex = index % count
            ReportFile.at(url).merge([feature([scenario("S\(scenarioIndex)", line: scenarioIndex + 1)])])
        }
        XCTAssertTrue(file === ReportFile.at(url))
        XCTAssertEqual(file.merges, count * 2)
        let names = names(file.read()).first ?? []
        XCTAssertEqual(names, (0..<count).map { "S\($0)" })
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

    func testASerialRunCreatesTheFolderOfTheReportPathSetting() throws {
        Cucumber.shared.reset()
        let nested = folder.appendingPathComponent("not/yet/there/report.json")
        Cucumber.reportPath = nested.path
        addTeardownBlock { Cucumber.reportPath = nil }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        reporter.testSuiteStarted(at: Date())
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path))
    }

    func testAReporterMadeWithAPathKeepsIt() {
        Cucumber.reportPath = "elsewhere/else.json"
        addTeardownBlock { Cucumber.reportPath = nil }
        XCTAssertEqual(CucumberJSONReporter(reportPath: url).reportURL, url)
    }
}

/// The order of a report's features, the bytes of its file, and when it is written (#385).
extension ReportFileTests {
    func testFeaturesAreInTheOrderOfTheirFilesWhicheverWorkerWritesFirst() {
        let accounts = feature([scenario("Sign in", line: 3)], name: "Accounts", uri: bundleURI(copy: "a", file: "Accounts.feature"))
        let checkout = feature([scenario("Pay", line: 3)], name: "Checkout", uri: bundleURI(copy: "a"))
        ReportFile(url: url).merge([checkout])
        ReportFile(url: url).merge([accounts])
        XCTAssertEqual(ReportFile(url: url).read().compactMap { $0["name"] as? String }, ["Accounts", "Checkout"])
    }

    func testFeaturesOfWorkersRunningFromCopiesOfTheBundleAreOrderedByTheirPathInTheBundle() {
        let accounts = feature([scenario("Sign in", line: 3)], name: "Accounts", uri: bundleURI(copy: "clone-9", file: "Accounts.feature"))
        let checkout = feature([scenario("Pay", line: 3)], name: "Checkout", uri: bundleURI(copy: "clone-1"))
        ReportFile(url: url).merge([checkout])
        ReportFile(url: url).merge([accounts])
        XCTAssertEqual(ReportFile(url: url).read().compactMap { $0["name"] as? String }, ["Accounts", "Checkout"])
    }

    func testFeaturesOfOneFileKeepTheOrderTheyAreDeclaredIn() {
        let first = feature([scenario("A", line: 3)], name: "Second declared", uri: "Steps.swift")
        var second = feature([scenario("B", line: 3)], name: "First declared", uri: "Steps.swift")
        second["line"] = 20
        var earlier = first
        earlier["line"] = 10
        ReportFile(url: url).merge([second])
        ReportFile(url: url).merge([earlier])
        XCTAssertEqual(ReportFile(url: url).read().compactMap { $0["name"] as? String }, ["Second declared", "First declared"])
    }

    /// A serial run and a parallel run of the same features write the same bytes, but for each duration,
    /// which differs from one run to the next.
    func testASerialAndAParallelRunWriteTheSameReport() throws {
        func report(parallel: Bool) throws -> String {
            Cucumber.shared.reset()
            Cucumber.parallelTesting = parallel ? true : nil
            let path = folder.appendingPathComponent("\(parallel ? "parallel" : "serial")/report.json")
            Cucumber.reportPath = path.path
            let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
            Feature("Accounts") {
                Scenario("Sign in") {
                    Given(I: print(""))
                    Then(I: print(""))
                }
                Scenario("Sign out") {
                    Given(I: print(""))
                }
            }
            Feature("Checkout") {
                Scenario("Pay") {
                    Given(I: print(""))
                }
            }
            reporter.testSuiteStarted(at: Date())
            Cucumber.shared.executeFeatures()
            reporter.testSuiteFinished(at: Date())
            let text = try String(contentsOf: path, encoding: .utf8)
            return text.replacingOccurrences(of: #""duration" : [0-9.e+-]+"#, with: #""duration" : 0"#, options: .regularExpression)
        }
        addTeardownBlock {
            Cucumber.parallelTesting = nil
            Cucumber.reportPath = nil
        }
        let serial = try report(parallel: false)
        let parallel = try report(parallel: true)
        XCTAssertTrue(serial.contains("Sign out"))
        XCTAssertEqual(serial, parallel)
    }

    func testAParallelRunMergesWhereAScenarioFinishesNotForEveryStep() throws {
        Cucumber.shared.reset()
        Cucumber.parallelTesting = true
        Cucumber.reportPath = url.path
        addTeardownBlock {
            Cucumber.parallelTesting = nil
            Cucumber.reportPath = nil
        }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Feature("F1") {
            Scenario("S1") {
                Given(I: print(""))
                When(I: print(""))
                Then(I: print(""))
                Then(I: print(""))
            }
        }
        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()

        // The suite's start, then the scenario and the feature finishing: not a merge for each of the
        // steps' four starts and four finishes, nor for the starts of the feature and the scenario.
        XCTAssertLessThanOrEqual(ReportFile.at(url).merges, 3)
        // Features other tests parsed from strings may be in the report too, ahead of F1.
        let feature = ReportFile(url: url).read().first { $0["name"] as? String == "F1" }
        let scenarios = feature?["elements"] as? [[String: Any]]
        XCTAssertEqual((scenarios?.first?["steps"] as? [[String: Any]])?.count, 4)
    }

    func testAReportThatCantBeWrittenIsSaidSoOnceNotSilently() throws {
        let blocker = folder.appendingPathComponent("blocker")
        try Data().write(to: blocker)
        let report = ReportFile(url: blocker.appendingPathComponent("report.json"))
        var warnings = [String]()
        let sink = ReportFile.warningSink
        ReportFile.warningSink = { warnings.append($0) }
        addTeardownBlock { ReportFile.warningSink = sink }

        report.merge([feature([scenario("A", line: 3)])])
        report.merge([feature([scenario("A", line: 3)])])
        XCTAssertEqual(warnings.count, 1)
        XCTAssertTrue(warnings.first?.contains(blocker.path) ?? false)
    }

    /// What a report that can't be written says, for each way it can't be.
    private func warnings(whenWriting report: ReportFile, features: [[String: Any]]? = nil) -> [String] {
        var warnings = [String]()
        let sink = ReportFile.warningSink
        ReportFile.warningSink = { warnings.append($0) }
        addTeardownBlock { ReportFile.warningSink = sink }
        report.merge(features ?? [feature([scenario("A", line: 3)])])
        ReportFile.warningSink = sink
        return warnings
    }

    func testAReportThatIsAFolderIsSaidSo() throws {
        let asFolder = folder.appendingPathComponent("a-folder.json")
        try FileManager.default.createDirectory(at: asFolder, withIntermediateDirectories: true)
        XCTAssertEqual(warnings(whenWriting: ReportFile(url: asFolder)).count, 1)
    }

    func testALockFileThatCantBeCreatedIsSaidSo() throws {
        let report = folder.appendingPathComponent("locked.json")
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: report.path + ".lock"), withIntermediateDirectories: true)
        let said = warnings(whenWriting: ReportFile(url: report))
        XCTAssertEqual(said.count, 1)
        XCTAssertTrue(said.first?.contains(".lock") ?? false)
    }

    func testResultsThatCantBeEncodedAreSaidSoAndDontCrash() {
        let unencodable = feature([scenario("A", line: 3)], name: "Bad")
            .merging(["duration": Double.nan]) { _, new in new }
        XCTAssertEqual(warnings(whenWriting: ReportFile(url: url), features: [unencodable]).count, 1)
    }

    func testASerialRunSaysWhenItCantWriteItsReport() throws {
        let blocker = folder.appendingPathComponent("serial-blocker")
        try Data().write(to: blocker)
        Cucumber.shared.reset()
        Cucumber.reportPath = blocker.appendingPathComponent("report.json").path
        addTeardownBlock { Cucumber.reportPath = nil }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        var said = [String]()
        let sink = ReportFile.warningSink
        ReportFile.warningSink = { said.append($0) }
        addTeardownBlock { ReportFile.warningSink = sink }
        reporter.testSuiteStarted(at: Date())
        XCTAssertEqual(said.count, 1)
    }
}
