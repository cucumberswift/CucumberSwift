//
//  ParallelTestingTests+WithoutTheSetting.swift
//  CucumberSwiftTests
//
//  Xcode's parallel testing without `Cucumber.parallelTesting` fails with a message naming the setting
//  (#389). An extension of ParallelTestingTests, so that it shares its setup.
//

import Foundation
import XCTest
@testable import CucumberSwift

extension ParallelTestingTests {
    // Xcode's parallel testing without the setting runs scenarios in every worker, or not at all, and the run
    // can pass (#389), so the first test of a parallel worker fails with a message that names the setting.
    private func issues(isParallelRun: Bool, tests: Int = 2) -> [String] {
        var messages = [String]()
        let observer = ParallelWorkerObserver(isParallelRun: { isParallelRun }, report: { _, issue in
            messages.append(issue.compactDescription)
        })
        _ = parseFeature()
        (0..<tests).forEach { _ in observer.testCaseWillStart(self) }
        return messages
    }

    func testAParallelRunWithoutTheSettingFailsOnceWithAMessageNamingIt() {
        let messages = issues(isParallelRun: true)

        XCTAssertEqual(messages, [ParallelWorkerObserver.message])
        XCTAssertTrue(ParallelWorkerObserver.message.contains("Cucumber.parallelTesting = true"))
        XCTAssertTrue(ParallelWorkerObserver.message.contains("CUCUMBER_PARALLEL_TESTING"))
    }

    func testAParallelRunWithTheSettingOffExplicitlyFails() {
        Cucumber.parallelTesting = false

        XCTAssertEqual(issues(isParallelRun: true).count, 1)
    }

    func testASerialRunDoesNotFail() {
        XCTAssertEqual(issues(isParallelRun: false), [])
    }

    func testAParallelRunWithTheSettingOnDoesNotFail() {
        Cucumber.parallelTesting = true

        XCTAssertEqual(issues(isParallelRun: true), [])
    }

    func testAParallelRunWithOneTestPerScenarioDoesNotFail() {
        Cucumber.oneTestPerScenario = true

        XCTAssertEqual(issues(isParallelRun: true), [])
    }

    func testTheSettingIsReadFromTheEnvironmentToo() {
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = "YES"
        addTeardownBlock { Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = nil }

        XCTAssertEqual(issues(isParallelRun: true), [])
    }

    // Without the setting the scenarios would run in every worker, and xcodebuild can crash on them, so
    // CucumberTest's suite is one failing test instead of the scenarios, and the run fails once.
    func testTheSuiteIsOneFailingTestInsteadOfTheScenariosInAParallelRunWithoutTheSetting() {
        _ = parseFeature()

        let name = "CucumberSwiftParallelTestingIsOff\(ProcessInfo.processInfo.processIdentifier)"
        let suite = CucumberTest.failureSuite(method: "ParallelTestingIsOff", message: ParallelWorkerObserver.message, name: name)

        XCTAssertTrue(ParallelWorkerObserver.isMissingSetting { true })
        XCTAssertEqual(suite.name, name)
        XCTAssertEqual(suite.tests.map(\.name).count, 1)
        XCTAssertTrue(suite.tests.first?.name.contains("ParallelTestingIsOff") == true, "\(suite.tests.map(\.name))")
    }

    // A parallel worker told the run is wrong must not be told twice: the suite's failing test is started
    // after CucumberTest's suite reported it.
    func testTheObserverDoesNotReportAgainOnceTheSuiteDid() {
        _ = parseFeature()
        ParallelWorkerObserver.reported.withLock { $0 = true }

        XCTAssertEqual(issues(isParallelRun: true), [])
    }

    // Without the setting, a worker's CucumberTest suite is the failing test, and no scenario runs.
    func testCucumberTestHoldsOneFailingTestInsteadOfTheScenariosInAParallelRunWithoutTheSetting() {
        let title = parseFeature()
        ParallelWorkerObserver.parallelRunProbe.withLock { $0 = { true } }

        let names = CucumberTest.defaultTestSuite.tests.map(\.name)

        XCTAssertEqual(names.count, 1, "\(names)")
        XCTAssertTrue(names.first?.contains("ParallelTestingIsOff") == true, "\(names)")
        XCTAssertFalse(names.contains { $0.contains(title) }, "\(names)")
        XCTAssertTrue(ParallelWorkerObserver.reported.snapshot)
    }

    // The failure XCTest shows is an issue on the test that started first, recorded while that test runs.
    @available(iOS 14, macOS 11, tvOS 14, macCatalyst 14, *)
    func testTheObserverRecordsTheIssueOnTheTestThatStartedWhileItRuns() {
        _ = parseFeature()
        let observer = ParallelWorkerObserver { true }
        XCTExpectFailure("The observer fails the first test of a parallel run without the setting")

        observer.testCaseWillStart(self)

        XCTAssertTrue(ParallelWorkerObserver.reported.snapshot)
    }
}
