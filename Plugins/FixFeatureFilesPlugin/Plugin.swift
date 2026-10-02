import Foundation
import PackagePlugin

private enum FixError: Error, CustomStringConvertible {
    case unknownTargets([String])
    case failed(Int32)

    var description: String {
        switch self {
            case .unknownTargets(let names): return "No target named \(names.joined(separator: ", "))"
            case .failed(let status): return "CucumberSwiftLintTool exited with status \(status)"
        }
    }
}

/// Fixes the misspelt keywords that the CucumberSwiftLint plugin reports in feature files, by
/// applying each of its "Did you mean" suggestions, and prints each line it changed.
@main
struct FixFeatureFilesPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let unknown = names.filter { name in !context.package.targets.contains { $0.name == name } }
        guard unknown.isEmpty else { throw FixError.unknownTargets(unknown) }
        let targets = context.package.targets.filter { names.isEmpty || names.contains($0.name) }
        try fix(tool: context.tool(named: "CucumberSwiftLintTool").path,
                paths: targets.compactMap { ($0 as? SourceModuleTarget)?.directory })
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FixFeatureFilesPlugin: XcodeCommandPlugin {
    // Xcode passes `--target` for each target chosen when the command is run.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let unknown = names.filter { name in !context.xcodeProject.targets.contains { $0.displayName == name } }
        guard unknown.isEmpty else { throw FixError.unknownTargets(unknown) }
        let targets = context.xcodeProject.targets.filter { names.isEmpty || names.contains($0.displayName) }
        try fix(tool: context.tool(named: "CucumberSwiftLintTool").path,
                paths: targets.flatMap { $0.inputFiles.map(\.path) })
    }
}
#endif

/// Feature files are usually in a copied resource folder, so pass folders as well as `.feature`
/// files. The tool finds the feature files in each folder, and prints what it changes.
private func fix(tool: Path, paths: [Path]) throws {
    let candidates = Set(paths.map(\.string)).sorted().filter { path in
        var isDirectory: ObjCBool = false
        return path.hasSuffix(".feature")
            || (FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: tool.string)
    process.arguments = ["--fix"] + candidates
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw FixError.failed(process.terminationStatus) }
}
