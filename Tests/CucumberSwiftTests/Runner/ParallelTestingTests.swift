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

    /// The class for the scenario at `position` of the only feature, which is the first: `F01 S02 › …`.
    private func scenarioClass(_ title: String, _ scenario: String, at position: Int = 1) -> XCTestCase.Type? {
        let prefix = CucumberTest.scenarioOrderPrefix(feature: 1, of: 1, scenario: position, of: 2, readable: true)
        return NSClassFromString(prefix + title + CucumberTest.readFeatureScenarioDelimiter() + scenario) as? XCTestCase.Type
    }

    @MainActor
    func testEachScenarioGetsAClassWhoseSuiteIsItsStepsInOrder() throws {
        let title = parseFeature()

        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        let giftCard = try XCTUnwrap(scenarioClass(title, "Pay with a gift card"))
        let names = giftCard.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(names.count, 2, "\(names)")
        XCTAssertTrue(names.first?.hasSuffix("1 \u{203A} Given a cart]") == true, "\(names)")
        XCTAssertTrue(names.last?.hasSuffix("2 \u{203A} When I pay with a gift card]") == true, "\(names)")
        XCTAssertEqual(try XCTUnwrap(scenarioClass(title, "Pay by card", at: 2)).defaultTestSuite.tests.count, 1)
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

        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        // Their positions make the names differ.
        func name(_ position: Int) -> String {
            CucumberTest.scenarioOrderPrefix(feature: 1, of: 1, scenario: position, of: 2, readable: true)
                + title + CucumberTest.readFeatureScenarioDelimiter() + "Pay by card"
        }
        let first = try XCTUnwrap(NSClassFromString(name(1)) as? XCTestCase.Type)
        let second = try XCTUnwrap(NSClassFromString(name(2)) as? XCTestCase.Type)
        XCTAssertEqual(first.defaultTestSuite.name, name(1))
        XCTAssertEqual(second.defaultTestSuite.name, name(2))
    }

    // XCTest groups test classes by their bundle. A class made at run time would otherwise be in the main
    // bundle, which in a test target hosted in an app is the app, and xcodebuild crashes on that.
    @MainActor
    func testEachScenarioClassIsInTheTestBundleAndOtherClassesAreNot() throws {
        let title = parseFeature()

        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        let testBundle = try XCTUnwrap((Cucumber.shared as? StepImplementation)?.bundle)
        XCTAssertEqual(Bundle(for: try XCTUnwrap(scenarioClass(title, "Pay by card", at: 2))), testBundle)
        XCTAssertEqual(Bundle(for: ParallelTestingTests.self), Bundle(for: CucumberSwiftTests.self))
        XCTAssertEqual(Bundle(for: CucumberTest.self), Bundle(for: Cucumber.self))
    }

    @MainActor
    func testCucumberTestLeavesTheScenariosOutOnceTheirClassesAreMade() {
        let title = parseFeature()
        Cucumber.parallelTesting = true
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
        Cucumber.parallelTesting = true
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
        XCTAssertNotNil(scenarioClass(title, "Pay by card", at: 2))
    }

    // A worker must have each scenario's class before XCTest lists or builds anything, with or without a
    // host app. Preparing later let a worker without one build CucumberTest's suite first and run every
    // scenario a second time (#371).
    func testPreparingWhenLoadedOnTheMainThreadMakesTheScenarioClassesAtOnce() {
        let title = parseFeature()
        Cucumber.parallelTesting = true

        ParallelTesting.prepareWhenLoaded()

        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
        XCTAssertNotNil(scenarioClass(title, "Pay by card", at: 2))
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

    // With one test per scenario, each scenario is a class of its own too, with one test named after the
    // scenario, so that Xcode can hand it to a worker (#388).
    @MainActor
    func testPreparingMakesAClassWithOneTestForEachScenarioWithOneTestPerScenario() throws {
        let title = parseFeature()
        Cucumber.parallelTesting = true
        Cucumber.oneTestPerScenario = true

        ParallelTesting.prepare()

        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
        let giftCard = try XCTUnwrap(scenarioClass(title, "Pay with a gift card", at: 1))
        let tests = giftCard.defaultTestSuite.tests
        XCTAssertEqual(tests.count, 1, "\(tests.map(\.name))")
        XCTAssertTrue(giftCard.isSubclass(of: try XCTUnwrap(CucumberTest.scenarioTestClass)))
        XCTAssertTrue(tests.first?.name.hasSuffix("Pay with a gift card]") == true, "\(tests.map(\.name))")
        XCTAssertEqual(try XCTUnwrap(scenarioClass(title, "Pay by card", at: 2)).defaultTestSuite.tests.count, 1)
    }

    @MainActor
    func testCucumberTestLeavesTheScenarioTestsOutOnceTheirClassesAreMadeWithOneTestPerScenario() {
        let title = parseFeature()
        Cucumber.parallelTesting = true
        Cucumber.oneTestPerScenario = true
        ParallelTesting.prepare()

        let names = CucumberTest.defaultTestSuite.tests.map(\.name)

        XCTAssertFalse(names.contains { $0.contains(title) }, "\(names)")
    }

    // XCTest lists the classes by name, so with one test per scenario the classes are made too late too when
    // CucumberTest's suite is built first.
    @MainActor
    func testPreparingTooLateIsReportedWithOneTestPerScenario() {
        _ = parseFeature()
        Cucumber.parallelTesting = true
        Cucumber.oneTestPerScenario = true
        _ = CucumberTest.defaultTestSuite

        ParallelTesting.prepare()

        XCTAssertTrue(ParallelTesting.classesMadeTooLate)
    }

    // The order of the files is the order of the names XCTest sorts as strings, at every width.
    func testPrefixesSortInTheOrderOfTheFeatureFiles() {
        for readable in [true, false] {
            for count in [3, 10, 12, 100, 101] {
                let names = (1...count).map {
                    CucumberTest.scenarioOrderPrefix(feature: 1, of: 1, scenario: $0, of: count, readable: readable)
                }
                XCTAssertEqual(names.sorted(), names, "\(count) scenarios, readable: \(readable)")
                XCTAssertEqual(Set(names.map(\.count)).count, 1, "one width for \(count) scenarios")
            }
        }
    }

    func testPrefixesAreAtLeastTwoDigitsWideAndWidenWithTheCounts() {
        XCTAssertEqual(CucumberTest.scenarioOrderPrefix(feature: 1, of: 3, scenario: 2, of: 4, readable: true), "F01 S02 \u{203A} ")
        XCTAssertEqual(CucumberTest.scenarioOrderPrefix(feature: 1, of: 3, scenario: 2, of: 4, readable: false), "F01_S02_")
        XCTAssertEqual(CucumberTest.scenarioOrderPrefix(feature: 7, of: 120, scenario: 99, of: 100, readable: true), "F007 S099 \u{203A} ")
    }

    // A scenario keeps its name whichever tags run, so the positions count the scenarios that are left out.
    @MainActor
    func testPositionsDoNotDependOnWhichScenariosRun() throws {
        let title = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(title)
           Scenario: Slow one
             Given a cart
           @quick
           Scenario: Quick one
             Given a cart
           @quick
           Scenario: Quick two
             Given a cart
        """)
        CucumberTest.featuresLoaded = true
        Cucumber.parallelTesting = true
        Cucumber.shared.environment["CUCUMBER_TAGS"] = "quick"
        addTeardownBlock { Cucumber.shared.environment["CUCUMBER_TAGS"] = nil }

        let prefixes = CucumberTest.scenariosToRun().map { "\($0.scenario.title): \($0.prefix)" }

        XCTAssertEqual(prefixes, ["Quick one: F01 S02 \u{203A} ", "Quick two: F01 S03 \u{203A} "])
    }

    // Without parallel testing the classes are named as they were.
    func testSerialRunsKeepTheirNames() {
        _ = parseFeature()

        XCTAssertEqual(CucumberTest.scenariosToRun().map(\.prefix), ["", ""])
    }

    // What XCTest does with the classes: sort them by name. The order must be the order of the files across
    // features too, and a scenario of a feature after the 9th must not sort before one of an earlier feature.
    @MainActor
    func testClassesSortedByNameAreInTheOrderOfTheFeatureFiles() {
        let features = (1...12).map { feature in
            "Feature: Zed \(feature) \(UUID().uuidString)\n"
                + (1...11).map { "   Scenario: B \($0)\n     Given a cart\n" }.joined()
        }
        features.forEach { Cucumber.shared.parseIntoFeatures($0) }
        CucumberTest.featuresLoaded = true
        Cucumber.parallelTesting = true

        let names = CucumberTest.scenarioSuites().map(\.name)

        XCTAssertEqual(names.count, 12 * 11)
        XCTAssertEqual(names.sorted(), names)
        XCTAssertEqual(Set(names).count, names.count)
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

        // The class's name starts with the feature's position in the files (#388).
        let className = "F01 \u{203A} \(first)"
        let featureClass = try XCTUnwrap(NSClassFromString(className) as? XCTestCase.Type)
        let names = featureClass.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(
            names,
            [
                "-[\(className) 1 \u{203A} Pay by card \u{203A} 1 \u{203A} Given a cart]",
                "-[\(className) 1 \u{203A} Pay by card \u{203A} 2 \u{203A} When I pay by card]",
                "-[\(className) 2 \u{203A} Pay with a gift card \u{203A} 1 \u{203A} Given a cart]",
                "-[\(className) 3 \u{203A} Pay by card \u{203A} 1 \u{203A} Given a cart]"
            ]
        )
        XCTAssertEqual(names, names.sorted())
        XCTAssertEqual(featureClass.defaultTestSuite.name, className)
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

        let className = "F01_" + CucumberTest.generatedTestName(title, readable: false)
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

        // Their positions in the files tell them apart (#388).
        XCTAssertEqual(try XCTUnwrap(NSClassFromString("F01 \u{203A} " + title) as? XCTestCase.Type).defaultTestSuite.tests.count, 1)
        XCTAssertEqual(try XCTUnwrap(NSClassFromString("F02 \u{203A} " + title) as? XCTestCase.Type).defaultTestSuite.name,
                       "F02 \u{203A} " + title)
    }

    // With whole features and one test per scenario, a feature's class is a subclass of
    // `CucumberScenarioTest` with a test for each scenario, in the feature file's order (#388).
    @MainActor
    func testWithWholeFeaturesAndOneTestPerScenarioEachFeatureGetsAClassWithATestForEachScenario() throws {
        let (first, _) = parseFeatures()
        Cucumber.parallelTestingUnit = .feature
        Cucumber.oneTestPerScenario = true

        ParallelTesting.makeScenarioClasses()

        let className = "F01 \u{203A} \(first)"
        let featureClass = try XCTUnwrap(NSClassFromString(className) as? XCTestCase.Type)
        XCTAssertTrue(featureClass.isSubclass(of: try XCTUnwrap(CucumberTest.scenarioTestClass)))
        let names = featureClass.defaultTestSuite.tests.map(\.name)
        XCTAssertEqual(
            names,
            [
                "-[\(className) 1 \u{203A} Pay by card]",
                "-[\(className) 2 \u{203A} Pay with a gift card]",
                "-[\(className) 3 \u{203A} Pay by card]"
            ]
        )
        XCTAssertEqual(names, names.sorted())
        XCTAssertTrue(ParallelTesting.scenarioClassesMade)
    }

    @MainActor
    func testWithWholeFeaturesTheFeatureClassesSortInTheFeatureFilesOrder() throws {
        // Titles that sort the other way round from the files' order.
        let titles = ["Zed \(UUID().uuidString)", "Alpha \(UUID().uuidString)"]
        titles.forEach {
            Cucumber.shared.parseIntoFeatures("Feature: \($0)\n   Scenario: Pay\n     Given a cart")
        }
        CucumberTest.featuresLoaded = true
        Cucumber.parallelTestingUnit = .feature

        let names = CucumberTest.featureSuites().map(\.suite.name)

        XCTAssertEqual(names, ["F01 \u{203A} \(titles[0])", "F02 \u{203A} \(titles[1])"])
        XCTAssertEqual(names, names.sorted())
    }
}
