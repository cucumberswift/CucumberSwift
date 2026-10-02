import Foundation

// Run by the CucumberSwiftLint build tool plugin:
//   CucumberSwiftLintTool --stamp <file> --features <file>… --step-definitions <file>…
// Prints each problem as `file:line:column: warning: message`, which Xcode and SwiftPM show as a
// warning on that line. Always exits 0, so a problem never fails the build.
//
// Run by the Fix Feature Files command plugin:
//   CucumberSwiftLintTool --fix <file or folder>…
// Applies each "Did you mean" suggestion to the feature files, and prints each line it changed.
// Exits 1 if a path or a feature file can't be checked or fixed.

let arguments = Arguments(CommandLine.arguments.dropFirst())
if arguments.fix {
    let status = FeatureFixer.run(
        paths: arguments.fixPaths,
        output: { print($0) },
        errorOutput: { FileHandle.standardError.write(Data("\($0)\n".utf8)) })
    exit(status)
} else {
    let diagnostics = Linter.check(features: arguments.features, stepDefinitionFiles: arguments.swiftFiles)
    for diagnostic in diagnostics {
        print(diagnostic)
    }
    if let stamp = arguments.stamp {
        FileManager.default.createFile(atPath: stamp, contents: Data("\(diagnostics.count)\n".utf8))
    }
}
