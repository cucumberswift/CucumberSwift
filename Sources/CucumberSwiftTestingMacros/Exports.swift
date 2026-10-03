//
//  Exports.swift
//  CucumberSwiftTestingMacros
//
// The step definition macros of CucumberSwiftMacros, for the Swift Testing runner. StepDefinitionMacros.swift
// is a symlink to CucumberSwiftMacros' declarations, and the macros return the step types re-exported here.
// The localized macros, such as `#ES_Dado`, are not here: CucumberSwiftTesting has no localized step types.

// The expansions use CucumberSwiftTesting's step types and CucumberSwiftExpressions' `CucumberExpression`
// and `Match`, so importing this module is enough to use the macros.
@_exported import CucumberSwiftTesting
@_exported import CucumberSwiftExpressions
