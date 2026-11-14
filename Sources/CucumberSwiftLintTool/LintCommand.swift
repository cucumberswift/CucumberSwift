import Foundation

/// `cucumberswift lint --stamp <file> --features <file>… --step-definitions <file>…`, which the
/// CucumberSwiftLint build tool plugin runs. It prints each problem as `file:line:column: warning: message`,
/// which Xcode and SwiftPM show as a warning on that line, and returns 0, so a warning never fails the build.
/// A step of the Swift DSL written where a step definition belongs, or the other way round, is an `error:`,
/// and the command then returns 1, which fails it.
///
/// `cucumberswift fix-feature-files <file or folder>…`, which the Fix Feature Files command plugin runs,
/// applies each "Did you mean" suggestion to the feature files, and prints each line it changed. It returns 1
/// if a path or a feature file can't be checked or fixed.
public enum LintCommand {
    /// `cucumberswift lint`: the arguments that follow `lint`.
    public static func lint(arguments: [String]) -> Int32 {
        let arguments = Arguments(arguments)
        let diagnostics = Linter.check(features: arguments.features, stepDefinitionFiles: arguments.swiftFiles)
        for diagnostic in diagnostics {
            print(diagnostic)
        }
        if let stamp = arguments.stamp {
            FileManager.default.createFile(atPath: stamp, contents: Data("\(diagnostics.count)\n".utf8))
        }
        return diagnostics.contains { $0.severity == .error } ? 1 : 0
    }

    /// `cucumberswift fix-feature-files`: the files and folders that follow it.
    public static func fixFeatureFiles(paths: [String]) -> Int32 {
        FeatureFixer.run(
            paths: paths,
            output: { print($0) },
            errorOutput: { FileHandle.standardError.write(Data("\($0)\n".utf8)) })
    }
}
