//
//  StepDefinitionMacros.swift
//  CucumberSwiftMacros
//

// The macros return the step types of the runner that Exports.swift re-exports. CucumberSwiftTestingMacros
// compiles this file too, through a symlink, for CucumberSwiftTesting's step types.

// The pattern is a `String`, not a `StaticString`, so that an interpolated pattern or a variable
// reaches the macro, which reports that the pattern must be a string literal. A `StaticString`
// would fail Swift's own type check first, with an error that does not say why.
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
public macro Given<each Argument>(_ expression: String,
                                  _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `When` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro When<each Argument>(_ expression: String,
                                 _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `Then` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro Then<each Argument>(_ expression: String,
                                 _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// An `And` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro And<each Argument>(_ expression: String,
                                _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `But` step definition whose pattern and closure are checked when it compiles. See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro But<each Argument>(_ expression: String,
                                _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A step definition for any keyword whose pattern and closure are checked when it compiles.
/// See ``Given(_:_:)``.
@freestanding(expression)
@discardableResult
public macro MatchAll<each Argument>(_ expression: String,
                                     _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `Given` step definition with a regex literal, whose pattern and closure are checked when it compiles.
///
/// ```swift
/// #Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { (count: Substring, container: Substring) in
///     …
/// }
/// ```
///
/// The closure takes one argument per capture group, in order, and optionally the `Step` last. Each
/// argument's type is its capture's type in the regex's `Output`: `Substring`, or `Substring?` for a group
/// that may not take part in the match, such as `(\d+)?`. Regex literals need iOS 16, macOS 13 or tvOS 16.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro Given<Output, each Argument>(_ regex: Regex<Output>,
                                          _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `When` step definition with a regex literal, whose pattern and closure are checked when it compiles.
/// See `#Given` with a regex literal.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro When<Output, each Argument>(_ regex: Regex<Output>,
                                         _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `Then` step definition with a regex literal, whose pattern and closure are checked when it compiles.
/// See `#Given` with a regex literal.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro Then<Output, each Argument>(_ regex: Regex<Output>,
                                         _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// An `And` step definition with a regex literal, whose pattern and closure are checked when it compiles.
/// See `#Given` with a regex literal.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro And<Output, each Argument>(_ regex: Regex<Output>,
                                        _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A `But` step definition with a regex literal, whose pattern and closure are checked when it compiles.
/// See `#Given` with a regex literal.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro But<Output, each Argument>(_ regex: Regex<Output>,
                                        _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// A step definition for any keyword with a regex literal, whose pattern and closure are checked when it
/// compiles. See `#Given` with a regex literal.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MatchAll<Output, each Argument>(_ regex: Regex<Output>,
                                             _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#else
// Without the Macros trait the macros are declared but unavailable, so that using one says what
// to turn on, rather than that no such macro exists.
@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<each Argument>(_ expression: String,
                   _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<each Argument>(_ expression: String,
                  _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<each Argument>(_ expression: String,
                  _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<each Argument>(_ expression: String,
                 _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<each Argument>(_ expression: String,
                 _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<each Argument>(_ expression: String,
                      _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Output, each Argument>(_ regex: Regex<Output>,
                   _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Output, each Argument>(_ regex: Regex<Output>,
                  _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Output, each Argument>(_ regex: Regex<Output>,
                  _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Output, each Argument>(_ regex: Regex<Output>,
                 _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Output, each Argument>(_ regex: Regex<Output>,
                 _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Output, each Argument>(_ regex: Regex<Output>,
                      _ body: (repeat each Argument) async throws -> Void) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#endif
