//
//  DSLContainerMacros.swift
//  CucumberSwiftMacros
//

// The parts of a feature written in the Swift DSL, as macros, so that a feature can be written in the macro style
// throughout, with the DSL step macros in DSLStepMacros.swift:
//
//     #Feature("Checkout") {
//         #Scenario("Buy cukes") {
//             #When(I: addCukes(2))
//         }
//     }
//
// Each expands to the call it stands for, with the same arguments, and the position it is written at. The macros
// return the types of the runner that Exports.swift re-exports. CucumberSwiftTestingMacros compiles this file too,
// through a symlink, for CucumberSwiftTesting's types.
#if Macros

/// A feature written in the Swift DSL, in the macro style, with its contents' scenarios. It expands to `Feature(_:tags:line:column:file:_:)`
/// with its position written in when it compiles. See ``Given(I:)`` for its steps.
@freestanding(expression)
@discardableResult
public macro Feature(_ title: String,
                     tags: [String] = [],
                     @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Feature
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLFeatureMacro")

/// A scenario of a feature written in the Swift DSL, in the macro style.
@freestanding(expression)
@discardableResult
public macro Scenario(_ title: String,
                      description: String = "",
                      tags: [String] = [],
                      @StepBuilder _ content: () -> [StepDSL]) -> Scenario
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

/// A Scenario Outline of a feature written in the Swift DSL, in the macro style: a scenario for each of `examples`.
@freestanding(expression)
@discardableResult
public macro ScenarioOutline<T>(_ title: String,
                                tags: [String] = [],
                                description: String = "",
                                headers: T.Type,
                                @StepBuilder steps: (T) -> [StepDSL],
                                examples: () -> [T]) -> ScenarioOutline
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

/// A Scenario Outline whose title is made from each example, in the macro style.
@freestanding(expression)
@discardableResult
public macro ScenarioOutline<T>(_ title: (T) -> String,
                                tags: [String] = [],
                                description: String = "",
                                headers: T.Type,
                                @StepBuilder steps: (T) -> [StepDSL],
                                examples: () -> [T]) -> ScenarioOutline
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

/// Steps that run before each scenario of the feature or rule, in the macro style.
@freestanding(expression)
@discardableResult
public macro Background(@StepBuilder _ content: () -> [StepDSL]) -> Background
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLPartMacro")

/// A group of scenarios, in the macro style.
@freestanding(expression)
@discardableResult
public macro Rule(_ title: String,
                  tags: [String] = [],
                  @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Rule
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

/// The text under a feature's title, in the macro style.
@freestanding(expression)
@discardableResult
public macro Description(_ title: String) -> Description
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLPartMacro")

#else
// Without the Macros trait the macros are declared but unavailable, so that using one says what to turn on, rather
// than that no such macro exists.

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Feature(_ title: String,
                     tags: [String] = [],
                     @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Feature
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLFeatureMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Scenario(_ title: String,
                      description: String = "",
                      tags: [String] = [],
                      @StepBuilder _ content: () -> [StepDSL]) -> Scenario
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ScenarioOutline<T>(_ title: String,
                                tags: [String] = [],
                                description: String = "",
                                headers: T.Type,
                                @StepBuilder steps: (T) -> [StepDSL],
                                examples: () -> [T]) -> ScenarioOutline
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ScenarioOutline<T>(_ title: (T) -> String,
                                tags: [String] = [],
                                description: String = "",
                                headers: T.Type,
                                @StepBuilder steps: (T) -> [StepDSL],
                                examples: () -> [T]) -> ScenarioOutline
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Background(@StepBuilder _ content: () -> [StepDSL]) -> Background
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLPartMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Rule(_ title: String,
                  tags: [String] = [],
                  @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Rule
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLScenarioMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro Description(_ title: String) -> Description
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "DSLPartMacro")

#endif
