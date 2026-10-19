//
//  GherkinDSL.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//
// swiftlint:disable file_types_order

import Foundation
import XCTest

public protocol GherkinDSL {
    init(line: Int, file: StaticString)
    @discardableResult init(line: UInt, column: UInt, match: String?, handler: @escaping () -> Void, file: StaticString)
}

extension GherkinDSL {
    @discardableResult public init(_ handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(I handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(it handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(my handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(some handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(a handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }

    @discardableResult public init(the handler: @escaping @autoclosure () -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  handler: handler,
                  file: file)
    }
}

// Async steps take a closure or a function rather than an autoclosure, which cannot be async here:
// `Given(I: signIn)` or `Given(I: { try await signIn(as: .testUser) })`. A closure runs on the main actor;
// a function keeps its own isolation, so mark it `@MainActor` if it needs the main actor. The next step
// starts only once it has finished, and a thrown error fails the step.
extension GherkinDSL {
    @discardableResult public init(_ handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(I handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(it handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(my handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(some handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(a handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    @discardableResult public init(the handler: @escaping @MainActor () async throws -> Void,
                                   line: UInt = #line,
                                   column: UInt = #column,
                                   file: StaticString = #file,
                                   function _: StaticString = #function) {
        self.init(line: line,
                  column: column,
                  match: DSLStepText.read(line: line, column: column, file: file),
                  asyncHandler: handler,
                  file: file)
    }

    private init(line: UInt, column: UInt, match: String?, asyncHandler: @escaping AsyncStepRunner.Body, file: StaticString) {
        self.init(line: line,
                  column: column,
                  match: match,
                  handler: { AsyncStepRunner.runFailingOnError(asyncHandler, file: file, line: line) },
                  file: file)
    }
}

// What the DSL step macros, such as `#Given(I: logIn())`, expand to: the step's text, line, column and file
// are written into the expansion when the tests compile, rather than read from the Swift file when they run.
// Write the macro rather than calling these.
extension GherkinDSL {
    @discardableResult public init(_macroStep handler: @escaping @autoclosure () -> Void,
                                   stepText: String,
                                   line: UInt,
                                   column: UInt,
                                   file: StaticString) {
        self.init(line: line, column: column, match: stepText, handler: handler, file: file)
    }

    @discardableResult public init(_macroStep handler: @escaping @MainActor () async throws -> Void,
                                   stepText: String,
                                   line: UInt,
                                   column: UInt,
                                   file: StaticString) {
        self.init(line: line, column: column, match: stepText, asyncHandler: handler, file: file)
    }
}
