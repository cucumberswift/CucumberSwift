//
//  StepDefinitionMacros.swift
//  CucumberSwiftMacros
//

// The expansions use CucumberSwift's step types and CucumberSwiftExpressions' `CucumberExpression` and
// `Match`, so importing this module is enough to use the macros.
@_exported import CucumberSwift
@_exported import CucumberSwiftExpressions

#if Macros
/// A `Given` step definition whose pattern and closure are checked when it compiles.
///
/// ```swift
/// #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
///     …
/// }
/// ```
///
/// The closure takes one argument per parameter in the expression, or per capture group in an anchored
/// or `/…/` regular expression, in order, and optionally the `Step` last. Each argument needs its type:
/// `Int` for `{int}`, `Float` for `{float}`, `Double` for `{double}`, `String` for `{string}`, `{word}`,
/// `{}` and a capture group, and the parameter's output type for a custom parameter. The macro expands
/// to the step definition you would write by hand; use Expand Macro in Xcode to see it.
@freestanding(expression)
@discardableResult
public macro Given<each Argument>(_ expression: StaticString,
                                  _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `When` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro When<each Argument>(_ expression: StaticString,
                                 _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `Then` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro Then<each Argument>(_ expression: StaticString,
                                 _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// An `And` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro And<each Argument>(_ expression: StaticString,
                                _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `But` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro But<each Argument>(_ expression: StaticString,
                                _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A step definition for any keyword whose pattern and closure are checked when it compiles.
/// See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro MatchAll<each Argument>(_ expression: StaticString,
                                     _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#else
// Without the Macros trait the macros are declared but unavailable, so that using one says what
// to turn on, rather than that no such macro exists.
@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<each Argument>(_ expression: StaticString,
                   _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<each Argument>(_ expression: StaticString,
                  _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<each Argument>(_ expression: StaticString,
                  _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<each Argument>(_ expression: StaticString,
                 _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<each Argument>(_ expression: StaticString,
                 _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<each Argument>(_ expression: StaticString,
                      _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#endif
