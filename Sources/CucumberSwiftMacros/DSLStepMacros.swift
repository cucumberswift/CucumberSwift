//
//  DSLStepMacros.swift
//  CucumberSwiftMacros
//
// swiftlint:disable file_length

// The steps of the Swift DSL, with their text captured when the tests compile: `#Given(I: logIn())` is
// `Given(I: logIn())` whose text, `I: logIn()`, is written into the macro's expansion rather than read from the
// Swift file when the tests run, which needs the file and so fails on a device or from an archived test bundle.
// The macros return the step types of the runner that Exports.swift re-exports. CucumberSwiftTestingMacros
// compiles this file too, through a symlink, for CucumberSwiftTesting's step types.

// `Handler` is a call, such as `logIn()`, an async function, such as `signIn`, or a closure: the expansion
// passes it on to the step type, which takes any of them, as `Given(I:)` does.
#if Macros

@freestanding(expression)
@discardableResult
public macro Given<Handler>(_ handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A `Given` step of a feature written in the Swift DSL, whose text is captured when it compiles.
///
/// ```swift
/// Feature("Sign in") {
///     Scenario("A returning user") {
///         #Given(I: haveAnAccount())
///         #When(I: signIn)
///         #Then(the: settingsAreShown())
///     }
/// }
/// ```
///
/// The step's text is the label and what follows it, as written: `I: haveAnAccount()`. It is the same as the
/// text `Given(I: haveAnAccount())` reads from the Swift file when the tests run, with each line break in a
/// call written over several lines read as a space. Use Expand Macro in Xcode to see the expansion.
@freestanding(expression)
@discardableResult
public macro Given<Handler>(I handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Given<Handler>(it handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Given<Handler>(my handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Given<Handler>(some handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Given<Handler>(a handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Given<Handler>(the handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(_ handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A `When` step of a feature written in the Swift DSL, whose text is captured when it compiles. See ``Given(I:)``.
@freestanding(expression)
@discardableResult
public macro When<Handler>(I handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(it handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(my handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(some handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(a handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro When<Handler>(the handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(_ handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A `Then` step of a feature written in the Swift DSL, whose text is captured when it compiles. See ``Given(I:)``.
@freestanding(expression)
@discardableResult
public macro Then<Handler>(I handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(it handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(my handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(some handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(a handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro Then<Handler>(the handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(_ handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A `And` step of a feature written in the Swift DSL, whose text is captured when it compiles. See ``Given(I:)``.
@freestanding(expression)
@discardableResult
public macro And<Handler>(I handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(it handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(my handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(some handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(a handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro And<Handler>(the handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(_ handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A `But` step of a feature written in the Swift DSL, whose text is captured when it compiles. See ``Given(I:)``.
@freestanding(expression)
@discardableResult
public macro But<Handler>(I handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(it handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(my handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(some handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(a handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro But<Handler>(the handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(_ handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

/// A step for any keyword of a feature written in the Swift DSL, whose text is captured when it compiles. See ``Given(I:)``.
@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(I handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(it handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(my handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(some handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(a handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
public macro MatchAll<Handler>(the handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

#else
// Without the Macros trait the macros are declared but unavailable, so that using one says what
// to turn on, rather than that no such macro exists.

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(_ handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(I handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(it handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(my handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(some handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(a handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Given<Handler>(the handler: Handler) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(_ handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(I handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(it handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(my handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(some handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(a handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro When<Handler>(the handler: Handler) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(_ handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(I handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(it handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(my handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(some handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(a handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Then<Handler>(the handler: Handler) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(_ handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(I handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(it handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(my handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(some handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(a handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro And<Handler>(the handler: Handler) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(_ handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(I handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(it handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(my handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(some handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(a handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro But<Handler>(the handler: Handler) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(_ handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(I handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(it handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(my handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(some handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(a handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MatchAll<Handler>(the handler: Handler) -> MatchAllStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLStepMacro")

#endif
