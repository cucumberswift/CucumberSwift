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

    @Test func aStepWhoseRequirementFailsRecordsOneIssue() async {
        Given("a requirement fails") { _, _ in try #require(1 == 2, "required on purpose") }
        var comments = [String]()
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a requirement fails", line: 3)]))
        } matching: { issue in
            comments.append(issue.comments.map(\.rawValue).joined())
            return true
        }
        #expect(comments.count == 1)
        #expect(comments.first?.contains("required on purpose") == true)
    }

    @available(*, deprecated) // runs ExecuteFirstStep on purpose
    @Test func aRequirementThatFailsInExecuteFirstStepRecordsOneIssue() async {
        Given("a basket") { _, _ in await ExecuteFirstStep(matching: "a requirement fails") }
        When("a requirement fails") { _, _ in try #require(1 == 2, "required on purpose") }
        var comments = [String]()
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        } matching: { issue in
            comments.append(issue.comments.map(\.rawValue).joined())
            return true
        }
        #expect(comments.count == 1)
        #expect(comments.first?.contains("required on purpose") == true)
    }
}
