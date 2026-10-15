import Foundation
import PackagePlugin

private enum ConvertError: Error, CustomStringConvertible {
    case unknownTargets([String])
    case notSetUp(String)
    case failed(Int32)
    case missingValue(String)

    var description: String {
        switch self {
            case .unknownTargets(let names): return "No target named \(names.joined(separator: ", "))"
            case .notSetUp(let message): return message
            case .failed(let status): return "CucumberSwiftMacroConverterTool exited with status \(status)"
            case .missingValue(let option): return "\(option) needs a value: \(option == "--path" ? "the file or folder to convert" : "the name of a target")"
        }
    }
}

/// What the tool printed, collected while it ran, so the plugin can show it as one piece in order.
private final class Output: @unchecked Sendable {
    var data = Data()
}

/// Rewrites the step definitions that a step definition macro can replace exactly, marks the ones it leaves
/// with a `#warning`, and lists them all with the reason. `--dry-run` reports without changing a file.
/// `--target` and `--path` (each repeatable) limit it: `--path` alone to those files and folders, `--target`
/// alone to those targets, both to the files under the paths that belong to the targets (Xcode always passes
/// the targets chosen in its dialog, so its Arguments field can only narrow them); with neither, every target.
@main
struct ConvertToGherkinMacrosPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        try requireValues(in: arguments)
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let chosen = extractor.extractOption(named: "path")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let unknown = names.filter { name in !context.package.targets.contains { $0.name == name } }
        guard unknown.isEmpty else { throw ConvertError.unknownTargets(unknown) }
        let root = context.package.directoryURL
        let chosenURLs = chosen.map { resolve($0, in: root) }
        // The targets named, or every target when there is neither option: converted whole, or narrowed by `--path`.
        let converted = context.package.targets.filter { names.isEmpty && chosen.isEmpty || names.contains($0.name) }
        // With `--path` alone, the targets that own a chosen file or folder, which need the macros too.
        let targets = names.isEmpty && !chosen.isEmpty
            ? context.package.targets.filter { target in
                guard let module = target as? SourceModuleTarget else { return false }
                return overlaps(chosenURLs, [module.directoryURL])
            }
            : converted
        let missing = targets.compactMap { target -> String? in
            let products = target.dependencies.compactMap { dependency -> String? in
                if case .product(let product) = dependency { return product.name }
                return nil
            }
            return missingMacrosProduct(forDependencies: products).map { "\(target.name)=\($0)" }
        }
        try convert(tool: context.tool(named: "CucumberSwiftMacroConverterTool").url,
                    root: root,
                    paths: converted.compactMap { ($0 as? SourceModuleTarget)?.directoryURL },
                    chosen: chosen,
                    missing: missing,
                    dryRun: dryRun)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ConvertToGherkinMacrosPlugin: XcodeCommandPlugin {
    // Xcode passes `--target` for each target chosen in its dialog, and what is typed in its Arguments list, so
    // `--path` there narrows the chosen targets.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        try requireValues(in: arguments)
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let chosen = extractor.extractOption(named: "path")
        let dryRun = extractor.extractFlag(named: "dry-run") > 0
        let unknown = names.filter { name in !context.xcodeProject.targets.contains { $0.displayName == name } }
        guard unknown.isEmpty else { throw ConvertError.unknownTargets(unknown) }
        let root = context.xcodeProject.directoryURL
        let chosenURLs = chosen.map { resolve($0, in: root) }
        let converted = context.xcodeProject.targets.filter { names.isEmpty && chosen.isEmpty || names.contains($0.displayName) }
        let targets = names.isEmpty && !chosen.isEmpty
            ? context.xcodeProject.targets.filter { target in
                overlaps(chosenURLs, target.inputFiles.map(\.url))
            }
            : converted
        let missing = targets.compactMap { target -> String? in
            let products = target.dependencies.compactMap { dependency -> String? in
                if case .product(let product) = dependency { return product.name }
                return nil
            }
            return missingMacrosProduct(forDependencies: products).map { "\(target.displayName)=\($0)" }
        }
        try convert(tool: context.tool(named: "CucumberSwiftMacroConverterTool").url,
                    root: root,
                    paths: converted.flatMap { $0.inputFiles.map(\.url) },
                    chosen: chosen,
                    missing: missing,
                    dryRun: dryRun)
    }
}
#endif

/// The macros product a target needs and doesn't depend on, when it uses the CucumberSwift runner or the
/// Swift Testing runner without it.
private func missingMacrosProduct(forDependencies products: [String]) -> String? {
    if products.contains("CucumberSwift"), !products.contains("CucumberSwiftMacros") { return "CucumberSwiftMacros" }
    if products.contains("CucumberSwiftTesting"), !products.contains("CucumberSwiftTestingMacros") { return "CucumberSwiftTestingMacros" }
    return nil
}

/// Throws when `--target` or `--path` has no value, as at the end of the arguments or before another option:
/// the argument extractor drops it without a word, and the command would then convert more than was asked.
private func requireValues(in arguments: [String]) throws {
    for option in ["--target", "--path"] {
        for (index, argument) in arguments.enumerated() where argument == option {
            let value = arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
            if value == nil || value?.hasPrefix("--") == true { throw ConvertError.missingValue(option) }
        }
    }
}

/// `path` as the tool reads it: relative to the package or project folder, with `..` and links resolved.
private func resolve(_ path: String, in root: URL) -> URL {
    URL(fileURLWithPath: path, relativeTo: root).standardizedFileURL.resolvingSymlinksInPath()
}

/// Whether any chosen location overlaps any of a target's locations: see `overlap`.
private func overlaps(_ chosen: [URL], _ locations: [URL]) -> Bool {
    chosen.contains { path in locations.contains { overlap(path, $0) } }
}

/// Whether one location is, or is inside, the other: a chosen folder holds a target's files, and a chosen file
/// is inside its target's folder.
private func overlap(_ first: URL, _ second: URL) -> Bool {
    let first = first.resolvingSymlinksInPath().path
    let second = second.resolvingSymlinksInPath().path
    return first == second || first.hasPrefix(second + "/") || second.hasPrefix(first + "/")
}

/// Swift files and folders, as the tool takes them: it finds the Swift files in each folder, and checks each
/// `--path` is inside `root`, naming the ones that aren't. The tool says first, and changes nothing, when the
/// project isn't set up for the macros: its message is then the error.
private func convert(tool: URL, root: URL, paths: [URL], chosen: [String], missing: [String], dryRun: Bool) throws {
    let files = Set(paths.map(\.path)).sorted().filter { path in
        var isDirectory: ObjCBool = false
        return path.hasSuffix(".swift")
            || (FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }
    let process = Process()
    process.executableURL = tool
    process.arguments = ["--root", root.path] + missing.flatMap { ["--missing-macros", $0] }
        + chosen.flatMap { ["--path", $0] } + (dryRun ? ["--dry-run"] : []) + files
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardOutput = standardOutput
    process.standardError = standardError
    try process.run()
    // Read both pipes at the same time, so a long report can't fill one while this waits for the other.
    let errors = Output()
    let reading = DispatchGroup()
    reading.enter()
    DispatchQueue.global().async {
        errors.data = standardError.fileHandleForReading.readDataToEndOfFile()
        reading.leave()
    }
    let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
    reading.wait()
    process.waitUntilExit()
    let text = String(bytes: output + errors.data, encoding: .utf8) ?? ""
    // 2 is the tool's status for a project that isn't set up: what it printed says how to set it up.
    guard process.terminationStatus != 2 else { throw ConvertError.notSetUp(text.trimmingCharacters(in: .whitespacesAndNewlines)) }
    print(text, terminator: "")
    guard process.terminationStatus == 0 else { throw ConvertError.failed(process.terminationStatus) }
}
