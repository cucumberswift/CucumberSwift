import CucumberSwiftCoverageMerge
import CucumberSwiftLintTool
import Foundation
// Swift 6.0 reads Package@swift-6.0.swift, which has neither the Swift Testing runner nor the macros.
#if canImport(CucumberSwiftMacroConverterTool)
import CucumberSwiftMacroConverterTool
#endif
#if canImport(CucumberSwiftTestingGenerator)
import CucumberSwiftTestingGenerator
#endif

// cucumberswift <command> …
//
// CucumberSwift's command-line tool, run with `swift run cucumberswift`. It picks the command by its first
// argument, and the command's library target runs it with `run(arguments:) -> Int32`, which returns the exit
// status. Another command is another case here and a library target that the tool depends on. The plugins for
// SwiftPM and Xcode run the same commands, so every build tool shares one implementation.
//
//   coverage merge <folder>…                scores the scenarios of several runs as one run (CoverageCommand)
//   generate --output <file> <feature>…     writes the Swift Testing tests of feature files (GenerateCommand)
//   lint --stamp <file> --features …        checks feature files (LintCommand)
//   fix-feature-files <path>…               fixes the misspelt keywords that lint reports (LintCommand)
//   convert-to-gherkin-macros <path>…       rewrites step definitions as macros (ConvertCommand)

/// The `cucumberswift` command line: the commands and the usage, shared by the cucumberswift tool, by Bazel's
/// swift_binary, and by the tool the SwiftPM and Xcode plugins run.
public enum CucumberSwiftCommandLine {
    public static let usage = """
        usage: cucumberswift <command> …
          coverage merge <coverage folder or run folder>…
          generate --output <file.swift> <feature files…> [--swift <Swift file>]…
          lint --stamp <file> --features <feature files…> --step-definitions <Swift files…>
          fix-feature-files <feature files or folders…>
          convert-to-gherkin-macros [--dry-run] <Swift files or folders…>
        """

    /// Runs the command that the first of `arguments` names, and returns the exit status.
    public static func run(arguments: [String]) -> Int32 {
        let rest = Array(arguments.dropFirst())
        switch arguments.first {
            case "coverage":
                return CoverageCommand.run(arguments: rest)
            case "generate":
#if canImport(CucumberSwiftTestingGenerator)
                return GenerateCommand.run(arguments: rest)
#else
                return needsSwift61("generate")
#endif
            case "lint":
                return LintCommand.lint(arguments: rest)
            case "fix-feature-files":
                return LintCommand.fixFeatureFiles(paths: rest)
            case "convert-to-gherkin-macros":
#if canImport(CucumberSwiftMacroConverterTool)
                return ConvertCommand.run(arguments: rest)
#else
                return needsSwift61("convert-to-gherkin-macros")
#endif
            case "-h", "--help":
                print(usage)
                return 0
            case nil:
                print(usage)
                return 2
            default:
                FileHandle.standardError.write(Data("error: unknown command \(arguments[0])\n".utf8))
                print(usage)
                return 2
        }
    }

    private static func needsSwift61(_ command: String) -> Int32 {
        FileHandle.standardError.write(Data("error: \(command) needs Swift 6.1 or later (Xcode 16.3 or later)\n".utf8))
        return 2
    }
}
