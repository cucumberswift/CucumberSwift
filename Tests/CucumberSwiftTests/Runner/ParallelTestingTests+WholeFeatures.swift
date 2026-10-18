//
//  ParallelTestingTests+WholeFeatures.swift
//  CucumberSwiftTests
//
//  With whole features as the parallel testing unit, each feature gets a class of its own, whose tests
//  sort into the feature files' order. An extension of ParallelTestingTests, so that it shares its setup.
//

import Foundation
import XCTest
@testable import CucumberSwift

extension ParallelTestingTests {
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
