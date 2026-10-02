import Foundation
import PackagePlugin

/// Checks the target's `.feature` files on every build, and reports each problem as a warning on
/// the line it was found on, in Xcode's issue navigator and in the editor.
@main
struct CucumberSwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        return try lintCommands(tool: context.tool(named: "CucumberSwiftLintTool").path,
                                workDirectory: context.pluginWorkDirectory,
                                targetName: target.name,
                                files: target.sourceFiles.map(\.path) + [target.directory])
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CucumberSwiftLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        try lintCommands(tool: context.tool(named: "CucumberSwiftLintTool").path,
                         workDirectory: context.pluginWorkDirectory,
                         targetName: target.displayName,
                         files: target.inputFiles.map(\.path))
    }
}
#endif

/// Feature files are usually a copied resource folder, so the plugin is given the folder, not
/// the files in it. Expand folders to the `.feature` and `.swift` files inside them.
private func lintCommands(tool: Path, workDirectory: Path, targetName: String, files: [Path]) throws -> [Command] {
    var features = Set<String>()
    var swiftFiles = Set<String>()
    for file in files {
        for path in expand(file.string) {
            switch URL(fileURLWithPath: path).pathExtension {
            case "feature": features.insert(path)
            case "swift": swiftFiles.insert(path)
            default: break
            }
        }
    }
    guard !features.isEmpty else { return [] }
    let sortedFeatures = features.sorted()
    let sortedSwiftFiles = swiftFiles.sorted()
    let stamp = workDirectory.appending("\(targetName).lint-stamp")
    return [
        .buildCommand(displayName: "Checking feature files in \(targetName)",
                      executable: tool,
                      arguments: ["--stamp", stamp.string, "--features"] + sortedFeatures
                        + ["--step-definitions"] + sortedSwiftFiles,
                      inputFiles: (sortedFeatures + sortedSwiftFiles).map { Path($0) },
                      outputFiles: [stamp])
    ]
}

private func expand(_ path: String) -> [String] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return [] }
    guard isDirectory.boolValue else { return [path] }
    guard let enumerator = FileManager.default.enumerator(atPath: path) else { return [] }
    return enumerator.compactMap { $0 as? String }
        .filter { !$0.hasPrefix(".build/") && !$0.contains("/.build/") }
        .map { (path as NSString).appendingPathComponent($0) }
}
