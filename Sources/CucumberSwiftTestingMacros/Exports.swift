//
//  Exports.swift
//  CucumberSwiftTestingMacros
//
// The step definition and hook macros of CucumberSwiftMacros, for the Swift Testing runner. StepDefinitionMacros.swift,
// HookMacros.swift and LocalizedStepDefinitionMacros.swift are symlinks to CucumberSwiftMacros' declarations, and the
// macros return the step types, and call the hooks, re-exported here.
// The localized macros, such as `#ES_Dado`, expand to the step types declared in
// Sources/CucumberSwiftTesting/LocalizedStepTypes.swift.

// The expansions use CucumberSwiftTesting's step types and CucumberSwiftExpressions' `CucumberExpression`
// and `Match`, so importing this module is enough to use the macros.
@_exported import CucumberSwiftTesting
@_exported import CucumberSwiftExpressions

#if Macros
import Foundation

/// Tells the runner, at run time, that the test target links the step definition macros, so that it
/// suggests macros for undefined steps. An Objective-C class, which the linker keeps and
/// `NSClassFromString` finds, though nothing refers to it.
@objc(CucumberSwiftTestingMacrosMarker)
public final class CucumberSwiftTestingMacrosMarker: NSObject {}
#endif
