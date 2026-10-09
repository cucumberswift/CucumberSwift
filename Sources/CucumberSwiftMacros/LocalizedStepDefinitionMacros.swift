//
//  LocalizedStepDefinitionMacros.swift
//  CucumberSwiftMacros
//
//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedStepDefinitionMacroTests.
//  Do not edit: change I18n.swift, then rewrite this file as that test describes.
//

#if Macros

// MARK: Afrikaans

/// `#Given` in Afrikaans.
@freestanding(expression)
@discardableResult
public macro AF_Gegewe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Afrikaans.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AF_Gegewe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Afrikaans.
@freestanding(expression)
@discardableResult
public macro AF_Wanneer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Afrikaans.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AF_Wanneer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Afrikaans.
@freestanding(expression)
@discardableResult
public macro AF_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Afrikaans.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AF_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Afrikaans.
@freestanding(expression)
@discardableResult
public macro AF_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Afrikaans.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AF_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Afrikaans.
@freestanding(expression)
@discardableResult
public macro AF_Maar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Afrikaans.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AF_Maar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Armenian

/// `#Given` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Դիցուք<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Դիցուք<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Եթե<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Եթե<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Երբ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Երբ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Ապա<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Ապա<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Եվ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Եվ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Armenian.
@freestanding(expression)
@discardableResult
public macro AM_Բայց<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Armenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AM_Բայց<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Aragonese

/// `#Given` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Dau<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Dau<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Daus<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Daus<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Cuan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Cuan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Alavez<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Alavez<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Allora<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Allora<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Antonces<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Antonces<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Aragonese.
@freestanding(expression)
@discardableResult
public macro AN_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Aragonese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AN_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Arabic

/// `#Given` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_بفرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_بفرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_متى<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_متى<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_عندما<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_عندما<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_اذاً<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_اذاً<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_ثم<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_ثم<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_و<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_و<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Arabic.
@freestanding(expression)
@discardableResult
public macro AR_لكن<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Arabic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AR_لكن<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Asturian

/// `#Given` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Dáu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Dáu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Daos<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Daos<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Daes<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Daes<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Cuando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Cuando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Entós<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Entós<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Ya<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Ya<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Asturian.
@freestanding(expression)
@discardableResult
public macro AST_Peru<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Asturian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AST_Peru<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Azerbaijani

/// `#Given` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_TutaqKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_TutaqKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Verilir<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Verilir<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Əgər<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Əgər<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_NəVaxtKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_NəVaxtKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_OHalda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_OHalda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Və<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Və<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Həm<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Həm<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Amma<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Amma<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Azerbaijani.
@freestanding(expression)
@discardableResult
public macro AZ_Ancaq<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Azerbaijani.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro AZ_Ancaq<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Bulgarian

/// `#Given` in Bulgarian.
@freestanding(expression)
@discardableResult
public macro BG_Дадено<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Bulgarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BG_Дадено<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Bulgarian.
@freestanding(expression)
@discardableResult
public macro BG_Когато<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Bulgarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BG_Когато<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Bulgarian.
@freestanding(expression)
@discardableResult
public macro BG_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Bulgarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BG_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Bulgarian.
@freestanding(expression)
@discardableResult
public macro BG_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Bulgarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BG_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Bulgarian.
@freestanding(expression)
@discardableResult
public macro BG_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Bulgarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BG_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Malay

/// `#Given` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Diberi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Diberi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Bagi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Bagi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Apabila<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Apabila<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Maka<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Maka<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Kemudian<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Kemudian<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Tetapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Tetapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Malay.
@freestanding(expression)
@discardableResult
public macro BM_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Malay.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BM_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Bosnian

/// `#Given` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_Dato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_Dato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_Zatim<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_Zatim<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Bosnian.
@freestanding(expression)
@discardableResult
public macro BS_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Bosnian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro BS_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Catalan

/// `#Given` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Donat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Donat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Donada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Donada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Atès<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Atès<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Atesa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Atesa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Quan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Quan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Aleshores<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Aleshores<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Cal<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Cal<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Catalan.
@freestanding(expression)
@discardableResult
public macro CA_Però<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Catalan.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CA_Però<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Czech

/// `#Given` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_Pokud<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_Pokud<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_ZaPředpokladu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_ZaPředpokladu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_Když<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_Když<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_Pak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_Pak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_ATaké<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_ATaké<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Czech.
@freestanding(expression)
@discardableResult
public macro CS_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Czech.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CS_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Welsh

/// `#Given` in Welsh.
@freestanding(expression)
@discardableResult
public macro CY_GB_AnrhegedigA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Welsh.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CY_GB_AnrhegedigA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Welsh.
@freestanding(expression)
@discardableResult
public macro CY_GB_Pryd<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Welsh.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CY_GB_Pryd<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Welsh.
@freestanding(expression)
@discardableResult
public macro CY_GB_Yna<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Welsh.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CY_GB_Yna<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Welsh.
@freestanding(expression)
@discardableResult
public macro CY_GB_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Welsh.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CY_GB_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Welsh.
@freestanding(expression)
@discardableResult
public macro CY_GB_Ond<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Welsh.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro CY_GB_Ond<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Danish

/// `#Given` in Danish.
@freestanding(expression)
@discardableResult
public macro DA_Givet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Danish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DA_Givet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Danish.
@freestanding(expression)
@discardableResult
public macro DA_Når<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Danish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DA_Når<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Danish.
@freestanding(expression)
@discardableResult
public macro DA_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Danish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DA_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Danish.
@freestanding(expression)
@discardableResult
public macro DA_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Danish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DA_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Danish.
@freestanding(expression)
@discardableResult
public macro DA_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Danish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DA_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: German

/// `#Given` in German.
@freestanding(expression)
@discardableResult
public macro DE_Angenommen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_Angenommen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in German.
@freestanding(expression)
@discardableResult
public macro DE_GegebenSei<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_GegebenSei<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in German.
@freestanding(expression)
@discardableResult
public macro DE_GegebenSeien<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_GegebenSeien<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in German.
@freestanding(expression)
@discardableResult
public macro DE_Wenn<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_Wenn<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in German.
@freestanding(expression)
@discardableResult
public macro DE_Dann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_Dann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in German.
@freestanding(expression)
@discardableResult
public macro DE_Und<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_Und<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in German.
@freestanding(expression)
@discardableResult
public macro DE_Aber<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in German.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro DE_Aber<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Greek

/// `#Given` in Greek.
@freestanding(expression)
@discardableResult
public macro EL_Δεδομένου<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Greek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EL_Δεδομένου<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Greek.
@freestanding(expression)
@discardableResult
public macro EL_Όταν<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Greek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EL_Όταν<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Greek.
@freestanding(expression)
@discardableResult
public macro EL_Τότε<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Greek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EL_Τότε<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Greek.
@freestanding(expression)
@discardableResult
public macro EL_Και<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Greek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EL_Και<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Greek.
@freestanding(expression)
@discardableResult
public macro EL_Αλλά<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Greek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EL_Αλλά<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Emoji

/// `#Given` in Emoji.
@freestanding(expression)
@discardableResult
public macro EM_😐<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Emoji.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EM_😐<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Emoji.
@freestanding(expression)
@discardableResult
public macro EM_🎬<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Emoji.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EM_🎬<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Emoji.
@freestanding(expression)
@discardableResult
public macro EM_🙏<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Emoji.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EM_🙏<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Emoji.
@freestanding(expression)
@discardableResult
public macro EM_😂<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Emoji.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EM_😂<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Emoji.
@freestanding(expression)
@discardableResult
public macro EM_😔<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Emoji.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EM_😔<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Scouse

/// `#Given` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_Givun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_Givun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_YouseKnowWhenYouseGot<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_YouseKnowWhenYouseGot<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_Wun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_Wun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_YouseKnowLikeWhen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_YouseKnowLikeWhen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_Dun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_Dun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_DenYouseGotta<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_DenYouseGotta<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Scouse.
@freestanding(expression)
@discardableResult
public macro EN_SCOUSE_Buh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Scouse.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_SCOUSE_Buh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Australian

/// `#Given` in Australian.
@freestanding(expression)
@discardableResult
public macro EN_AU_YKnow<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Australian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_AU_YKnow<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Australian.
@freestanding(expression)
@discardableResult
public macro EN_AU_ItSJustUnbelievable<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Australian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_AU_ItSJustUnbelievable<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Australian.
@freestanding(expression)
@discardableResult
public macro EN_AU_ButAtTheEndOfTheDayIReckon<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Australian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_AU_ButAtTheEndOfTheDayIReckon<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Australian.
@freestanding(expression)
@discardableResult
public macro EN_AU_TooRight<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Australian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_AU_TooRight<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Australian.
@freestanding(expression)
@discardableResult
public macro EN_AU_YeahNah<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Australian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_AU_YeahNah<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: LOLCAT

/// `#Given` in LOLCAT.
@freestanding(expression)
@discardableResult
public macro EN_LOL_ICanHaz<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in LOLCAT.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_LOL_ICanHaz<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in LOLCAT.
@freestanding(expression)
@discardableResult
public macro EN_LOL_Wen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in LOLCAT.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_LOL_Wen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in LOLCAT.
@freestanding(expression)
@discardableResult
public macro EN_LOL_Den<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in LOLCAT.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_LOL_Den<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in LOLCAT.
@freestanding(expression)
@discardableResult
public macro EN_LOL_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in LOLCAT.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_LOL_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in LOLCAT.
@freestanding(expression)
@discardableResult
public macro EN_LOL_But<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in LOLCAT.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_LOL_But<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Old English

/// `#Given` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Thurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Thurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Þurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Þurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Ðurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Ðurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Tha<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Tha<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Þa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Þa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Ða<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Ða<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_ThaThe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_ThaThe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_ÞaÞe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_ÞaÞe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_ÐaÐe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_ÐaÐe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Ond<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Ond<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD__7<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD__7<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Old English.
@freestanding(expression)
@discardableResult
public macro EN_OLD_Ac<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Old English.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_OLD_Ac<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Pirate

/// `#Given` in Pirate.
@freestanding(expression)
@discardableResult
public macro EN_PIRATE_Gangway<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Pirate.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_PIRATE_Gangway<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Pirate.
@freestanding(expression)
@discardableResult
public macro EN_PIRATE_Blimey<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Pirate.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_PIRATE_Blimey<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Pirate.
@freestanding(expression)
@discardableResult
public macro EN_PIRATE_LetGoAndHaul<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Pirate.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_PIRATE_LetGoAndHaul<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Pirate.
@freestanding(expression)
@discardableResult
public macro EN_PIRATE_Aye<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Pirate.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_PIRATE_Aye<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Pirate.
@freestanding(expression)
@discardableResult
public macro EN_PIRATE_Avast<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Pirate.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EN_PIRATE_Avast<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Esperanto

/// `#Given` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Donitaĵo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Donitaĵo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Komence<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Komence<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Se<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Se<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Do<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Do<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Kaj<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Kaj<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Esperanto.
@freestanding(expression)
@discardableResult
public macro EO_Sed<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Esperanto.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro EO_Sed<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Spanish

/// `#Given` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Cuando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Cuando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Entonces<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Entonces<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Spanish.
@freestanding(expression)
@discardableResult
public macro ES_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Spanish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ES_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Estonian

/// `#Given` in Estonian.
@freestanding(expression)
@discardableResult
public macro ET_Eeldades<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Estonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ET_Eeldades<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Estonian.
@freestanding(expression)
@discardableResult
public macro ET_Kui<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Estonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ET_Kui<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Estonian.
@freestanding(expression)
@discardableResult
public macro ET_Siis<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Estonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ET_Siis<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Estonian.
@freestanding(expression)
@discardableResult
public macro ET_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Estonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ET_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Estonian.
@freestanding(expression)
@discardableResult
public macro ET_Kuid<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Estonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ET_Kuid<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Persian

/// `#Given` in Persian.
@freestanding(expression)
@discardableResult
public macro FA_بافرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Persian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FA_بافرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Persian.
@freestanding(expression)
@discardableResult
public macro FA_هنگامی<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Persian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FA_هنگامی<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Persian.
@freestanding(expression)
@discardableResult
public macro FA_آنگاه<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Persian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FA_آنگاه<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Persian.
@freestanding(expression)
@discardableResult
public macro FA_و<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Persian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FA_و<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Persian.
@freestanding(expression)
@discardableResult
public macro FA_اما<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Persian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FA_اما<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Finnish

/// `#Given` in Finnish.
@freestanding(expression)
@discardableResult
public macro FI_Oletetaan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Finnish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FI_Oletetaan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Finnish.
@freestanding(expression)
@discardableResult
public macro FI_Kun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Finnish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FI_Kun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Finnish.
@freestanding(expression)
@discardableResult
public macro FI_Niin<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Finnish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FI_Niin<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Finnish.
@freestanding(expression)
@discardableResult
public macro FI_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Finnish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FI_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Finnish.
@freestanding(expression)
@discardableResult
public macro FI_Mutta<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Finnish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FI_Mutta<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: French

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_Soit<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Soit<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonnéQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonnéQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonnéQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonnéQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonné<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonné<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonnée<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonnée<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonnés<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonnés<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtantDonnées<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtantDonnées<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonnéQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonnéQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonnéQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonnéQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonné<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonné<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonnée<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonnée<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonnés<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonnés<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in French.
@freestanding(expression)
@discardableResult
public macro FR_ÉtantDonnées<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_ÉtantDonnées<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in French.
@freestanding(expression)
@discardableResult
public macro FR_Quand<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Quand<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in French.
@freestanding(expression)
@discardableResult
public macro FR_Lorsque<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Lorsque<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in French.
@freestanding(expression)
@discardableResult
public macro FR_Lorsqu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Lorsqu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in French.
@freestanding(expression)
@discardableResult
public macro FR_Alors<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Alors<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in French.
@freestanding(expression)
@discardableResult
public macro FR_EtQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_EtQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in French.
@freestanding(expression)
@discardableResult
public macro FR_Et<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Et<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in French.
@freestanding(expression)
@discardableResult
public macro FR_MaisQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_MaisQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in French.
@freestanding(expression)
@discardableResult
public macro FR_MaisQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_MaisQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in French.
@freestanding(expression)
@discardableResult
public macro FR_Mais<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in French.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro FR_Mais<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Irish

/// `#Given` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_CuirIGcásGo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_CuirIGcásGo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_CuirIGcásNach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_CuirIGcásNach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_CuirIGcásGur<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_CuirIGcásGur<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_CuirIGcásNár<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_CuirIGcásNár<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_NuairA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_NuairA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_NuairNach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_NuairNach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_NuairBa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_NuairBa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_NuairNár<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_NuairNár<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_Ansin<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_Ansin<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_Agus<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_Agus<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Irish.
@freestanding(expression)
@discardableResult
public macro GA_Ach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Irish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GA_Ach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Gujarati

/// `#Given` in Gujarati.
@freestanding(expression)
@discardableResult
public macro GJ_આપેલછે<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Gujarati.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GJ_આપેલછે<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Gujarati.
@freestanding(expression)
@discardableResult
public macro GJ_ક્યારે<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Gujarati.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GJ_ક્યારે<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Gujarati.
@freestanding(expression)
@discardableResult
public macro GJ_પછી<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Gujarati.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GJ_પછી<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Gujarati.
@freestanding(expression)
@discardableResult
public macro GJ_અને<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Gujarati.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GJ_અને<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Gujarati.
@freestanding(expression)
@discardableResult
public macro GJ_પણ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Gujarati.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GJ_પણ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Galician

/// `#Given` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Cando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Cando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Entón<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Entón<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Logo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Logo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Mais<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Mais<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Galician.
@freestanding(expression)
@discardableResult
public macro GL_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Galician.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro GL_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Hebrew

/// `#Given` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_בהינתן<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_בהינתן<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_כאשר<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_כאשר<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_אז<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_אז<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_אזי<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_אזי<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_וגם<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_וגם<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Hebrew.
@freestanding(expression)
@discardableResult
public macro HE_אבל<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Hebrew.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HE_אבל<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Hindi

/// `#Given` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_अगर<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_अगर<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_यदि<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_यदि<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_चूंकि<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_चूंकि<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_जब<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_जब<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_कदा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_कदा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_तब<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_तब<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_तदा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_तदा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_और<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_और<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_तथा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_तथा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_पर<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_पर<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_परन्तु<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_परन्तु<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Hindi.
@freestanding(expression)
@discardableResult
public macro HI_किन्तु<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Hindi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HI_किन्तु<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Croatian

/// `#Given` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Zadan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Zadan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Zadani<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Zadani<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Zadano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Zadano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Onda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Onda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Croatian.
@freestanding(expression)
@discardableResult
public macro HR_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Croatian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HR_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Creole

/// `#Given` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Sipoze<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Sipoze<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_SipozeKe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_SipozeKe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Lè<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Lè<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Le<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Le<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_LèSaA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_LèSaA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_LeSaA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_LeSaA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Ak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Ak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Epi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Epi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Creole.
@freestanding(expression)
@discardableResult
public macro HT_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Creole.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HT_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Hungarian

/// `#Given` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Amennyiben<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Amennyiben<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Adott<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Adott<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Majd<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Majd<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Ha<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Ha<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Amikor<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Amikor<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_Akkor<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_Akkor<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_És<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_És<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Hungarian.
@freestanding(expression)
@discardableResult
public macro HU_De<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Hungarian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro HU_De<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Indonesian

/// `#Given` in Indonesian.
@freestanding(expression)
@discardableResult
public macro ID_Dengan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Indonesian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ID_Dengan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Indonesian.
@freestanding(expression)
@discardableResult
public macro ID_Ketika<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Indonesian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ID_Ketika<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Indonesian.
@freestanding(expression)
@discardableResult
public macro ID_Maka<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Indonesian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ID_Maka<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Indonesian.
@freestanding(expression)
@discardableResult
public macro ID_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Indonesian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ID_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Indonesian.
@freestanding(expression)
@discardableResult
public macro ID_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Indonesian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ID_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Icelandic

/// `#Given` in Icelandic.
@freestanding(expression)
@discardableResult
public macro IS_Ef<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Icelandic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IS_Ef<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Icelandic.
@freestanding(expression)
@discardableResult
public macro IS_Þegar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Icelandic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IS_Þegar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Icelandic.
@freestanding(expression)
@discardableResult
public macro IS_Þá<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Icelandic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IS_Þá<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Icelandic.
@freestanding(expression)
@discardableResult
public macro IS_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Icelandic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IS_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Icelandic.
@freestanding(expression)
@discardableResult
public macro IS_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Icelandic.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IS_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Italian

/// `#Given` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Dato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Dato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Data<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Data<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Dati<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Dati<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Date<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Date<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Quando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Quando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Allora<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Allora<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Italian.
@freestanding(expression)
@discardableResult
public macro IT_Ma<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Italian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro IT_Ma<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Japanese

/// `#Given` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_前提<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_前提<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_もし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_もし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_ならば<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_ならば<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_かつ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_かつ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_しかし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_しかし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_但し<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_但し<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Japanese.
@freestanding(expression)
@discardableResult
public macro JA_ただし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Japanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JA_ただし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Javanese

/// `#Given` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Nalika<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Nalika<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Nalikaning<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Nalikaning<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Manawa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Manawa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Menawa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Menawa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Njuk<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Njuk<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Banjur<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Banjur<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Lan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Lan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Nanging<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Nanging<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Javanese.
@freestanding(expression)
@discardableResult
public macro JV_Ananging<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Javanese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro JV_Ananging<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Georgian

/// `#Given` in Georgian.
@freestanding(expression)
@discardableResult
public macro KA_Მოცემული<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Georgian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KA_Მოცემული<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Georgian.
@freestanding(expression)
@discardableResult
public macro KA_Როდესაც<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Georgian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KA_Როდესაც<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Georgian.
@freestanding(expression)
@discardableResult
public macro KA_Მაშინ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Georgian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KA_Მაშინ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Georgian.
@freestanding(expression)
@discardableResult
public macro KA_Და<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Georgian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KA_Და<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Georgian.
@freestanding(expression)
@discardableResult
public macro KA_Მაგ­რამ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Georgian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KA_Მაგ­რამ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Kannada

/// `#Given` in Kannada.
@freestanding(expression)
@discardableResult
public macro KN_ನೀಡಿದ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Kannada.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KN_ನೀಡಿದ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Kannada.
@freestanding(expression)
@discardableResult
public macro KN_ಸ್ಥಿತಿಯನ್ನು<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Kannada.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KN_ಸ್ಥಿತಿಯನ್ನು<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Kannada.
@freestanding(expression)
@discardableResult
public macro KN_ನಂತರ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Kannada.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KN_ನಂತರ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Kannada.
@freestanding(expression)
@discardableResult
public macro KN_ಮತ್ತು<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Kannada.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KN_ಮತ್ತು<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Kannada.
@freestanding(expression)
@discardableResult
public macro KN_ಆದರೆ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Kannada.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KN_ಆದರೆ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Korean

/// `#Given` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_조건<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_조건<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_먼저<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_먼저<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_만일<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_만일<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_만약<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_만약<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_그러면<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_그러면<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_그리고<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_그리고<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_하지만<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_하지만<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Korean.
@freestanding(expression)
@discardableResult
public macro KO_단<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Korean.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro KO_단<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Lithuanian

/// `#Given` in Lithuanian.
@freestanding(expression)
@discardableResult
public macro LT_Duota<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Lithuanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LT_Duota<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Lithuanian.
@freestanding(expression)
@discardableResult
public macro LT_Kai<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Lithuanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LT_Kai<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Lithuanian.
@freestanding(expression)
@discardableResult
public macro LT_Tada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Lithuanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LT_Tada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Lithuanian.
@freestanding(expression)
@discardableResult
public macro LT_Ir<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Lithuanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LT_Ir<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Lithuanian.
@freestanding(expression)
@discardableResult
public macro LT_Bet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Lithuanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LT_Bet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Luxemburgish

/// `#Given` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_Ugeholl<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_Ugeholl<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_Wann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_Wann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_Dann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_Dann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_Awer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_Awer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Luxemburgish.
@freestanding(expression)
@discardableResult
public macro LU_Mä<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Luxemburgish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LU_Mä<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Latvian

/// `#Given` in Latvian.
@freestanding(expression)
@discardableResult
public macro LV_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Latvian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LV_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Latvian.
@freestanding(expression)
@discardableResult
public macro LV_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Latvian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LV_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Latvian.
@freestanding(expression)
@discardableResult
public macro LV_Tad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Latvian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LV_Tad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Latvian.
@freestanding(expression)
@discardableResult
public macro LV_Un<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Latvian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LV_Un<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Latvian.
@freestanding(expression)
@discardableResult
public macro LV_Bet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Latvian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro LV_Bet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Macedonian

/// `#Given` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_Дадено<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_Дадено<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_Дадена<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_Дадена<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_Кога<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_Кога<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_Тогаш<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_Тогаш<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Macedonian.
@freestanding(expression)
@discardableResult
public macro MK_CYRL_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Macedonian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_CYRL_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Macedonian (Latin)

/// `#Given` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_Dadeno<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_Dadeno<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_Dadena<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_Dadena<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_Koga<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_Koga<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_Togash<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_Togash<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Macedonian (Latin).
@freestanding(expression)
@discardableResult
public macro MK_LATN_No<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Macedonian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MK_LATN_No<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Mongolian

/// `#Given` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_ӨгөгдсөнНь<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_ӨгөгдсөнНь<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Анх<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Анх<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Хэрэв<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Хэрэв<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Тэгэхэд<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Тэгэхэд<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_ҮүнийДараа<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_ҮүнийДараа<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Мөн<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Мөн<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Тэгээд<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Тэгээд<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Гэхдээ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Гэхдээ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Mongolian.
@freestanding(expression)
@discardableResult
public macro MN_Харин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Mongolian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro MN_Харин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Dutch

/// `#Given` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Gegeven<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Gegeven<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Stel<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Stel<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Als<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Als<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Wanneer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Wanneer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Dutch.
@freestanding(expression)
@discardableResult
public macro NL_Maar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Dutch.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NL_Maar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Norwegian

/// `#Given` in Norwegian.
@freestanding(expression)
@discardableResult
public macro NO_Gitt<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Norwegian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NO_Gitt<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Norwegian.
@freestanding(expression)
@discardableResult
public macro NO_Når<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Norwegian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NO_Når<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Norwegian.
@freestanding(expression)
@discardableResult
public macro NO_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Norwegian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NO_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Norwegian.
@freestanding(expression)
@discardableResult
public macro NO_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Norwegian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NO_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Norwegian.
@freestanding(expression)
@discardableResult
public macro NO_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Norwegian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro NO_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Panjabi

/// `#Given` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਜੇਕਰ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਜੇਕਰ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਜਿਵੇਂਕਿ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਜਿਵੇਂਕਿ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਜਦੋਂ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਜਦੋਂ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਤਦ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਤਦ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਅਤੇ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਅਤੇ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Panjabi.
@freestanding(expression)
@discardableResult
public macro PA_ਪਰ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Panjabi.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PA_ਪਰ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Polish

/// `#Given` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Zakładając<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Zakładając<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Mając<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Mając<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_ZakładającŻe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_ZakładającŻe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Jeżeli<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Jeżeli<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Jeśli<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Jeśli<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Gdy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Gdy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Kiedy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Kiedy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Wtedy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Wtedy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Oraz<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Oraz<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Polish.
@freestanding(expression)
@discardableResult
public macro PL_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Polish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PL_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Portuguese

/// `#Given` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Quando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Quando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Então<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Então<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Entao<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Entao<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Portuguese.
@freestanding(expression)
@discardableResult
public macro PT_Mas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Portuguese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro PT_Mas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Romanian

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DateFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DateFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DatFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DatFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DatăFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DatăFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DatiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DatiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DațiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DațiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_DaţiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_DaţiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Cand<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Cand<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Când<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Când<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Atunci<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Atunci<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Si<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Si<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Și<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Și<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Şi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Şi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Romanian.
@freestanding(expression)
@discardableResult
public macro RO_Dar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Romanian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RO_Dar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Russian

/// `#Given` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Допустим<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Допустим<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Дано<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Дано<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Пусть<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Пусть<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Когда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Когда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Если<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Если<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Затем<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Затем<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Тогда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Тогда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_КТомуЖе<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_КТомуЖе<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Также<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Также<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_А<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_А<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Russian.
@freestanding(expression)
@discardableResult
public macro RU_Иначе<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Russian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro RU_Иначе<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Slovak

/// `#Given` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Pokiaľ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Pokiaľ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_ZaPredpokladu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_ZaPredpokladu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Keď<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Keď<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Ak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Ak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Tak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Tak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Potom<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Potom<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_ATiež<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_ATiež<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_ATaktiež<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_ATaktiež<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_AZároveň<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_AZároveň<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Slovak.
@freestanding(expression)
@discardableResult
public macro SK_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Slovak.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SK_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Slovenian

/// `#Given` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Dano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Dano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Podano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Podano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Zaradi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Zaradi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Privzeto<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Privzeto<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Ko<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Ko<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Ce<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Ce<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Če<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Če<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Kadar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Kadar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Nato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Nato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Potem<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Potem<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Takrat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Takrat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_In<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_In<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Ter<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Ter<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Toda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Toda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Ampak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Ampak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Slovenian.
@freestanding(expression)
@discardableResult
public macro SL_Vendar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Slovenian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SL_Vendar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Serbian

/// `#Given` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_ЗаДато<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_ЗаДато<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_ЗаДате<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_ЗаДате<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_ЗаДати<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_ЗаДати<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_Када<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_Када<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_Кад<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_Кад<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_Онда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_Онда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Serbian.
@freestanding(expression)
@discardableResult
public macro SR_CYRL_Али<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Serbian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_CYRL_Али<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Serbian (Latin)

/// `#Given` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_ZaDato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_ZaDato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_ZaDate<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_ZaDate<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_ZaDati<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_ZaDati<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_Onda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_Onda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Serbian (Latin).
@freestanding(expression)
@discardableResult
public macro SR_LATN_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Serbian (Latin).
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SR_LATN_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Swedish

/// `#Given` in Swedish.
@freestanding(expression)
@discardableResult
public macro SV_Givet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Swedish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SV_Givet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Swedish.
@freestanding(expression)
@discardableResult
public macro SV_När<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Swedish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SV_När<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Swedish.
@freestanding(expression)
@discardableResult
public macro SV_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Swedish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SV_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Swedish.
@freestanding(expression)
@discardableResult
public macro SV_Och<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Swedish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SV_Och<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Swedish.
@freestanding(expression)
@discardableResult
public macro SV_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Swedish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro SV_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Tamil

/// `#Given` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_கொடுக்கப்பட்ட<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_கொடுக்கப்பட்ட<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_எப்போது<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_எப்போது<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_அப்பொழுது<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_அப்பொழுது<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_மேலும்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_மேலும்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_மற்றும்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_மற்றும்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Tamil.
@freestanding(expression)
@discardableResult
public macro TA_ஆனால்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Tamil.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TA_ஆனால்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Thai

/// `#Given` in Thai.
@freestanding(expression)
@discardableResult
public macro TH_กำหนดให้<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Thai.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TH_กำหนดให้<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Thai.
@freestanding(expression)
@discardableResult
public macro TH_เมื่อ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Thai.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TH_เมื่อ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Thai.
@freestanding(expression)
@discardableResult
public macro TH_ดังนั้น<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Thai.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TH_ดังนั้น<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Thai.
@freestanding(expression)
@discardableResult
public macro TH_และ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Thai.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TH_และ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Thai.
@freestanding(expression)
@discardableResult
public macro TH_แต่<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Thai.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TH_แต่<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Telugu

/// `#Given` in Telugu.
@freestanding(expression)
@discardableResult
public macro TL_చెప్పబడినది<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Telugu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TL_చెప్పబడినది<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Telugu.
@freestanding(expression)
@discardableResult
public macro TL_ఈపరిస్థితిలో<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Telugu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TL_ఈపరిస్థితిలో<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Telugu.
@freestanding(expression)
@discardableResult
public macro TL_అప్పుడు<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Telugu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TL_అప్పుడు<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Telugu.
@freestanding(expression)
@discardableResult
public macro TL_మరియు<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Telugu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TL_మరియు<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Telugu.
@freestanding(expression)
@discardableResult
public macro TL_కాని<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Telugu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TL_కాని<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Klingon

/// `#Given` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH_GhuNoblu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH_GhuNoblu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH_DaHGhuBejlu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH_DaHGhuBejlu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH_QaSDI<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH_QaSDI<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH_Vaj<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH_Vaj<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH__Ej<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH__Ej<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH_Latlh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH_Latlh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH__Ach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH__Ach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Klingon.
@freestanding(expression)
@discardableResult
public macro TLH__A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Klingon.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TLH__A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Turkish

/// `#Given` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_DiyelimKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_DiyelimKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_EğerKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_EğerKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_OZaman<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_OZaman<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_Ve<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_Ve<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_Fakat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_Fakat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Turkish.
@freestanding(expression)
@discardableResult
public macro TR_Ama<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Turkish.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TR_Ama<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Tatar

/// `#Given` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Әйтик<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Әйтик<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Әгәр<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Әгәр<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Нәтиҗәдә<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Нәтиҗәдә<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Һәм<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Һәм<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Вә<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Вә<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Ләкин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Ләкин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Tatar.
@freestanding(expression)
@discardableResult
public macro TT_Әмма<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Tatar.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro TT_Әмма<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Ukrainian

/// `#Given` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Припустимо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Припустимо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_ПрипустимоЩо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_ПрипустимоЩо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Нехай<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Нехай<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Дано<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Дано<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Якщо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Якщо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Коли<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Коли<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Тоді<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Тоді<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_І<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_І<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_АТакож<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_АТакож<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Та<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Та<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Ukrainian.
@freestanding(expression)
@discardableResult
public macro UK_Але<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Ukrainian.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UK_Але<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Urdu

/// `#Given` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_اگر<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_اگر<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_بالفرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_بالفرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_فرضکیا<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_فرضکیا<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_جب<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_جب<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_پھر<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_پھر<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_تب<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_تب<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_اور<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_اور<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Urdu.
@freestanding(expression)
@discardableResult
public macro UR_لیکن<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Urdu.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UR_لیکن<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Uzbek

/// `#Given` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Агар<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Агар<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Унда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Унда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Ва<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Ва<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Лекин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Лекин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Бирок<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Бирок<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Uzbek.
@freestanding(expression)
@discardableResult
public macro UZ_Аммо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Uzbek.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro UZ_Аммо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Vietnamese

/// `#Given` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Biết<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Biết<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Cho<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Cho<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Khi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Khi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Thì<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Thì<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Và<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Và<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Vietnamese.
@freestanding(expression)
@discardableResult
public macro VI_Nhưng<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Vietnamese.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro VI_Nhưng<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Chinese simplified

/// `#Given` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_假如<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_假如<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_假设<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_假设<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_假定<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_假定<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_当<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_当<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_那么<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_那么<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_而且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_而且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_并且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_并且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_同时<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_同时<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Chinese simplified.
@freestanding(expression)
@discardableResult
public macro ZH_CN_但是<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Chinese simplified.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_CN_但是<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

// MARK: Chinese traditional

/// `#Given` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_假如<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_假如<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_假設<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_假設<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_假定<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Given` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_假定<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_當<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#When` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_當<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_那麼<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#Then` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_那麼<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_而且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_而且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_並且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_並且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_同時<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#And` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_同時<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` in Chinese traditional.
@freestanding(expression)
@discardableResult
public macro ZH_TW_但是<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

/// `#But` with a regex literal, in Chinese traditional.
@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public macro ZH_TW_但是<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#else
// Without the Macros trait the macros are declared but unavailable, as in StepDefinitionMacros.swift.

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Gegewe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Gegewe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Wanneer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Wanneer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Maar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AF_Maar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Դիցուք<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Դիցուք<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Եթե<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Եթե<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Երբ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Երբ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Ապա<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Ապա<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Եվ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Եվ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Բայց<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AM_Բայց<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dau<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dau<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Daus<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Daus<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Cuan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Cuan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Alavez<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Alavez<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Allora<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Allora<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Antonces<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Antonces<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AN_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_بفرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_بفرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_متى<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_متى<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_عندما<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_عندما<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_اذاً<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_اذاً<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_ثم<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_ثم<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_و<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_و<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_لكن<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AR_لكن<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Dáu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Dáu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Daos<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Daos<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Daes<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Daes<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Cuando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Cuando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Entós<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Entós<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Ya<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Ya<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Peru<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AST_Peru<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_TutaqKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_TutaqKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Verilir<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Verilir<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Əgər<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Əgər<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_NəVaxtKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_NəVaxtKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_OHalda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_OHalda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Və<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Və<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Həm<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Həm<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Amma<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Amma<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Ancaq<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro AZ_Ancaq<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Дадено<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Дадено<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Когато<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Когато<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BG_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Diberi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Diberi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Bagi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Bagi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Apabila<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Apabila<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Maka<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Maka<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Kemudian<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Kemudian<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Tetapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Tetapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BM_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Dato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Dato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Zatim<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Zatim<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro BS_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Donat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Donat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Donada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Donada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Atès<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Atès<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Atesa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Atesa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Quan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Quan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Aleshores<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Aleshores<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Cal<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Cal<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Però<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CA_Però<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Pokud<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Pokud<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_ZaPředpokladu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_ZaPředpokladu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Když<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Když<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Pak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Pak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_ATaké<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_ATaké<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CS_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_AnrhegedigA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_AnrhegedigA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Pryd<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Pryd<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Yna<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Yna<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Ond<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro CY_GB_Ond<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Givet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Givet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Når<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Når<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DA_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Angenommen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Angenommen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_GegebenSei<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_GegebenSei<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_GegebenSeien<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_GegebenSeien<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Wenn<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Wenn<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Dann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Dann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Und<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Und<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Aber<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro DE_Aber<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Δεδομένου<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Δεδομένου<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Όταν<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Όταν<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Τότε<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Τότε<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Και<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Και<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Αλλά<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EL_Αλλά<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😐<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😐<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_🎬<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_🎬<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_🙏<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_🙏<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😂<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😂<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😔<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EM_😔<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Givun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Givun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_YouseKnowWhenYouseGot<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_YouseKnowWhenYouseGot<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Wun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Wun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_YouseKnowLikeWhen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_YouseKnowLikeWhen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Dun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Dun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_DenYouseGotta<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_DenYouseGotta<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Buh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_SCOUSE_Buh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_YKnow<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_YKnow<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_ItSJustUnbelievable<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_ItSJustUnbelievable<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_ButAtTheEndOfTheDayIReckon<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_ButAtTheEndOfTheDayIReckon<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_TooRight<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_TooRight<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_YeahNah<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_AU_YeahNah<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_ICanHaz<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_ICanHaz<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_Wen<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_Wen<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_Den<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_Den<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_But<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_LOL_But<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Thurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Thurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Þurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Þurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ðurh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ðurh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Tha<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Tha<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Þa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Þa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ða<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ða<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ThaThe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ThaThe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ÞaÞe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ÞaÞe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ÐaÐe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_ÐaÐe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ond<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ond<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD__7<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD__7<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ac<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_OLD_Ac<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Gangway<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Gangway<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Blimey<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Blimey<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_LetGoAndHaul<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_LetGoAndHaul<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Aye<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Aye<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Avast<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EN_PIRATE_Avast<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Donitaĵo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Donitaĵo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Komence<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Komence<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Se<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Se<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Do<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Do<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Kaj<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Kaj<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Sed<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro EO_Sed<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Cuando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Cuando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Entonces<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Entonces<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Y<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Y<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ES_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Eeldades<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Eeldades<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Kui<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Kui<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Siis<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Siis<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Kuid<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ET_Kuid<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_بافرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_بافرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_هنگامی<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_هنگامی<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_آنگاه<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_آنگاه<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_و<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_و<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_اما<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FA_اما<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Oletetaan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Oletetaan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Kun<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Kun<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Niin<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Niin<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Mutta<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FI_Mutta<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Soit<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Soit<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnéQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnéQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnéQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnéQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonné<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonné<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnée<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnée<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnés<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnés<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnées<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtantDonnées<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnéQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnéQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnéQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnéQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonné<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonné<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnée<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnée<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnés<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnés<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnées<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_ÉtantDonnées<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Quand<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Quand<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Lorsque<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Lorsque<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Lorsqu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Lorsqu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Alors<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Alors<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_EtQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Et<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Et<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_MaisQue<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_MaisQue<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_MaisQu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_MaisQu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Mais<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro FR_Mais<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásGo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásGo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásNach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásNach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásGur<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásGur<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásNár<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_CuirIGcásNár<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairNach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairNach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairBa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairBa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairNár<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_NuairNár<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Ansin<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Ansin<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Agus<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Agus<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Ach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GA_Ach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_આપેલછે<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_આપેલછે<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_ક્યારે<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_ક્યારે<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_પછી<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_પછી<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_અને<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_અને<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_પણ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GJ_પણ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Cando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Cando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Entón<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Entón<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Logo<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Logo<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Mais<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Mais<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Pero<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro GL_Pero<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_בהינתן<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_בהינתן<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_כאשר<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_כאשר<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אז<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אז<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אזי<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אזי<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_וגם<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_וגם<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אבל<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HE_אבל<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_अगर<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_अगर<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_यदि<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_यदि<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_चूंकि<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_चूंकि<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_जब<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_जब<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_कदा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_कदा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तब<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तब<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तदा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तदा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_और<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_और<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तथा<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_तथा<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_पर<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_पर<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_परन्तु<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_परन्तु<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_किन्तु<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HI_किन्तु<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadani<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadani<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Zadano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Onda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Onda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HR_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Sipoze<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Sipoze<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_SipozeKe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_SipozeKe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Lè<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Lè<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Le<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Le<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_LèSaA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_LèSaA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_LeSaA<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_LeSaA<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Ak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Ak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Epi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Epi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HT_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Amennyiben<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Amennyiben<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Adott<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Adott<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Majd<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Majd<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Ha<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Ha<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Amikor<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Amikor<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Akkor<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_Akkor<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_És<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_És<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_De<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro HU_De<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Dengan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Dengan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Ketika<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Ketika<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Maka<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Maka<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ID_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Ef<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Ef<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Þegar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Þegar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Þá<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Þá<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IS_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Dato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Dato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Data<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Data<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Dati<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Dati<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Date<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Date<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Quando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Quando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Allora<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Allora<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Ma<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro IT_Ma<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_前提<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_前提<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_もし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_もし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_ならば<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_ならば<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_かつ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_かつ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_しかし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_しかし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_但し<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_但し<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_ただし<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JA_ただし<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nalika<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nalika<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nalikaning<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nalikaning<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Manawa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Manawa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Menawa<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Menawa<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Njuk<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Njuk<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Banjur<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Banjur<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Lan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Lan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Tapi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Tapi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nanging<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Nanging<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Ananging<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro JV_Ananging<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მოცემული<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მოცემული<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Როდესაც<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Როდესაც<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მაშინ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მაშინ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Და<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Და<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მაგ­რამ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KA_Მაგ­რამ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ನೀಡಿದ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ನೀಡಿದ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಸ್ಥಿತಿಯನ್ನು<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಸ್ಥಿತಿಯನ್ನು<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ನಂತರ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ನಂತರ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಮತ್ತು<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಮತ್ತು<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಆದರೆ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KN_ಆದರೆ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_조건<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_조건<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_먼저<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_먼저<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_만일<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_만일<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_만약<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_만약<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_그러면<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_그러면<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_그리고<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_그리고<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_하지만<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_하지만<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_단<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro KO_단<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Duota<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Duota<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Kai<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Kai<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Tada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Tada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Ir<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Ir<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Bet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LT_Bet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Ugeholl<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Ugeholl<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Wann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Wann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Dann<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Dann<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_An<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_An<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Awer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Awer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Mä<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LU_Mä<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Ja<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Ja<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Tad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Tad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Un<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Un<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Bet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro LV_Bet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Дадено<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Дадено<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Дадена<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Дадена<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Кога<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Кога<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Тогаш<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Тогаш<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_CYRL_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Dadeno<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Dadeno<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Dadena<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Dadena<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Koga<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Koga<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Togash<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_Togash<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_No<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MK_LATN_No<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_ӨгөгдсөнНь<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_ӨгөгдсөнНь<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Анх<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Анх<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Хэрэв<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Хэрэв<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Тэгэхэд<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Тэгэхэд<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_ҮүнийДараа<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_ҮүнийДараа<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Мөн<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Мөн<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Тэгээд<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Тэгээд<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Гэхдээ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Гэхдээ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Харин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro MN_Харин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Gegeven<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Gegeven<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Stel<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Stel<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Als<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Als<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Wanneer<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Wanneer<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Dan<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Dan<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_En<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_En<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Maar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NL_Maar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Gitt<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Gitt<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Når<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Når<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Og<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Og<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro NO_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜੇਕਰ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜੇਕਰ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜਿਵੇਂਕਿ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜਿਵੇਂਕਿ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜਦੋਂ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਜਦੋਂ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਤਦ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਤਦ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਅਤੇ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਅਤੇ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਪਰ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PA_ਪਰ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Zakładając<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Zakładając<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Mając<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Mając<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_ZakładającŻe<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_ZakładającŻe<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Jeżeli<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Jeżeli<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Jeśli<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Jeśli<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Gdy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Gdy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Kiedy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Kiedy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Wtedy<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Wtedy<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Oraz<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Oraz<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PL_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dado<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dado<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dados<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dados<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dadas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Dadas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Quando<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Quando<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Então<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Então<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Entao<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Entao<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_E<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_E<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Mas<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro PT_Mas<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DateFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DateFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatăFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatăFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DatiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DațiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DațiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DaţiFiind<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_DaţiFiind<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Cand<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Cand<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Când<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Când<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Atunci<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Atunci<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Si<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Si<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Și<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Și<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Şi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Şi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Dar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RO_Dar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Допустим<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Допустим<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Дано<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Дано<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Пусть<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Пусть<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Когда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Когда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Если<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Если<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Затем<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Затем<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Тогда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Тогда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_КТомуЖе<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_КТомуЖе<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Также<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Также<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Но<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Но<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_А<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_А<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Иначе<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro RU_Иначе<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Pokiaľ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Pokiaľ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ZaPredpokladu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ZaPredpokladu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Keď<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Keď<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Ak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Ak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Tak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Tak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Potom<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Potom<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ATiež<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ATiež<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ATaktiež<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_ATaktiež<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_AZároveň<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_AZároveň<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Ale<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SK_Ale<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Dano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Dano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Podano<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Podano<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Zaradi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Zaradi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Privzeto<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Privzeto<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ko<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ko<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ce<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ce<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Če<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Če<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Kadar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Kadar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Nato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Nato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Potem<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Potem<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Takrat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Takrat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_In<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_In<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ter<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ter<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Toda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Toda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ampak<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Ampak<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Vendar<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SL_Vendar<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДато<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДато<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДате<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДате<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДати<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_ЗаДати<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Када<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Када<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Кад<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Кад<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Онда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Онда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_И<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_И<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Али<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_CYRL_Али<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDato<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDato<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDate<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDate<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDati<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_ZaDati<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Kada<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Kada<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Kad<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Kad<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Onda<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Onda<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_I<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_I<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Ali<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SR_LATN_Ali<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Givet<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Givet<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_När<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_När<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Så<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Så<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Och<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Och<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Men<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro SV_Men<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_கொடுக்கப்பட்ட<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_கொடுக்கப்பட்ட<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_எப்போது<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_எப்போது<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_அப்பொழுது<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_அப்பொழுது<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_மேலும்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_மேலும்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_மற்றும்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_மற்றும்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_ஆனால்<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TA_ஆனால்<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_กำหนดให้<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_กำหนดให้<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_เมื่อ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_เมื่อ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_ดังนั้น<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_ดังนั้น<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_และ<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_และ<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_แต่<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TH_แต่<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_చెప్పబడినది<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_చెప్పబడినది<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_ఈపరిస్థితిలో<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_ఈపరిస్థితిలో<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_అప్పుడు<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_అప్పుడు<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_మరియు<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_మరియు<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_కాని<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TL_కాని<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_GhuNoblu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_GhuNoblu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_DaHGhuBejlu<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_DaHGhuBejlu<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_QaSDI<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_QaSDI<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_Vaj<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_Vaj<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__Ej<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__Ej<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_Latlh<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH_Latlh<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__Ach<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__Ach<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__A<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TLH__A<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_DiyelimKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_DiyelimKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_EğerKi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_EğerKi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_OZaman<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_OZaman<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Ve<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Ve<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Fakat<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Fakat<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Ama<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TR_Ama<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әйтик<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әйтик<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әгәр<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әгәр<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Нәтиҗәдә<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Нәтиҗәдә<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Һәм<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Һәм<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Вә<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Вә<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Ләкин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Ләкин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әмма<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro TT_Әмма<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Припустимо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Припустимо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_ПрипустимоЩо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_ПрипустимоЩо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Нехай<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Нехай<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Дано<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Дано<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Якщо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Якщо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Коли<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Коли<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_То<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_То<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Тоді<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Тоді<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_І<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_І<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_АТакож<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_АТакож<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Та<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Та<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Але<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UK_Але<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_اگر<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_اگر<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_بالفرض<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_بالفرض<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_فرضکیا<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_فرضکیا<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_جب<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_جب<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_پھر<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_پھر<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_تب<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_تب<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_اور<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_اور<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_لیکن<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UR_لیکن<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Агар<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Агар<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Унда<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Унда<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Ва<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Ва<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Лекин<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Лекин<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Бирок<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Бирок<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Аммо<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro UZ_Аммо<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Biết<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Biết<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Cho<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Cho<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Khi<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Khi<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Thì<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Thì<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Và<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Và<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Nhưng<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro VI_Nhưng<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假如<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假如<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假设<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假设<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假定<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_假定<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_当<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_当<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_那么<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_那么<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_而且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_而且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_并且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_并且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_同时<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_同时<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_但是<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_CN_但是<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假如<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假如<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假設<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假設<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假定<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_假定<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> GivenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_當<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_當<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> WhenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_那麼<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_那麼<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ThenStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_而且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_而且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_並且<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_並且<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_同時<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_同時<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> AndStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_但是<each Argument>(_ expression: String,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")

@freestanding(expression)
@discardableResult
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@available(*, unavailable, message: "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later.")
public macro ZH_TW_但是<Output, each Argument>(_ regex: Regex<Output>,
    _ body: (repeat each Argument) async throws -> Void) -> ButStep
    = #externalMacro(module: "CucumberSwiftMacrosPlugin", type: "StepDefinitionMacro")
#endif
