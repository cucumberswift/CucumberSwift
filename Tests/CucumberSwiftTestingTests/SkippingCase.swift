//
//  SkippingCase.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Testing

/// The two cases of a test that runs scenario cases which skip, in this order. From Swift 6.3 a skipped case
/// calls `Test.cancel`, and so does a step that skips with it, which reports the test that called `run` as
/// cancelled rather than passed. So the `run` case runs them, where only that case is cancelled, and the
/// `check` case checks what it saw (#480).
enum SkippingCase: String, CaseIterable, Sendable, CustomTestStringConvertible {
    case run, check
    var testDescription: String { rawValue }
}

/// What each test's `run` case saw, until its `check` case takes it.
@MainActor
private var skippingCaseResults = [String: Any]()

extension CucumberTests {
    /// In the `run` case, calls `body` and keeps what it returns, then returns `nil`. In the `check` case,
    /// returns what the `run` case kept, and fails the test if it kept nothing, such as when it didn't run
    /// to the end, so that the test's expectations can't be left out unnoticed.
    func inSkippingCase<Result>(
        _ testCase: SkippingCase,
        test: String = #function,
        _ body: () async throws -> Result
    ) async throws -> Result? {
        switch testCase {
            case .run:
                skippingCaseResults[test] = try await body()
                return nil
            case .check:
                let result = skippingCaseResults.removeValue(forKey: test)
                return try #require(result as? Result, "The run case of \(test) didn't finish, so there is nothing to check.")
        }
    }
}
