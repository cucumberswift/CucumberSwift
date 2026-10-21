//
//  GherkinDSL.swift
//  CucumberSwiftTesting
//
// The steps of a feature written in the Swift DSL, written with the DSL step macros, as with CucumberSwift:
// `#Given(I: logIn())`, `#When(I: signIn)` for an async function, or `#Then(the: { try await check() })` for a
// closure. The macros expand to the `_macroStep` form.

import Foundation

/// A step of a feature written in the Swift DSL: what it runs, and its text, which its name, the report and
/// the hooks use.
struct DSLStep {
    let keyword: Step.Keyword
    let text: String
    let line: Int
    let column: Int
    /// The Swift file the step is written in.
    let file: String
    let body: @MainActor () async throws -> Void
    /// Whether the step goes on after an issue, as `continueAfterFailure(_:)` sets it, or `nil` to follow
    /// ``StepImplementation/continueTestingAfterFailure``.
    var continuesAfterFailure: Bool?
}

// This runner has the DSL step macros, such as `#Given(I: logIn())`, which capture each step's text when the
// tests compile, and not CucumberSwift's step functions, such as `Given(I: logIn())`, which read it from the
// Swift file when the tests run, and so find nothing on a device or from an archived test bundle. Calling a
// function says to write the macro instead.
extension StepDSL {
    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(_: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(I _: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(it _: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(my _: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(some _: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(a _: Handler) { fatalError("unavailable") }

    @available(*, unavailable, message: "Write the DSL step macro, such as #Given(I: logIn()), from CucumberSwiftTestingMacros: this runner has no step functions.")
    public convenience init<Handler>(the _: Handler) { fatalError("unavailable") }
}

// What the DSL step macros, such as `#Given(I: logIn())`, expand to: the step's text, line, column and file
// are written into the expansion when the tests compile, rather than read from the Swift file when they run.
// Write the macro rather than calling these.
extension StepDSL {
    @discardableResult public convenience init(_macroStep handler: @escaping @autoclosure @MainActor () -> Void,
                                               stepText: String,
                                               line: UInt,
                                               column: UInt,
                                               file: StaticString) {
        self.init(dslText: stepText, line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(_macroStep handler: @escaping @MainActor () async throws -> Void,
                                               stepText: String,
                                               line: UInt,
                                               column: UInt,
                                               file: StaticString) {
        self.init(dslText: stepText, line: line, column: column, file: file, body: handler)
    }

    /// Whether this step of the Swift DSL goes on after a failed expectation: with `false`, an async step's
    /// task is cancelled at its first issue, whatever ``StepImplementation/continueTestingAfterFailure`` says.
    /// Either way, once a step has failed the rest of its scenario's steps don't run.
    public func continueAfterFailure(_ value: Bool) -> StepDSL {
        dslStep?.continuesAfterFailure = value
        return self
    }
}
