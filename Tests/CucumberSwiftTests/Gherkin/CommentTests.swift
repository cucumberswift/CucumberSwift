//
//  CommentTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/16/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift
class CommentTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testInlineCommentsAreIgnored() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       Scenario: Some determinable business situation
         Given some precondition #Snarky Dev Comment
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        let steps = firstScenario?.steps
        XCTAssertEqual(steps?.first?.keyword, .given)
        XCTAssertEqual(steps?.first?.match, "some precondition")
    }

    func testCommentCharacterCanBeEscapedInline() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       Scenario: Some determinable business situation
         Given some color \\#ffffff
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        let steps = firstScenario?.steps
        XCTAssertEqual(steps?.first?.keyword, .given)
        XCTAssertEqual(steps?.first?.match, "some color #ffffff")
    }

    func testCommentedLinesAreIgnored() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
       Scenario: Some determinable business situation
         Given some precondition #Snarky Dev Comment
         #When something else happens
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        let steps = firstScenario?.steps
        XCTAssertEqual(steps?.first?.keyword, .given)
        XCTAssertEqual(steps?.first?.match, "some precondition")
        XCTAssertEqual(steps?.count, 1)
    }

    func testTrailingCommentEndsAtEndOfLine() {
        let cucumber = Cucumber(withString: """
    Feature: F
      Scenario: S
        Given I am logged in #switch to OAuth
        Then I see my name
    """)
        let steps = cucumber.features.first?.scenarios.first?.steps
        XCTAssertEqual(steps?.count, 2)
        XCTAssertEqual(steps?.first?.keyword, .given)
        XCTAssertEqual(steps?.first?.match, "I am logged in")
        XCTAssertEqual(steps?.last?.keyword, .then)
        XCTAssertEqual(steps?.last?.match, "I see my name")
        XCTAssert(Gherkin.errors.snapshot.isEmpty)
    }

    func testTrailingCommentsBeforeSeveralSteps() {
        let cucumber = Cucumber(withString: """
    Feature: F
      Scenario: S
        Given I order item #42 now
        And a # b
        Then done
        And the color is \\#123456
    """)
        let steps = cucumber.features.first?.scenarios.first?.steps
        XCTAssertEqual(steps?.map(\.keyword), [.given, [.and, .given], .then, [.and, .then]])
        XCTAssertEqual(steps?.map(\.match), ["I order item", "a", "done", "the color is #123456"])
        XCTAssert(Gherkin.errors.snapshot.isEmpty)
    }

    func testLanguageIsParsed() {
        let cucumber = Cucumber(withString: """
    #language:en

    Feature: Explicit language specification

      Scenario: minimalistic
        Given the minimalism
    """)
        XCTAssertEqual(cucumber.features.count, 1)
        XCTAssertEqual(cucumber.features.first?.title, "Explicit language specification")
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.title, "minimalistic")
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.first?.keyword, .given)
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.first?.match, "the minimalism")
        XCTAssertEqual(Scope.language.given, "Given")
    }

    func testEmojiLanguageIsParsed() {
        let cucumber = Cucumber(withString: """
    # language: em
    📚: 🙈🙉🙊

      📕: 💃
        😐🎸
    """)
        XCTAssertEqual(cucumber.features.count, 1)
        XCTAssertEqual(cucumber.features.first?.title, "🙈🙉🙊")
        XCTAssertEqual(cucumber.features.first?.scenarios.first?.title, "💃")
//        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.first?.keyword, .given)
//        XCTAssertEqual(cucumber.features.first?.scenarios.first?.steps.first?.match, "🎸")
        XCTAssertEqual(Scope.language.given, "😐")
    }

    // Build tools read a keyword in a language they give, rather than the lexer's current one (#324).
    func testAKeywordIsReadInTheCurrentLanguageOrTheLanguageItIsGiven() throws {
        defer { Scope.language = .default }
        Scope.language = try XCTUnwrap(Language("es"))
        XCTAssertEqual(Step.Keyword("Dado"), .given)
        XCTAssertNil(Step.Keyword("Given"))
        XCTAssertEqual(Step.Keyword("Given", in: .default), .given)
        XCTAssertNil(Step.Keyword("Dado", in: .default))
    }
}
