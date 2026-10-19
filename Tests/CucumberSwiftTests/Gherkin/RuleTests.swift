//
//  RuleTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 12/6/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

@testable import CucumberSwift

class RuleTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testSimpleRule() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some rule

    Rule: A
      The rule A description

      Example: Example A
        Given a

      Scenario: Scenario B
        Given b
    """)
        let firstScenario = Cucumber.shared.features.first?.scenarios.first
        XCTAssertEqual(firstScenario?.steps.count, 1)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.match, "a")

        let secondScenario = Cucumber.shared.features.first?.scenarios[safe: 1]
        XCTAssertEqual(secondScenario?.steps.count, 1)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.match, "b")
    }

    func testMultipleRules() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some rules

    Rule: A
      The rule A description

      Example: Example A
        Given a

    Rule: B
      The rule B description

      Example: Example B
        Given b
    """)
        let firstScenario = Cucumber.shared.features.first?.scenarios.first
        XCTAssertEqual(firstScenario?.steps.count, 1)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.match, "a")

        let secondScenario = Cucumber.shared.features.first?.scenarios[safe: 1]
        XCTAssertEqual(secondScenario?.steps.count, 1)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.match, "b")
    }

    func testRuleWithSeparateBackgroundSteps() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some rules

    Background:
      Given fb

    Rule: A
      The rule A description

      Background:
        Given ab

      Example: Example A
        Given a

    Rule: B
      The rule B description

      Example: Example B
        Given b
    """)
        let firstScenario = Cucumber.shared.features.first?.scenarios.first
        XCTAssertEqual(firstScenario?.steps.count, 3)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(firstScenario?.steps[safe: 0]?.match, "fb")
        XCTAssertEqual(firstScenario?.steps[safe: 1]?.keyword, .given)
        XCTAssertEqual(firstScenario?.steps[safe: 1]?.match, "ab")
        XCTAssertEqual(firstScenario?.steps[safe: 2]?.keyword, .given)
        XCTAssertEqual(firstScenario?.steps[safe: 2]?.match, "a")

        let secondScenario = Cucumber.shared.features.first?.scenarios[safe: 1]
        XCTAssertEqual(secondScenario?.steps.count, 2)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.keyword, .given)
        XCTAssertEqual(secondScenario?.steps[safe: 0]?.match, "fb")
        XCTAssertEqual(secondScenario?.steps[safe: 1]?.keyword, .given)
        XCTAssertEqual(secondScenario?.steps[safe: 1]?.match, "b")
    }

    // A Rule's Scenario Outline runs every example, after the feature's and the Rule's Backgrounds, and
    // every scenario in a Rule has the Rule's tags after the feature's and before its own (#468).
    let ruleWithAnOutline = """
    @feature
    Feature: Some rules

    Background:
      Given fb

    @rule
    Rule: A
      Background:
        Given ab

      @first
      Scenario: Scenario A
        Given a

      @outline
      Scenario Outline: Outline A
        Given I eat <n> cukes

        @small
        Examples:
          | n |
          | 1 |
          | 2 |

    Rule: B
      Scenario: Scenario B
        Given b
    """

    func testARulesScenarioOutlineRunsEveryExampleAfterBothBackgrounds() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(ruleWithAnOutline)
        var matches = [String]()
        MatchAll("^(.*)$") { _, step in matches.append(step.match) }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(matches, [
            "fb", "ab", "a",
            "fb", "ab", "I eat 1 cukes",
            "fb", "ab", "I eat 2 cukes",
            "fb", "b"
        ])
        XCTAssert(Gherkin.errors.snapshot.isEmpty, "\(Gherkin.errors.snapshot)")
    }

    func testARulesScenariosAndExamplesHaveItsTagsAfterTheFeatures() {
        let cucumber = Cucumber(withString: ruleWithAnOutline)
        let scenarios = cucumber.features.first?.scenarios
        XCTAssertEqual(scenarios?.map(\.title), ["Scenario A", "Outline A (n: 1)", "Outline A (n: 2)", "Scenario B"])
        XCTAssertEqual(scenarios?.map(\.tags), [
            ["feature", "rule", "first"],
            ["feature", "rule", "outline", "small"],
            ["feature", "rule", "outline", "small"],
            ["feature"]
        ])
        XCTAssert(Gherkin.errors.snapshot.isEmpty, "\(Gherkin.errors.snapshot)")
    }

    func testCucumberTagsSelectARulesScenariosByItsTag() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(ruleWithAnOutline)
        Cucumber.shared.environment["CUCUMBER_TAGS"] = "rule"
        defer { Cucumber.shared.environment["CUCUMBER_TAGS"] = nil }
        var matches = [String]()
        MatchAll("^(.*)$") { _, step in matches.append(step.match) }

        Cucumber.shared.executeFeatures()

        XCTAssertEqual(matches, [
            "fb", "ab", "a",
            "fb", "ab", "I eat 1 cukes",
            "fb", "ab", "I eat 2 cukes"
        ])
    }

    func testShouldRunWithSeesARulesTags() {
        var seen = [[String]]()
        Cucumber.shouldRunWith = { _, tags in
            seen.append(tags)
            return !tags.contains("rule")
        }
        defer { Cucumber.shouldRunWith = { _, _ in true } }
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(ruleWithAnOutline)
        var matches = [String]()
        MatchAll("^(.*)$") { _, step in matches.append(step.match) }

        Cucumber.shared.executeFeatures()

        XCTAssert(seen.contains(["feature", "rule", "outline", "small"]), "\(seen)")
        XCTAssertEqual(matches, ["fb", "b"])
    }

    func testARulesOutlineExamplesAreInTheJSONReportWithTheRulesTags() throws {
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(ruleWithAnOutline)
        MatchAll("^(.*)$") { _, _ in }
        reporter.testSuiteStarted(at: Date())

        Cucumber.shared.executeFeatures()

        let report = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        let elements = try XCTUnwrap(report.first?["elements"] as? [[AnyHashable: Any]])
        XCTAssertEqual(elements.map { $0["name"] as? String }, ["Scenario A", "Outline A (n: 1)", "Outline A (n: 2)", "Scenario B"])
        let tags = elements.map { ($0["tags"] as? [[AnyHashable: Any]])?.compactMap { $0["name"] as? String } }
        XCTAssertEqual(tags[1], ["feature", "rule", "outline", "small"])
        let steps = elements[2]["steps"] as? [[AnyHashable: Any]]
        XCTAssertEqual(steps?.compactMap { $0["name"] as? String }, ["fb", "ab", "I eat 2 cukes"])
    }
}
