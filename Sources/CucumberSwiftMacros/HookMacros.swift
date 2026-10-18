//
//  HookMacros.swift
//  CucumberSwiftMacros
//

// The hook macros expand to the hooks of the runner that Exports.swift re-exports. CucumberSwiftTestingMacros
// compiles this file too, through a symlink, for CucumberSwiftTesting's hooks.

// Each hook has two declarations. The first gives the closure its argument's type, so `{ scenario in` and
// `{ _ in` type-check. The second takes any closure, so that one with the wrong arguments reaches the macro,
// which says what the hook passes, with a fix-it, rather than failing Swift's own type check first.
#if Macros
/// A `BeforeFeature` hook whose closure is checked when it compiles. It runs once before a feature's first scenario.
///
/// ```swift
/// #BeforeFeature(priority: 1) { feature in
///     …
/// }
/// ```
///
/// The closure takes the `Feature`, or no argument, and may be `async throws`. The macro expands to the hook
/// you would write by hand, with the same arguments, so it runs exactly as that does. Use Expand Macro in Xcode
/// to see it.
@freestanding(expression)
public macro BeforeFeature(priority: UInt? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           closure: (Feature) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro BeforeFeature<each Argument>(priority: UInt? = nil,
                                          file: StaticString = #filePath,
                                          line: UInt = #line,
                                          closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

/// An `AfterFeature` hook whose closure is checked when it compiles. It runs once after a feature's last scenario. See ``BeforeFeature(priority:file:line:closure:)``.
@freestanding(expression)
public macro AfterFeature(priority: UInt? = nil,
                          file: StaticString = #filePath,
                          line: UInt = #line,
                          closure: (Feature) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro AfterFeature<each Argument>(priority: UInt? = nil,
                                         file: StaticString = #filePath,
                                         line: UInt = #line,
                                         closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

/// A `BeforeScenario` hook whose closure is checked when it compiles. It runs before each scenario. See ``BeforeFeature(priority:file:line:closure:)``.
@freestanding(expression)
public macro BeforeScenario(priority: UInt? = nil,
                            file: StaticString = #filePath,
                            line: UInt = #line,
                            closure: (Scenario) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro BeforeScenario<each Argument>(priority: UInt? = nil,
                                           file: StaticString = #filePath,
                                           line: UInt = #line,
                                           closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

/// An `AfterScenario` hook whose closure is checked when it compiles. It runs after each scenario. See ``BeforeFeature(priority:file:line:closure:)``.
@freestanding(expression)
public macro AfterScenario(priority: UInt? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           closure: (Scenario) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro AfterScenario<each Argument>(priority: UInt? = nil,
                                          file: StaticString = #filePath,
                                          line: UInt = #line,
                                          closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

/// A `BeforeStep` hook whose closure is checked when it compiles. It runs before each step. See ``BeforeFeature(priority:file:line:closure:)``.
@freestanding(expression)
public macro BeforeStep(priority: UInt? = nil,
                        file: StaticString = #filePath,
                        line: UInt = #line,
                        closure: (Step) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro BeforeStep<each Argument>(priority: UInt? = nil,
                                       file: StaticString = #filePath,
                                       line: UInt = #line,
                                       closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

/// An `AfterStep` hook whose closure is checked when it compiles. It runs after each step. See ``BeforeFeature(priority:file:line:closure:)``.
@freestanding(expression)
public macro AfterStep(priority: UInt? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line,
                       closure: (Step) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
public macro AfterStep<each Argument>(priority: UInt? = nil,
                                      file: StaticString = #filePath,
                                      line: UInt = #line,
                                      closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")
#else
// Without the Macros trait the macros are declared but unavailable, so that using one says what
// to turn on, rather than that no such macro exists.
@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeFeature(priority: UInt? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           closure: (Feature) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeFeature<each Argument>(priority: UInt? = nil,
                                          file: StaticString = #filePath,
                                          line: UInt = #line,
                                          closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterFeature(priority: UInt? = nil,
                          file: StaticString = #filePath,
                          line: UInt = #line,
                          closure: (Feature) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterFeature<each Argument>(priority: UInt? = nil,
                                         file: StaticString = #filePath,
                                         line: UInt = #line,
                                         closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeScenario(priority: UInt? = nil,
                            file: StaticString = #filePath,
                            line: UInt = #line,
                            closure: (Scenario) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeScenario<each Argument>(priority: UInt? = nil,
                                           file: StaticString = #filePath,
                                           line: UInt = #line,
                                           closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterScenario(priority: UInt? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           closure: (Scenario) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterScenario<each Argument>(priority: UInt? = nil,
                                          file: StaticString = #filePath,
                                          line: UInt = #line,
                                          closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeStep(priority: UInt? = nil,
                        file: StaticString = #filePath,
                        line: UInt = #line,
                        closure: (Step) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BeforeStep<each Argument>(priority: UInt? = nil,
                                       file: StaticString = #filePath,
                                       line: UInt = #line,
                                       closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterStep(priority: UInt? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line,
                       closure: (Step) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")

@freestanding(expression)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the hook macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AfterStep<each Argument>(priority: UInt? = nil,
                                      file: StaticString = #filePath,
                                      line: UInt = #line,
                                      closure: (repeat each Argument) async throws -> Void)
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "HookMacro")
#endif
