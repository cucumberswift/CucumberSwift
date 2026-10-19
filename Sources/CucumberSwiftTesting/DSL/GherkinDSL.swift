//
//  GherkinDSL.swift
//  CucumberSwiftTesting
//
// The steps of a feature written in the Swift DSL, named and shaped as in CucumberSwift: `Given(I: logIn())`,
// `When(I: signIn)` for an async function, or `Then(the: { try await check() })` for a closure. The DSL step
// macros, such as `#Given(I: logIn())`, expand to the `_macroStep` form.

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

// A function's text is read from the Swift file when the tests run, from the opening parenthesis of the call
// on, as CucumberSwift reads it: `I: logIn()`. That needs the file, so the macros are the way to write a step
// for tests that run on a device.
extension StepDSL {
    @discardableResult public convenience init(_ handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(I handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(it handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(my handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(some handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(a handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }

    @discardableResult public convenience init(the handler: @escaping @autoclosure () -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file) { handler() }
    }
}

// Async steps take a closure or a function rather than an autoclosure, which cannot be async here:
// `Given(I: signIn)` or `Given(I: { try await signIn(as: .testUser) })`. A closure runs on the main actor;
// a function keeps its own isolation. The next step starts only once it has finished, and a thrown error
// fails the step.
extension StepDSL {
    @discardableResult public convenience init(_ handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(I handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(it handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(my handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(some handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(a handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }

    @discardableResult public convenience init(the handler: @escaping @MainActor () async throws -> Void,
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath) {
        self.init(dslText: DSLStepText.read(line: line, column: column, file: file), line: line, column: column, file: file, body: handler)
    }
}

// What the DSL step macros, such as `#Given(I: logIn())`, expand to: the step's text, line, column and file
// are written into the expansion when the tests compile, rather than read from the Swift file when they run.
// Write the macro rather than calling these.
extension StepDSL {
    @discardableResult public convenience init(_macroStep handler: @escaping @autoclosure () -> Void,
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
