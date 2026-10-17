//
//  StepDSL+Selector.swift
//  CucumberSwiftTesting
//
// CucumberSwift's step definitions with a regular expression in a string and a class and a selector to run.
// They are deprecated there too, in favour of regex literals. They need the Objective-C runtime.

#if canImport(ObjectiveC)
import Foundation
#if canImport(XCTest)
import XCTest
#endif

private func performSelector(_ selector: Selector, on type: NSObject.Type?) {
    guard let instance = type?.init(), instance.responds(to: selector) else { return }
    #if canImport(XCTest)
    let testCase = instance as? XCTestCase
    testCase?.setUp()
    defer { testCase?.tearDown() }
    #endif
    instance.perform(selector)
}

extension StepDSL {
    /// A step definition with a regular expression in a string that, for each step it matches, makes an
    /// instance of `class` with `init()` and calls `selector` on it, as CucumberSwift's does. An `XCTestCase`
    /// gets `setUp()` before and `tearDown()` after, before the step's `AfterStep` hooks. A class that isn't an
    /// `NSObject`, or an instance that doesn't respond to `selector`, does nothing. The expression matches as
    /// it does for the step definitions with a regular expression whose closure takes a `[String]`.
    @_disfavoredOverload
    @available(*, deprecated, message: "To use regular expressions with CucumberSwift please migrate to use regex literals.")
    @discardableResult
    public convenience init(_ regex: String,
                            class: AnyClass,
                            selector: Selector,
                            line: Int = #line,
                            file: StaticString = #file) {
        let type = `class` as? NSObject.Type
        self.init(regex, callback: { _, _ in performSelector(selector, on: type) }, line: line, file: file)
    }
}
#endif
