//
//  TagTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/16/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

class TagTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    let featureFileWithTags: String =
    """
    @featuretag
    Feature: Some terse yet descriptive text of what is desired

       @scenario1tag
       Scenario: Some determinable business situation
         Given a scenario with tags

       Scenario: Some other determinable business situation
         Given a scenario without tags

    """

    func testCommentAfterTagIsIgnored() {
        let cucumber = Cucumber(withString: """
        Feature: Test functionality
          @Disable # TODO: comment
          Scenario: Test scenario
            Given Do smth
        """)
        let scenario = cucumber.features.first?.scenarios.first
        XCTAssertEqual(scenario?.tags, ["Disable"])
        XCTAssertEqual(scenario?.steps.map(\.match), ["Do smth"])
        XCTAssert(Gherkin.errors.snapshot.isEmpty)
    }

    func testTagsAreScopedAndInheritedCorrectly() {
        let cucumber = Cucumber(withString: featureFileWithTags)
        XCTAssert(cucumber.features.first?.containsTag("featuretag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("featuretag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1tag") ?? false)
        XCTAssert(!(cucumber.features.first?.scenarios.last?.containsTag("scenario1tag") ?? true))
    }

    func testTagedWorkForScenarioOutlines() {
        let cucumber = Cucumber(withString: """
    @scenario1tag
    Feature: Some terse yet descriptive text of what is desired
        @someOtherTag
       Scenario Outline: Some determinable business situation
         Given a <thing> with tags

        Examples:
        |  thing   |
        | scenario |
    """)
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.first?.match, "a scenario with tags")
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1tag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("someOtherTag") ?? false)
    }

    func testMultipleTagsSpaceSeparated() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       @scenario1tag @someOtherTag
       Scenario: Some determinable business situation
         Given a scenario with tags
    """)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1tag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("someOtherTag") ?? false)
    }

    func testMultipleTagsNotSeparated() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       @scenario1tag@someOtherTag
       Scenario: Some determinable business situation
         Given a scenario with tags
    """)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1tag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("someOtherTag") ?? false)
    }

    func testTagsWithColon() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       @scenario1:tag
       Scenario: Some determinable business situation
         Given a scenario with tags
    """)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1:tag") ?? false)

        XCTAssertEqual(cucumber.features.first?.scenarios.first?.tags.first, "scenario1:tag")
    }

    func testMultipleTagsCommaSeparated() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       @scenario1tag, @someOtherTag
       Scenario: Some determinable business situation
         Given a scenario with tags
    """)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("scenario1tag") ?? false)
        XCTAssert(cucumber.features.first?.scenarios.first?.containsTag("someOtherTag") ?? false)
    }

    func testLegacyRunWithSpecificTags() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(featureFileWithTags)
        Cucumber.shared.environment["CUCUMBER_TAGS"] = "scenario1tag"

        var withTagsCalled = false
        Given("a scenario with tags") { _, _ in
            withTagsCalled = true
        }
        var withoutTagsCalled = false
        Given("a scenario without tags") { _, _ in
            withoutTagsCalled = true
        }

        Cucumber.shared.executeFeatures()

        XCTAssert(withTagsCalled)
        XCTAssertFalse(withoutTagsCalled)
        Cucumber.shared.environment["CUCUMBER_TAGS"] = nil
    }

    func testRunWithSpecificTags() {
        Cucumber.shouldRunWith = { _, tags in
            tags.contains("scenario1tag")
        }
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(featureFileWithTags)
        Cucumber.shared.environment["CUCUMBER_TAGS"] = nil

        var withTagsCalled = false
        Given("a scenario with tags") { _, _ in
            withTagsCalled = true
        }
        var withoutTagsCalled = false
        Given("a scenario without tags") { _, _ in
            withoutTagsCalled = true
        }

        Cucumber.shared.executeFeatures()

        XCTAssert(withTagsCalled)
        XCTAssertFalse(withoutTagsCalled)
        Cucumber.shouldRunWith = { _, _ in true }
    }

    func testTagOnExamples() {
        Cucumber.shouldRunWith = { _, tags in
            tags.contains("exampleTag")
        }
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        @scenario1tag
        Feature: Some terse yet descriptive text of what is desired
            @someOtherTag
           Scenario Outline: Some determinable business situation
             Given a <thing> with tags

            @exampleTag
            Examples:
            |  thing   |
            | scenario |
        """)
        Cucumber.shared.environment["CUCUMBER_TAGS"] = nil

        var stepCalled = false
        Given("a scenario with tags") { _, _ in
            stepCalled = true
        }

        Cucumber.shared.executeFeatures()

        XCTAssert(stepCalled)

        Cucumber.shouldRunWith = { _, _ in true }
    }

    func testAtSignInStepTextIsText() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given a @MainActor function step 1
             And the @delimits tags
             When I type "test@example.com"
             Then I email support@example.com
        """, uri: "at_sign_in_step.feature")
        let scenario = Cucumber.shared.features.first?.scenarios.first
        XCTAssertEqual(scenario?.steps.map(\.match), [
            "a @MainActor function step 1",
            "the @delimits tags",
            "I type \"test@example.com\"",
            "I email support@example.com"
        ])
        XCTAssertEqual(scenario?.tags, [])
        XCTAssert(Gherkin.errors.isEmpty, "\(Gherkin.errors)")
    }

    func testAtSignInTitlesAndDescriptionsIsText() {
        let cucumber = Cucumber(withString: """
        Feature: Mail to support@example.com
          Replies come from noreply@example.com

           Scenario: Reply to @someone
             Given a scenario
        """)
        let feature = cucumber.features.first
        XCTAssertEqual(feature?.title, "Mail to support@example.com")
        XCTAssertEqual(feature?.desc.trimmingCharacters(in: .whitespacesAndNewlines), "Replies come from noreply@example.com")
        XCTAssertEqual(feature?.tags, [])
        XCTAssertEqual(feature?.scenarios.first?.title, "Reply to @someone")
        XCTAssertEqual(feature?.scenarios.first?.tags, [])
        XCTAssertEqual(feature?.scenarios.first?.steps.map(\.match), ["a scenario"])
        XCTAssert(Gherkin.errors.isEmpty, "\(Gherkin.errors)")
    }

    func testTagLinesStillParseAlongsideAtSignInStepText() {
        let cucumber = Cucumber(withString: """
        @feature_tag1 @feature_tag2
          @feature_tag3
        Feature: Minimal Scenario Outline

        @scenario_tag1
        Scenario: minimalistic
            Given the minimalism

        @joined_tag3@joined_tag4
        Scenario: joined tags
          Given the @delimits tags
        """)
        let feature = cucumber.features.first
        XCTAssertEqual(feature?.tags, ["feature_tag1", "feature_tag2", "feature_tag3"])
        XCTAssertEqual(feature?.scenarios.first?.tags, ["feature_tag1", "feature_tag2", "feature_tag3", "scenario_tag1"])
        XCTAssertEqual(feature?.scenarios.last?.tags, ["feature_tag1", "feature_tag2", "feature_tag3", "joined_tag3", "joined_tag4"])
        XCTAssertEqual(feature?.scenarios.last?.steps.map(\.match), ["the @delimits tags"])
        XCTAssert(Gherkin.errors.isEmpty, "\(Gherkin.errors)")
    }

    func testEscapedAtSignInStepTextStillWorks() {
        let cucumber = Cucumber(withString: #"""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             When I type "test\@surglogs.com"
        """#)
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.map(\.match), ["I type \"test@surglogs.com\""])
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.tags, [])
        XCTAssert(Gherkin.errors.isEmpty, "\(Gherkin.errors)")
    }
}
