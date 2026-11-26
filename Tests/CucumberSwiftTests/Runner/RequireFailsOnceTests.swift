//
//  RequireFailsOnceTests.swift
//  CucumberSwiftTests
//
//  A failed `try #require` in a step fails its test once, as a failed `#expect` does, and any other error a
//  step throws still fails it (#562). BrokenFeaturesPackage's expected-failures checks a whole run.
//
import Foundation
#if canImport(Testing)
import Testing
#endif
import XCTest
@testable import CucumberSwift

class RequireFailsOnceTests: XCTestCase {
    private struct StepError: Error {}

    func testAnErrorIsNotAlreadyRecordedUnlessSwiftTestingThrewIt() {
        XCTAssertFalse(Cucumber.isAlreadyRecorded(StepError()))
    }

    func testAnErrorFailsItsStepEvenAfterAnotherFailure() {
        XCTAssertTrue(Cucumber.reportsError(StepError(), afterFailure: false))
        XCTAssertTrue(Cucumber.reportsError(StepError(), afterFailure: true))
    }

    func testAStepThatDoesNotThrowDoesNotFail() {
        Cucumber.failOnError(in: self) {}
    }

    #if canImport(Testing)
    /// What a failed `try #require` throws. Its failure is expected, and isn't recorded at all where XCTest
    /// has no interop with Swift Testing, as on Xcode 16.
    private func requireError() throws -> any Error {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("XCTExpectFailure needs iOS 14") }
        var thrown: (any Error)?
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("require fails on purpose", options: options) {
            do {
                try #require(1 == 2, "require failed on purpose")
            } catch {
                thrown = error
            }
        }
        return try XCTUnwrap(thrown)
    }

    func testTheErrorAFailedRequireThrowsIsAlreadyRecorded() throws {
        XCTAssertTrue(Cucumber.isAlreadyRecorded(try requireError()))
    }

    func testAFailedRequireDoesNotFailItsStepAgain() throws {
        XCTAssertFalse(Cucumber.reportsError(try requireError(), afterFailure: true))
    }

    // Without XCTest's interop with Swift Testing nothing failed the step, so the error must.
    func testAFailedRequireFailsItsStepWhenNothingElseDid() throws {
        XCTAssertTrue(Cucumber.reportsError(try requireError(), afterFailure: false))
    }
    #endif
}
