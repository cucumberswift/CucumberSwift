import Foundation

// Run by the CucumberSwiftLint build tool plugin:
//   CucumberSwiftLintTool --stamp <file> --features <file>… --step-definitions <file>…
// Prints each problem as `file:line:column: warning: message`, which Xcode and SwiftPM show as a
// warning on that line. Always exits 0, so a problem never fails the build.
//
// Run by the Fix Feature Files command plugin:
//   CucumberSwiftLintTool --fix <file or folder>…
// Applies each "Did you mean" suggestion to the feature files, and prints each line it changed.
// Exits 1 if a fixed file can't be saved.

let arguments = Arguments(CommandLine.arguments.dropFirst())
if arguments.fix {
    let outcome = FeatureFixer.fix(paths: arguments.fixPaths)
    let (files, changes, failures) = (outcome.files, outcome.changes, outcome.failures)
    for change in changes {
        print(change)
    }
    for failure in failures {
        FileHandle.standardError.write(Data("\(failure)\n".utf8))
    }
    let fixedFiles = Set(changes.map(\.file)).count
    if failures.isEmpty || !changes.isEmpty {
        print(changes.isEmpty
            ? "Nothing to fix in \(files.count) feature file\(files.count == 1 ? "" : "s")."
            : "Fixed \(changes.count) line\(changes.count == 1 ? "" : "s") in \(fixedFiles) of \(files.count) feature file\(files.count == 1 ? "" : "s").")
    }
    // Fail, so the plugin fails too, rather than report success while a file is unfixed.
    if !failures.isEmpty { exit(1) }
} else {
    let diagnostics = Linter.check(features: arguments.features, stepDefinitionFiles: arguments.swiftFiles)
    for diagnostic in diagnostics {
        print(diagnostic)
    }
    if let stamp = arguments.stamp {
        FileManager.default.createFile(atPath: stamp, contents: Data("\(diagnostics.count)\n".utf8))
    }
}
