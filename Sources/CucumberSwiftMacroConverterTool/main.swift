//
//  main.swift
//  CucumberSwiftMacroConverterTool
//

import Foundation

// The tool the Convert to Gherkin Macros command runs: `CucumberSwiftMacroConverterTool [--dry-run] <folder or .swift file>…`.
// It rewrites the step definitions it can convert exactly, marks each one it leaves with a #warning, and
// lists them all with the reason.
#if Macros
exit(MacroConversion.run(arguments: Array(CommandLine.arguments.dropFirst())))
#else
// Without the trait the tool has no swift-syntax, so it can't read Swift code. It says what to change, for the
// kind of project it finds from `--root`, and changes nothing.
let arguments = Array(CommandLine.arguments.dropFirst())
let root = arguments.firstIndex(of: "--root").flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
FileHandle.standardError.write(Data(SetupAdvice.traitOffMessage(root: root).utf8))
exit(2)
#endif
