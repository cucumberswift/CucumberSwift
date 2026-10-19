import Foundation
import PackagePlugin

/// Generates a Swift Testing test for each scenario in the target's `.feature` files, on every build
/// that changes one, and one for the features written in the Swift DSL. The tests run the scenarios with
/// CucumberSwiftTesting.
@main
struct CucumberSwiftTestingPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        return try generateCommands(tool: context.tool(named: "CucumberSwiftTestingGenerator").url,
                                    workDirectory: context.pluginWorkDirectoryURL,
                                    targetName: target.name,
                                    paths: target.sourceFiles.map(\.url.path) + [target.directoryURL.path])
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CucumberSwiftTestingPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        try generateCommands(tool: context.tool(named: "CucumberSwiftTestingGenerator").url,
                             workDirectory: context.pluginWorkDirectoryURL,
                             targetName: target.displayName,
                             paths: target.inputFiles.map(\.url.path))
    }
}
#endif

/// One command, which writes the tests for every `.feature` file in or under `paths`, and the test for the
/// features the target's Swift files write in the Swift DSL, if they write any. A target with neither gets none.
private func generateCommands(tool: URL, workDirectory: URL, targetName: String, paths: [String]) -> [Command] {
    let files = Set(paths.flatMap(expand))
    let features = files.filter { $0.hasSuffix(".feature") }.sorted()
    let swiftFiles = files.filter { $0.hasSuffix(".swift") }.sorted()
    guard !features.isEmpty || !swiftFiles.isEmpty else { return [] }
    let output = workDirectory.appendingPathComponent("CucumberFeatures.swift")
    return [
        .buildCommand(displayName: "Generating Swift Testing tests for the feature files in \(targetName)",
                      executable: tool,
                      arguments: ["--output", output.path] + features + swiftFiles.flatMap { ["--swift", $0] },
                      inputFiles: (features + swiftFiles).map { URL(fileURLWithPath: $0) },
                      outputFiles: [output])
    ]
}
