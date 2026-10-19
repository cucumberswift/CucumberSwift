//
//  Exports.swift
//  CucumberSwiftMacros
//

// The expansions use CucumberSwift's step types and CucumberSwiftExpressions' `CucumberExpression` and
// `Match`, so importing this module is enough to use the macros.
@_exported import CucumberSwift
@_exported import CucumberSwiftExpressions

#if Macros
import Foundation

/// Tells the runner, at run time, that the test target links the step definition macros, so that it
/// suggests macros for undefined steps. An Objective-C class, which the linker keeps and
/// `NSClassFromString` finds, though nothing refers to it.
@objc(CucumberSwiftMacrosMarker)
public final class CucumberSwiftMacrosMarker: NSObject {}
#endif
