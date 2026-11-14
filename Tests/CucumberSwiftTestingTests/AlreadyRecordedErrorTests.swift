//
//  AlreadyRecordedErrorTests.swift
//  CucumberSwiftTestingTests
//
// A failed `try #require` records its issue and then throws `ExpectationFailedError`. The runner must not
// record that error again (#564), or the step reports the failure twice.

@testable import CucumberSwiftTesting
import Foundation
import Testing

extension CucumberTests {
    @Test func aThrownExpectationFailedErrorIsAlreadyRecorded() {
        var thrown: (any Error)?
        withKnownIssue {
            do {
                let value: Int? = nil
                _ = try #require(value)
            } catch {
                thrown = error
                throw error
            }
        }
        #expect(thrown != nil)
        #expect(thrown.map(Cucumber.isAlreadyRecorded) == true)
    }

    @Test func anyOtherErrorIsNotAlreadyRecorded() {
        struct Failure: Error {}
        struct ExpectationFailedError: Error {}
        #expect(!Cucumber.isAlreadyRecorded(Failure()))
        #expect(!Cucumber.isAlreadyRecorded(CancellationError()))
        #expect(!Cucumber.isAlreadyRecorded(ExpectationFailedError()))
    }
}
