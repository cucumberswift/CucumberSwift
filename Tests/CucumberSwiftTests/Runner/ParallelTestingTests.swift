//
//  ParallelTestingTests.swift
//  CucumberSwiftTests
//
//  With experimental parallel testing, each scenario gets a class of its own before XCTest lists the
//  classes to hand to its parallel workers, and CucumberTest's suite then leaves the scenarios out (#31).
//  These tests build the suites and classes; they don't run the scenarios.
//

import Foundation
import XCTest
@testable import CucumberSwift

class ParallelTestingTests: XCTestCase {
    private static func reset() {
        Cucumber.parallelTesting = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.shared.reset()
        CucumberTest.resetSetUp()
        ParallelWorkerObserver.reported.withLock { $0 = false }
        ParallelWorkerObserver.parallelRunProbe.withLock { $0 = { ParallelWorkerObserver.isParallelRun() } }
    }

    override func setUpWithError() throws {
        Self.reset()
        addTeardownBlock { Self.reset() }
    }

    /// Parses a feature with a title of its own, so that no earlier test has taken its classes' names. The
    /// features count as loaded, so that the bundle's Features folder is not read.
    private func parseFeature() -> String {
        let title = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(title)
           Scenario: Pay with a gift card
             Given a cart
             When I pay with a gift card
           Scenario: Pay by card
             Given a cart
        """)
        CucumberTest.featuresLoaded = true
        return title
    }

    private func scenarioClass(_ title: String, _ scenario: String) -> XCTestCase.Type? {
        NSClassFromString(title + CucumberTest.readFeatureScenarioDelimiter() + scenario) as? XCTestCase.Type
    }

    @MainActor
    func testEachScenarioGetsAClassWhoseSuiteIsItsStepsInOrder() throws {
        let title = parseFeature()

        ParallelTesting.makeScenarioClasses()

        let giftCard = try XCTUnwrap(scenarioClass(title, "Pay with a gift card"))
        let names = giftCard.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(names.count, 2, "\(names)")
        XCTAssertTrue(names.first?.hasSuffix("1 \u{203A} Given a cart]") == true, "\(names)")
        XCTAssertTrue(names.last?.hasSuffix("2 \u{203A} When I pay with a gift card]") == true, "\(names)")
        XCTAssertEqual(try XCTUnwrap(scenarioClass(title, "Pay by card")).defaultTestSuite.tests.count, 1)
        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
    }

    // Two workers can run two scenarios with the same name at once, and xcodebuild crashes when two suites
    // with the same name run at once, so each suite is named after its class, which is unique.
    @MainActor
    func testScenariosWithTheSameNameHaveSuitesWithDifferentNames() throws {
        let title = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(title)
           Scenario: Pay by card
             Given a cart
           Scenario: Pay by card
             Given a cart
        """)
        CucumberTest.featuresLoaded = true

        ParallelTesting.makeScenarioClasses()

        let name = title + CucumberTest.readFeatureScenarioDelimiter() + "Pay by card"
        let first = try XCTUnwrap(NSClassFromString(name) as? XCTestCase.Type)
        let second = try XCTUnwrap(NSClassFromString(name + "1") as? XCTestCase.Type)
        XCTAssertEqual(first.defaultTestSuite.name, name)
        XCTAssertEqual(second.defaultTestSuite.name, name + "1")
    }

    // XCTest groups test classes by their bundle. A class made at run time would otherwise be in the main
    // bundle, which in a test target hosted in an app is the app, and xcodebuild crashes on that.
    @MainActor
    func testEachScenarioClassIsInTheTestBundleAndOtherClassesAreNot() throws {
        let title = parseFeature()

        ParallelTesting.makeScenarioClasses()

        let testBundle = try XCTUnwrap((Cucumber.shared as? StepImplementation)?.bundle)
        XCTAssertEqual(Bundle(for: try XCTUnwrap(scenarioClass(title, "Pay by card"))), testBundle)
        XCTAssertEqual(Bundle(for: ParallelTestingTests.self), Bundle(for: CucumberSwiftTests.self))
        XCTAssertEqual(Bundle(for: CucumberTest.self), Bundle(for: Cucumber.self))
    }

    @MainActor
    func testCucumberTestLeavesTheScenariosOutOnceTheirClassesAreMade() {
        let title = parseFeature()
        ParallelTesting.makeScenarioClasses()

        let names = CucumberTest.defaultTestSuite.tests.map(\.name)

        XCTAssertFalse(names.contains { $0.contains(title) }, "\(names)")
        XCTAssertTrue(names.contains { $0.contains("testGherkin") }, "\(names)")
    }

    func testCucumberTestHoldsTheScenariosOtherwise() {
        let title = parseFeature()

        let names = CucumberTest.defaultTestSuite.tests.map(\.name)

        XCTAssertEqual(names.filter { $0.contains(title) }.count, 2, "\(names)")
    }

    // A subclass, such as the one a StepImplementation's `bundle` uses, is a class XCTest hands to a
    // worker of its own. Only CucumberTest runs its checks, so that they run once.
    @MainActor
    func testASubclassOfCucumberTestHasNoTestsOnceTheScenarioClassesAreMade() throws {
        _ = parseFeature()
        ParallelTesting.makeScenarioClasses()
        // Made at run time, so that XCTest doesn't find it and run it as a test class.
        let name = "ParallelWorkerSubclass\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let subclass = try XCTUnwrap(objc_allocateClassPair(CucumberTest.self, name, 0) as? CucumberTest.Type)
        objc_registerClassPair(subclass)

        XCTAssertTrue(subclass.defaultTestSuite.tests.isEmpty)
        XCTAssertFalse(CucumberTest.defaultTestSuite.tests.isEmpty)
    }

    @MainActor
    func testPreparingDoesNothingUnlessTheFlagIsOn() {
        _ = parseFeature()

        ParallelTesting.prepare()

        XCTAssertFalse(ParallelTesting.scenarioClassesMade)
    }

    @MainActor
    func testPreparingMakesTheScenarioClassesWhenTheFlagIsOn() {
        let title = parseFeature()
        Cucumber.parallelTesting = true

        ParallelTesting.prepare()

        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
        XCTAssertNotNil(scenarioClass(title, "Pay by card"))
    }

    // A worker must have each scenario's class before XCTest lists or builds anything, with or without a
    // host app. Preparing later let a worker without one build CucumberTest's suite first and run every
    // scenario a second time (#371).
    func testPreparingWhenLoadedOnTheMainThreadMakesTheScenarioClassesAtOnce() {
        let title = parseFeature()
        Cucumber.parallelTesting = true

        ParallelTesting.prepareWhenLoaded()

        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
        XCTAssertNotNil(scenarioClass(title, "Pay by card"))
    }

    // A bundle loaded off the main thread prepares later, and XCTest may have built CucumberTest's suite,
    // scenarios and all, by then.
    @MainActor
    func testPreparingDoesNothingOnceXCTestHasBuiltTheSuite() {
        _ = parseFeature()
        Cucumber.parallelTesting = true
        _ = CucumberTest.defaultTestSuite

        ParallelTesting.prepare()

        XCTAssertFalse(ParallelTesting.scenarioClassesMade)
    }

    // With one test per scenario, every scenario is a test of one class, so a worker of its own can't be had.
    @MainActor
    func testPreparingDoesNothingWithOneTestPerScenario() {
        _ = parseFeature()
        Cucumber.parallelTesting = true
        Cucumber.oneTestPerScenario = true

        ParallelTesting.prepare()

        XCTAssertFalse(ParallelTesting.scenarioClassesMade)
    }

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

        let suite = CucumberTest.failureSuite(method: "ParallelTestingIsOff", message: ParallelWorkerObserver.message)

        XCTAssertTrue(ParallelWorkerObserver.isMissingSetting { true })
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
}
