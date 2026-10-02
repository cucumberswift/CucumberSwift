import Foundation

// Run by the CucumberSwiftLint build tool plugin:
//   CucumberSwiftLintTool --stamp <file> --features <file>… --step-definitions <file>…
// Prints each problem as `file:line:column: warning: message`, which Xcode and SwiftPM show as a
// warning on that line. Always exits 0, so a problem never fails the build.

let arguments = Arguments(CommandLine.arguments.dropFirst())
let diagnostics = Linter.check(features: arguments.features, stepDefinitionFiles: arguments.swiftFiles)
for diagnostic in diagnostics {
    print(diagnostic)
}
if let stamp = arguments.stamp {
    FileManager.default.createFile(atPath: stamp, contents: Data("\(diagnostics.count)\n".utf8))
}
