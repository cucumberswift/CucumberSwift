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

    /// The failures counted while a test replaces `Cucumber.failureCounter`. A step definition whose `#require`
    /// failed raises it, as Swift Testing's issue does through XCTest's interop.
    private static let failures = Locked(0)

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

    func testAStepThatThrowsFails() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("XCTExpectFailure needs iOS 14") }
        XCTExpectFailure("The step throws") {
            Cucumber.failOnError(in: self) { throw StepError() }
        }
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

    // The step fails once: the failure Swift Testing recorded counts, and the error it then threw doesn't fail
    // this test.
    func testAStepWhoseRequireFailedIsNotFailedAgainForItsError() throws {
        let error = try requireError()
        var failures = 0
        let body = {
            failures += 1
            throw error
        }
        Cucumber.failOnError(failureCount: { failures }, file: #filePath, line: #line, body)
    }

    // Without XCTest's interop with Swift Testing nothing failed the step, so the error must.
    func testAFailedRequireFailsItsStepWhenNothingElseDid() throws {
        XCTAssertTrue(Cucumber.reportsError(try requireError(), afterFailure: false))
    }

    // MARK: executeFirstStep

    /// Defines a step whose `#require` failed and one that throws, in a feature that uses both.
    private func defineFailingSteps() throws {
        Cucumber.shared.reset()
        Cucumber.failureCounter.withLock { $0 = { _ in Self.failures.snapshot } }
        Self.failures.withLock { $0 = 0 }
        addTeardownBlock {
            Cucumber.shared.reset()
            Cucumber.failureCounter.withLock { $0 = { $0?.testRun?.totalFailureCount ?? 0 } }
        }
        Cucumber.shared.parseIntoFeatures("""
        Feature: Failing steps
           Scenario: Steps that fail
             When a requirement fails
             And a step throws
        """)
        let error = try requireError()
        When("a requirement fails") { _, _ in
            Self.failures.withLock { $0 += 1 }
            throw error
        }
        When("a step throws") { _, _ in throw StepError() }
    }

    func testExecuteFirstStepDoesNotFailAgainForAFailedRequire() throws {
        try defineFailingSteps()
        Cucumber.shared.executeFirstStep(matching: "a requirement fails")
        XCTAssertEqual(Self.failures.snapshot, 1)
    }

    @MainActor
    func testAsyncExecuteFirstStepDoesNotFailAgainForAFailedRequire() async throws {
        try defineFailingSteps()
        await Cucumber.shared.executeFirstStep(matching: "a requirement fails")
        XCTAssertEqual(Self.failures.snapshot, 1)
    }

    func testExecuteFirstStepFailsForAnError() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("XCTExpectFailure needs iOS 14") }
        try defineFailingSteps()
        XCTExpectFailure("The step throws") {
            Cucumber.shared.executeFirstStep(matching: "a step throws")
        }
    }

    @MainActor
    func testAsyncExecuteFirstStepFailsForAnError() async throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("XCTExpectFailure needs iOS 14") }
        try defineFailingSteps()
        XCTExpectFailure("The step throws")
        await Cucumber.shared.executeFirstStep(matching: "a step throws")
    }
    #endif
}
