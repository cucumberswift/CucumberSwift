//
//  Unconvertible.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// Why a step definition can't be converted.
struct Unconvertible: Error {
    let reason: String
}
#endif
