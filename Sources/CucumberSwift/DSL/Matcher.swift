//
//  Matcher.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation
import CucumberSwiftExpressions

public protocol Matcher {
    init(line: Int, file: StaticString)
    var keyword: Step.Keyword { get }
}

extension Matcher {
    @_disfavoredOverload
    @available(*, deprecated, message: "To use regular expressions with CucumberSwift please migrate to use regex literals.")
    @discardableResult public init(_ regex: String,
                                   class: AnyClass,
                                   selector: Selector,
                                   line: Int = #line,
                                   file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, regex: regex, class: `class`, selector: selector, line: line, file: file)
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "To use regular expressions with CucumberSwift please migrate to use regex literals.")
    @discardableResult public init(_ regex: String,
                                   callback: @escaping (([String], Step) throws -> Void),
                                   line: Int = #line,
                                   file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, regex: regex, callback: callback, line: line, file: file)
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "To use regular expressions with CucumberSwift please migrate to use regex literals.")
    @discardableResult public init(_ regex: String,
                                   callback: @escaping @MainActor ([String], Step) async throws -> Void,
                                   line: Int = #line,
                                   file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, regex: regex, asyncCallback: callback, line: line, file: file)
    }

    @discardableResult public init(_ expression: CucumberExpression,
                                   callback: @escaping ((CucumberSwiftExpressions.Match, Step) throws -> Void),
                                   line: Int = #line,
                                   file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, expression: expression, callback: callback, line: line, file: file)
    }

    /// An async step definition. It runs on the main actor, and the next step starts only once it has finished.
    @discardableResult public init(_ expression: CucumberExpression,
                                   callback: @escaping @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void,
                                   line: Int = #line,
                                   file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, expression: expression, asyncCallback: callback, line: line, file: file)
    }

#if compiler(>=5.7) && canImport(_StringProcessing)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @discardableResult public init<Output>(_ regex: Regex<Output>,
                                           callback: @escaping ((Regex<Output>.Match, Step) -> Void),
                                           line: Int = #line,
                                           file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, regex: regex, callback: callback, line: line, file: file)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @discardableResult public init<Output>(_ regex: Regex<Output>,
                                           callback: @escaping @MainActor (Regex<Output>.Match, Step) async throws -> Void,
                                           line: Int = #line,
                                           file: StaticString = #file) {
        self.init(line: line, file: file)
        Cucumber.shared.attachClosureToSteps(keyword: keyword, regex: regex, asyncCallback: callback, line: line, file: file)
    }
#endif
}
