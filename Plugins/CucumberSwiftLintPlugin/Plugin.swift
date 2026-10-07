import Foundation
import PackagePlugin

/// Checks the target's `.feature` files on every build, and reports each problem as a warning on
/// the line it was found on, in Xcode's issue navigator and in the editor.
@main
struct CucumberSwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        return try lintCommands(tool: context.tool(named: "CucumberSwiftLintTool").url,
                                workDirectory: context.pluginWorkDirectoryURL,
                                targetName: target.name,
                                paths: target.sourceFiles.map(\.url.path) + [directoryPath(of: target)].compactMap { $0 })
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CucumberSwiftLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        try lintCommands(tool: context.tool(named: "CucumberSwiftLintTool").url,
                         workDirectory: context.pluginWorkDirectoryURL,
                         targetName: target.displayName,
                         paths: target.inputFiles.map(\.url.path))
    }
}
#endif

/// Feature files are usually a copied resource folder, so the plugin is given the folder, not
/// the files in it. Expand folders to the `.feature` and `.swift` files inside them.
private func lintCommands(tool: URL, workDirectory: URL, targetName: String, paths: [String]) throws -> [Command] {
    var features = Set<String>()
    var swiftFiles = Set<String>()
    for input in paths {
        for path in expand(input) {
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
    let stamp = workDirectory.appendingPathComponent("\(targetName).lint-stamp")
    return [
        .buildCommand(displayName: "Checking feature files in \(targetName)",
                      executable: tool,
                      arguments: ["--stamp", stamp.path, "--features"] + sortedFeatures
                        + ["--step-definitions"] + sortedSwiftFiles,
                      inputFiles: (sortedFeatures + sortedSwiftFiles).map { URL(fileURLWithPath: $0) },
                      outputFiles: [stamp])
    ]
}

/// The target's folder. Swift 6.1 added `directoryURL` to `Target`. Swift 6.0 reads Package.swift,
/// whose tools version 6.0 has it only on each kind of target, and deprecates `Path`; Swift 6.1 and
/// later read Package@swift-6.1.swift.
private func directoryPath(of target: any SourceModuleTarget) -> String? {
#if compiler(>=6.1)
    return target.directoryURL.path
#else
    switch target {
        case let target as SwiftSourceModuleTarget: return target.directoryURL.path
        case let target as ClangSourceModuleTarget: return target.directoryURL.path
        default: return nil
    }
#endif
}
