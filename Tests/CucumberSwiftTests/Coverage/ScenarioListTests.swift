//
//  ScenarioListTests.swift
//  CucumberSwiftTests
//
// `CUCUMBER_SCENARIOS`, which the mutation-test tool sets so that a run tests only the scenarios that cover a mutant.

import XCTest
@testable import CucumberSwift

final class ScenarioListTests: XCTestCase {
    private let feature = """
    Feature: Basket
      Scenario: One
        Given a step
      Scenario: Two
        Given a step
      Scenario Outline: Three
        Given a <thing>
        Examples:
          | thing |
          | a     |
          | b     |
    """

    override func tearDown() {
        Cucumber.shared.reset()
        super.tearDown()
    }

    func testEveryScenarioRunsWithoutTheVariable() {
        XCTAssertTrue(ScenarioList.runs(feature: "file:///x/Basket.feature", line: 2, environment: [:]))
    }

    func testTheListNamesScenariosByTheirFeatureInTheBundleAndTheirLine() {
        let environment = ["CUCUMBER_SCENARIOS": "Features/Basket.feature:2,Features/Basket.feature:11"]
        let uri = "file:///Users/x/Tests.xctest/Features/Basket.feature"
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 2, environment: environment))
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 11, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 4, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: "file:///Users/x/Tests.xctest/Features/Other.feature", line: 2, environment: environment))
    }

    func testEmptyEntriesNameNoScenarioAndAnEntryIsNotTrimmed() {
        let uri = "file:///x/Tests.xctest/Features/Basket.feature"
        let environment = ["CUCUMBER_SCENARIOS": "Features/Basket.feature:2,,"]
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 2, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 3, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 2, environment: ["CUCUMBER_SCENARIOS": " Features/Basket.feature:2"]), "A space is part of the path")
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 2, environment: ["CUCUMBER_SCENARIOS": ",,"]), "Only empty entries: no scenario")
    }

    func testACommaOrPercentInAPathSurvivesTheListTheToolWrites() {
        // The tool writes `%2C` for a comma and `%25` for a percent sign, and the list is split at the commas that remain.
        let uri = "file:///x/Tests.xctest/Features/Basket, large 100%.feature"
        let environment = ["CUCUMBER_SCENARIOS": "Features/Basket%2C large 100%25.feature:2,Features/Other.feature:4"]
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 2, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 4, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: "file:///x/Tests.xctest/Features/Basket", line: 2, environment: environment), "Not split at the comma")
    }

    func testAnEntryIsReadAsWrittenSoLeadingWhitespaceInAPathCounts() {
        let uri = "file:///x/Tests.xctest/\t Basket.feature"
        let environment = ["CUCUMBER_SCENARIOS": "\t Basket.feature:2,Other.feature:3"]
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 2, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: "file:///x/Tests.xctest/Basket.feature", line: 2, environment: environment))
    }

    func testASwiftScenarioIsNamedByItsFileFromThePackagesFolderWhereverThePackageIs() {
        // Outside the mutation-test tool's copy, a Swift scenario's feature is its file's absolute path.
        let uri = "/Users/me/Shop/Tests/ShopTests/BasketFeature.swift"
        let environment = ["CUCUMBER_SCENARIOS": "Tests/ShopTests/BasketFeature.swift:12"]
        XCTAssertTrue(ScenarioList.runs(feature: uri, line: 12, environment: environment))
        XCTAssertFalse(ScenarioList.runs(feature: uri, line: 13, environment: environment))
        func runs(_ feature: String, _ entry: String) -> Bool {
            ScenarioList.runs(feature: feature, line: 12, environment: ["CUCUMBER_SCENARIOS": entry])
        }
        let other = "/Users/me/Shop/Tests/OtherTests/BasketFeature.swift"
        XCTAssertFalse(runs(other, "Tests/ShopTests/BasketFeature.swift:12"), "Another folder")
        XCTAssertFalse(runs("/Users/me/Shop/XTests/ShopTests/BasketFeature.swift", "ests/ShopTests/BasketFeature.swift:12"),
                       "A whole folder name")
        XCTAssertTrue(runs(uri, "BasketFeature.swift:12"), "The file name alone")
        XCTAssertFalse(runs("/x/OtherShopTests/BasketFeature.swift", "ShopTests/BasketFeature.swift:12"),
                       "Not the end of a folder's name")
        XCTAssertTrue(runs(uri, "\(uri):12"), "The absolute path, exactly")
        XCTAssertFalse(runs("file:///x/Tests.xctest/Tests/ShopTests/Basket.feature", "Basket.feature:12"),
                       "A feature file is read exactly")
    }

    func testAnAbsoluteEntryStillSelectsASwiftScenarioInTheMutationCopy() {
        let file = "/tmp/mutation-copy-42-a1b2c3d4/package/Tests/F.swift"
        XCTAssertTrue(ScenarioList.runs(feature: file, line: 12, environment: ["CUCUMBER_SCENARIOS": "\(file):12"]), "Absolute")
        XCTAssertTrue(ScenarioList.runs(feature: file, line: 12, environment: ["CUCUMBER_SCENARIOS": "Tests/F.swift:12"]), "Relative")
        XCTAssertFalse(ScenarioList.runs(feature: file, line: 13, environment: ["CUCUMBER_SCENARIOS": "\(file):12"]), "Other line")
    }

    func testAnEmptyListRunsNoScenario() {
        XCTAssertFalse(ScenarioList.runs(feature: "file:///x/Basket.feature", line: 2, environment: ["CUCUMBER_SCENARIOS": ""]))
    }

    func testTheScenariosAndExamplesThatTheListNamesAreTheOnesTheFeatureKeeps() {
        Cucumber.shared.reset()
        Cucumber.shared.parseIntoFeatures(feature, uri: "file:///x/Tests.xctest/Features/Basket.feature")
        let scenarios = Cucumber.shared.features.flatMap(\.scenarios)
        XCTAssertEqual(scenarios.map(\.title), ["One", "Two", "Three (thing: a)", "Three (thing: b)"])
        let lines = scenarios.map { Int($0.location.line) }
        XCTAssertEqual(Set(lines).count, 4, "Each example has a line of its own")
        let environment = ["CUCUMBER_SCENARIOS": "Features/Basket.feature:\(lines[1]),Features/Basket.feature:\(lines[3])"]
        let kept = scenarios.taggedElements(with: environment, askImplementor: false)
        XCTAssertEqual(kept.map { Int($0.location.line) }, [lines[1], lines[3]])
        XCTAssertEqual(scenarios.taggedElements(with: [:], askImplementor: false).count, 4)
    }

    func testTheListLeavesFeaturesAlone() {
        Cucumber.shared.reset()
        Cucumber.shared.parseIntoFeatures(feature, uri: "file:///x/Tests.xctest/Features/Basket.feature")
        XCTAssertEqual(Cucumber.shared.features.taggedElements(with: ["CUCUMBER_SCENARIOS": ""], askImplementor: false).count, 1)
    }
}
