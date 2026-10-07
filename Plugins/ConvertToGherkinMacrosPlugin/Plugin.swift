import Foundation
import PackagePlugin

private enum ConvertError: Error, CustomStringConvertible {
    case unknownTargets([String])
    case failed(Int32)

    var description: String {
        switch self {
            case .unknownTargets(let names): return "No target named \(names.joined(separator: ", "))"
            case .failed(let status): return "CucumberSwiftMacroConverterTool exited with status \(status)"
        }
    }
}

/// Rewrites the step definitions that a step definition macro can replace exactly, and lists the ones it
/// leaves unchanged with the reason. `--dry-run` reports without changing a file.
@main
struct ConvertToGherkinMacrosPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let unknown = names.filter { name in !context.package.targets.contains { $0.name == name } }
        guard unknown.isEmpty else { throw ConvertError.unknownTargets(unknown) }
        let targets = context.package.targets.filter { names.isEmpty || names.contains($0.name) }
        try convert(tool: context.tool(named: "CucumberSwiftMacroConverterTool").url,
                    paths: targets.compactMap { ($0 as? SourceModuleTarget)?.directoryURL },
                    dryRun: dryRun)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ConvertToGherkinMacrosPlugin: XcodeCommandPlugin {
    // Xcode passes `--target` for each target chosen when the command is run.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let unknown = names.filter { name in !context.xcodeProject.targets.contains { $0.displayName == name } }
        guard unknown.isEmpty else { throw ConvertError.unknownTargets(unknown) }
        let targets = context.xcodeProject.targets.filter { names.isEmpty || names.contains($0.displayName) }
        try convert(tool: context.tool(named: "CucumberSwiftMacroConverterTool").url,
                    paths: targets.flatMap { $0.inputFiles.map(\.url) },
                    dryRun: dryRun)
    }
}
#endif

/// Swift files and folders, as the tool takes them: it finds the Swift files in each folder.
private func convert(tool: URL, paths: [URL], dryRun: Bool) throws {
    let files = Set(paths.map(\.path)).sorted().filter { path in
        var isDirectory: ObjCBool = false
        return path.hasSuffix(".swift")
            || (FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }
    let process = Process()
    process.executableURL = tool
    process.arguments = (dryRun ? ["--dry-run"] : []) + files
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw ConvertError.failed(process.terminationStatus) }
}
