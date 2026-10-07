//
//  main.swift
//  CucumberSwiftMacroConverterTool
//

import Foundation

// The tool the Convert to Gherkin Macros command runs: `CucumberSwiftMacroConverterTool [--dry-run] <folder or .swift file>…`.
// It rewrites the step definitions it can convert exactly, and lists each one it leaves unchanged with the reason.
#if Macros
exit(MacroConversion.run(arguments: Array(CommandLine.arguments.dropFirst())))
#else
FileHandle.standardError.write(Data("""
    Convert to Gherkin Macros needs CucumberSwift's Macros package trait, which brings in swift-syntax. \
    Turn the trait on in your Package.swift, as described in "Checking Step Definitions When They Compile", then run the command again.

    """.utf8))
exit(1)
#endif
