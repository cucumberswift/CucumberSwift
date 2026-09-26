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
        Gherkin.errors.removeAll()
        defer { Gherkin.errors.removeAll() }

        let matches = "This is a test".matches(for: "^(.*? is a test$")

        XCTAssertEqual(matches.count, 0)
        XCTAssert(Gherkin.errors.contains { $0.contains("^(.*? is a test$") },
                  "A pattern that will not compile should be recorded as a Gherkin error, not printed")
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
