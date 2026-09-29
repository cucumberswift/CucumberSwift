//
//  StringExtensionsTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 4/8/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

class StringExtensionsTests: XCTestCase {
    func testMatchesReturnsCorrectMatchesForRegex() {
        let matches = "This is a test".matches(for: "^(.*?) is a test$")
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches.first, "This is a test")
        XCTAssertEqual(matches.last, "This")
    }

    func testMatchesReturnsAnEmptyArrayForInvalidRegex() {
        let initialGherkinErrors = Gherkin.errors
        let initialErrors = RegularExpression.errors
        defer {
            Gherkin.errors = initialGherkinErrors
            RegularExpression.errors = initialErrors
        }

        let matches = "This is a test".matches(for: "^(.*? is a test$")

        XCTAssertEqual(matches.count, 0)
        XCTAssert(RegularExpression.errors.dropFirst(initialErrors.count).contains { $0.message.contains("^(.*? is a test$") },
                  "A pattern that will not compile should be recorded as a regular expression error, not printed")
        XCTAssertEqual(Gherkin.errors,
                       initialGherkinErrors,
                       "A pattern that will not compile is not a problem in a .feature file, so it is not a Gherkin error")
    }

    func testAPatternOnlySwiftAcceptsFallsBackToFoundationsMessage() throws {
        // NSRegularExpression rejects an omitted lower bound; Swift's parser accepts it, so it cannot
        // say what is wrong, and the message falls back to Foundation's.
        XCTAssertFalse(RegularExpression.validate("^a{,3}$", file: "StepDefinitions.swift", line: 1))
        let problem = try XCTUnwrap(RegularExpression.errors.last)
        RegularExpression.errors.removeLast()

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *), (try? Regex("^a{,3}$")) == nil {
            throw XCTSkip("This platform's Swift regular expression parser rejects the pattern too")
        }
        XCTAssert(problem.message.hasPrefix("Invalid regular expression '^a{,3}$': The value"), problem.message)
    }

    func testMatchesReturnsAnEmptyArrayForNonMatchingRegex() {
        let matches = "This is a test".matches(for: "^xc7qqv....$")
        XCTAssertEqual(matches.count, 0)
    }

    func testCapitalizingFirstLetter() {
        XCTAssertEqual("test".capitalizingFirstLetter(), "Test")
    }

    func testLowercasingFirstLetter() {
        XCTAssertEqual("Test".lowercasingFirstLetter(), "test")
    }

    func testCamelCaseFromSpaces() {
        XCTAssertEqual("test one".camelCasingString(), "testOne")
    }

    func testCamelCaseFromNonAlphanumericCharacters() {
        XCTAssertEqual("test-two".camelCasingString(), "testTwo")
    }

    func testInitWithStaticString() {
        let ss: StaticString = "someValue"
        XCTAssertEqual(String(ss), "someValue")
    }
}
