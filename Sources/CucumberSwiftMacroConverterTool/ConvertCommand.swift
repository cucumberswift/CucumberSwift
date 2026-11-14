//
//  ConvertCommand.swift
//  CucumberSwiftMacroConverterTool
//

import Foundation

/// `cucumberswift convert-to-gherkin-macros [--dry-run] <folder or .swift file>…`, which the Convert to Gherkin
/// Macros command plugin runs. It rewrites the step definitions it can convert exactly, marks each one it leaves
/// with a #warning, and lists them all with the reason.
public enum ConvertCommand {
    /// Returns the exit status.
    public static func run(arguments: [String]) -> Int32 {
#if Macros
        return MacroConversion.run(arguments: arguments)
#else
        // Without the trait the tool has no swift-syntax, so it can't read Swift code. It says what to change, for the
        // kind of project it finds from `--root`, and changes nothing.
        let root = arguments.firstIndex(of: "--root").flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
        FileHandle.standardError.write(Data(SetupAdvice.traitOffMessage(root: root).utf8))
        return 2
#endif
    }
}
