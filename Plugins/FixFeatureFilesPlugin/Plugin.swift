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
        try fix(tool: context.tool(named: "CucumberSwiftLintTool").url,
                paths: targets.compactMap { ($0 as? SourceModuleTarget).flatMap(directoryPath) })
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
        try fix(tool: context.tool(named: "CucumberSwiftLintTool").url,
                paths: targets.flatMap { $0.inputFiles.map(\.url.path) })
    }
}
#endif

/// Feature files are usually in a copied resource folder, so pass folders as well as `.feature`
/// files. The tool finds the feature files in each folder, and prints what it changes.
private func fix(tool: URL, paths: [String]) throws {
    let candidates = Set(paths).sorted().filter { path in
        var isDirectory: ObjCBool = false
        return path.hasSuffix(".feature")
            || (FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }
    let process = Process()
    process.executableURL = tool
    process.arguments = ["--fix"] + candidates
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw FixError.failed(process.terminationStatus) }
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
