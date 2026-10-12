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
        Cucumber.parallelTestingUnit = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.readableTestNames = nil
        Cucumber.shared.reset()
        CucumberTest.resetSetUp()
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

    // MARK: Whole features

    /// Parses two features, the first with two scenarios of the same title, and returns their titles.
    private func parseFeatures() -> (first: String, second: String) {
        let first = "Parallel \(UUID().uuidString)"
        let second = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(first)
           Scenario: Pay by card
             Given a cart
             When I pay by card
           Scenario: Pay with a gift card
             Given a cart
           Scenario: Pay by card
             Given a cart
        """)
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(second)
           Scenario: Sign in
             Given a cart
        """)
        CucumberTest.featuresLoaded = true
        return (first, second)
    }

    // Xcode runs a class's tests sorted by name, so the names sort into the feature file's order, and a
    // result bundle names a test by its class and method, so two scenarios with the same title stay apart.
    @MainActor
    func testWithWholeFeaturesEachFeatureGetsAClassWhoseTestsSortIntoTheFeatureFilesOrder() throws {
        let (first, _) = parseFeatures()
        Cucumber.parallelTestingUnit = .feature

        ParallelTesting.makeScenarioClasses()

        let featureClass = try XCTUnwrap(NSClassFromString(first) as? XCTestCase.Type)
        let names = featureClass.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(
            names,
            [
                "-[\(first) 1 \u{203A} Pay by card \u{203A} 1 \u{203A} Given a cart]",
                "-[\(first) 1 \u{203A} Pay by card \u{203A} 2 \u{203A} When I pay by card]",
                "-[\(first) 2 \u{203A} Pay with a gift card \u{203A} 1 \u{203A} Given a cart]",
                "-[\(first) 3 \u{203A} Pay by card \u{203A} 1 \u{203A} Given a cart]"
            ]
        )
        XCTAssertEqual(names, names.sorted())
        XCTAssertEqual(featureClass.defaultTestSuite.name, first)
        XCTAssertNil(scenarioClass(first, "Pay with a gift card"))
        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
    }

    @MainActor
    func testWithWholeFeaturesAndCamelCaseNamesTheTestsSortIntoTheFeatureFilesOrder() throws {
        Cucumber.readableTestNames = false
        let title = "Parallel\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(title)
        \((1...10).map { "   Scenario: Pay \($0)\n     Given a cart" }.joined(separator: "\n"))
        """)
        CucumberTest.featuresLoaded = true
        Cucumber.parallelTestingUnit = .feature

        ParallelTesting.makeScenarioClasses()

        let className = CucumberTest.generatedTestName(title, readable: false)
        let featureClass = try XCTUnwrap(NSClassFromString(className) as? XCTestCase.Type)
        let names = featureClass.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(names.count, 10)
        XCTAssertEqual(names.first, "-[\(className) Scenario01_Pay1_Step000_GivenACart]")
        XCTAssertEqual(names.last, "-[\(className) Scenario10_Pay10_Step000_GivenACart]")
        XCTAssertEqual(names, names.sorted())
    }

    @MainActor
    func testWithWholeFeaturesTwoFeaturesWithTheSameTitleGetClassesWithDifferentNames() throws {
        let title = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("Feature: \(title)\n   Scenario: Pay\n     Given a cart")
        Cucumber.shared.parseIntoFeatures("Feature: \(title)\n   Scenario: Pay\n     Given a cart")
        CucumberTest.featuresLoaded = true
        Cucumber.parallelTestingUnit = .feature

        ParallelTesting.makeScenarioClasses()

        XCTAssertEqual(try XCTUnwrap(NSClassFromString(title) as? XCTestCase.Type).defaultTestSuite.tests.count, 1)
        XCTAssertEqual(try XCTUnwrap(NSClassFromString(title + " 2") as? XCTestCase.Type).defaultTestSuite.name, title + " 2")
    }
}
