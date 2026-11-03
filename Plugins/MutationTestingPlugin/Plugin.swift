import Foundation
import PackagePlugin

private enum MutationError: Error, CustomStringConvertible {
    case unknownTargets([String])
    case noTargets
    case failed(Int32)
    case notSetUp
    case missingValue(String)

    var description: String {
        switch self {
            case .unknownTargets(let names): return "No target named \(names.joined(separator: ", "))"
            case .noTargets: return "The package has no target with code to mutate"
            case .failed(let status): return "CucumberSwiftMutationTestingTool exited with status \(status)"
            case .notSetUp: return "Mutation testing needs CucumberSwift's Macros package trait, which brings in swift-syntax. Turn it on and run the command again."
            case .missingValue(let option): return "\(option) needs a value"
        }
    }
}

/// Changes the code under test in a temporary copy of the package, runs the package's tests against each
/// change, and reports the changes that no test noticed. The package itself is never changed.
///
/// `--target` (repeatable) limits it to the code of those targets. `--dry-run` lists the changes without
/// testing them. `--max-mutants`, `--timeout-multiplier`, `--baseline-runs` and `--work-dir` tune the run;
/// the reports go to the plugin's folder in the package's `.build`, or to `--output`.
@main
struct MutationTestingPlugin: CommandPlugin {
    private static let valueOptions = ["max-mutants", "timeout-multiplier", "minimum-timeout", "baseline-runs", "work-dir", "output"]

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        for option in Self.valueOptions + ["target"] {
            for (index, argument) in arguments.enumerated() where argument == "--\(option)" {
                let value = arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
                if value == nil || value?.hasPrefix("--") == true { throw MutationError.missingValue("--\(option)") }
            }
        }
        let names = extractor.extractOption(named: "target")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let passed = Self.valueOptions.flatMap { option in
            extractor.extractOption(named: option).flatMap { ["--\(option)", $0] }
        }
        let modules = context.package.targets.compactMap { $0 as? SourceModuleTarget }.filter { $0.kind != .test }
        let unknown = names.filter { name in !modules.contains { $0.name == name } }
        guard unknown.isEmpty else { throw MutationError.unknownTargets(unknown) }
        let chosen = modules.filter { names.isEmpty || names.contains($0.name) }
        guard !chosen.isEmpty else { throw MutationError.noTargets }
        let root = context.package.directoryURL.resolvingSymlinksInPath()
        let sources = chosen.map { target -> String in
            let path = target.directoryURL.resolvingSymlinksInPath().path
            return path.hasPrefix(root.path + "/") ? String(path.dropFirst(root.path.count + 1)) : path
        }
        // The plugin's own folder is writable without asking, and it is in the package's .build folder, which git ignores.
        // The reports go there unless the user chose a place. The copy does not: that folder's path has a space in it
        // ("Mutation Testing"), and Swift Testing finds no tests in a package whose path has one. The tool picks a
        // folder for the copy itself.
        var defaults = [String]()
        if !passed.contains("--output") { defaults += ["--output", context.pluginWorkDirectoryURL.appending(path: "reports").path] }
        let process = Process()
        process.executableURL = try context.tool(named: "CucumberSwiftMutationTestingTool").url
        process.arguments = ["--root", root.path] + sources.flatMap { ["--sources", $0] } + defaults + passed + (dryRun ? ["--dry-run"] : []) + ["--disable-prebuilts"]
        // The tool writes to the plugin's own output, so a long run shows its progress as it goes.
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus != 2 else { throw MutationError.notSetUp }
        guard process.terminationStatus == 0 else { throw MutationError.failed(process.terminationStatus) }
    }
}
