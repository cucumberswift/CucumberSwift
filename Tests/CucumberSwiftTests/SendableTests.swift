//
//  SendableTests.swift
//  CucumberSwiftTests
//
//  The value types a consumer may pass between actors are `Sendable` (#243). These tests fail to
//  compile if one stops being `Sendable`.
//

import Foundation
import XCTest

@testable import CucumberSwift

private func sendable<T: Sendable>(_ value: T) -> T {
    value
}

final class SendableTests: XCTestCase {
    func testStepKeywordIsSendable() {
        XCTAssertEqual(sendable(Step.Keyword.given), .given)
    }

    func testReporterResultIsSendable() {
        XCTAssertEqual(sendable(Reporter.Result.failed("reason")), .failed("reason"))
    }

    func testLexerPositionIsSendable() {
        XCTAssertEqual(sendable(Lexer.Position(line: 1, column: 2)), Lexer.Position(line: 1, column: 2))
    }
}
