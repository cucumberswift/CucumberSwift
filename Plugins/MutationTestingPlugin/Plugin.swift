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
/// `--target` (repeatable) limits it to the code of those targets. `--tags` chooses the scenarios, as `CUCUMBER_TAGS`
/// does. `--dry-run` lists the changes without
/// testing them. `--max-mutants`, `--timeout-multiplier`, `--baseline-runs` and `--work-dir` tune the run;
/// the reports go to the plugin's folder in the package's `.build`, or to `--output`.
@main
struct MutationTestingPlugin: CommandPlugin {
    private static let valueOptions = ["max-mutants", "timeout-multiplier", "minimum-timeout", "baseline-runs", "work-dir", "output"]

    /// Throws when an option that takes a value has none, as at the end of the arguments or before another option:
    /// the argument extractor drops it without a word.
    private static func requireValues(in arguments: [String]) throws {
        for option in valueOptions + ["target", "tags"] {
            for (index, argument) in arguments.enumerated() where argument == "--\(option)" {
                let value = arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
                if value == nil || value?.hasPrefix("--") == true { throw MutationError.missingValue("--\(option)") }
            }
        }
    }

    /// The source folders of the named targets, or of every target that isn't a test target, relative to `root`. A
    /// named test target is left out, because its code isn't mutated: Xcode names every target of the package, test
    /// targets included, when it runs the command.
    private static func sourceFolders(of package: Package, named names: [String], root: URL) throws -> [String] {
        let unknown = names.filter { name in !package.targets.contains { $0.name == name } }
        guard unknown.isEmpty else { throw MutationError.unknownTargets(unknown) }
        let modules = package.targets.compactMap { $0 as? SourceModuleTarget }.filter { $0.kind != .test }
        let named = names.filter { name in modules.contains { $0.name == name } }
        let chosen = modules.filter { names.isEmpty || named.contains($0.name) }
        guard !chosen.isEmpty else { throw MutationError.noTargets }
        let prefix = root.path + "/"
        return chosen.map { target in
            let path = target.directoryURL.resolvingSymlinksInPath().path
            return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
        }
    }

    /// The folder the reports go to: the value of `--output` when the user passed one, else `fallback`.
    private static func outputFolder(passed: [String], default fallback: URL) -> URL {
        guard let index = passed.firstIndex(of: "--output"), passed.indices.contains(index + 1) else { return fallback }
        return URL(fileURLWithPath: passed[index + 1])
    }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        try Self.requireValues(in: arguments)
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let tags = extractor.extractOption(named: "tags").last
        var passed = [String]()
        for option in Self.valueOptions {
            for value in extractor.extractOption(named: option) { passed += ["--\(option)", value] }
        }
        let root = context.package.directoryURL.resolvingSymlinksInPath()
        let sources = try Self.sourceFolders(of: context.package, named: names, root: root)
        // Built step by step: one long concatenation is too slow for some compilers to type-check.
        var toolArguments: [String] = ["--root", root.path]
        for source in sources { toolArguments += ["--sources", source] }
        // The reports go to .build/mutation-testing in the package, as from the command-line tool, so a test run reads
        // the last report whichever way the command ran. Xcode would put the plugin's own folder in DerivedData. The
        // package's .build folder needs the permission to write to the package, which git ignores.
        let output = Self.outputFolder(passed: passed, default: root.appending(path: ".build/mutation-testing"))
        if !passed.contains("--output") { toolArguments += ["--output", output.path] }
        toolArguments += passed
        if dryRun { toolArguments.append("--dry-run") }
        if let tags { toolArguments += ["--tags", tags] }
        toolArguments.append("--disable-prebuilts")
        let process = Process()
        process.executableURL = try context.tool(named: "CucumberSwiftMutationTestingTool").url
        process.arguments = toolArguments
        // The tool writes to the plugin's own output, so a long run shows its progress as it goes.
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus != 2 else { throw MutationError.notSetUp }
        guard process.terminationStatus == 0 else { throw MutationError.failed(process.terminationStatus) }
        // Each survivor as a warning, which `swift package` prints and Xcode lists at the end of the command's report.
        for warning in SurvivorWarning.read(report: output.appending(path: "mutation-report.json"), root: root) {
            Diagnostics.warning(warning.message, file: warning.file, line: warning.line)
        }
    }
}
