//
//  MacroConversion.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import Foundation

/// Converts the Swift files in the folders and files it is given, and reports what it did. `--path` is the
/// files and folders the user chose, inside the project at `--root`: with folders and files given as well (a
/// target's), only the chosen ones that belong to them are converted.
public enum MacroConversion {
    /// What a run did, file by file.
    private struct Tally {
        var converted = 0
        var left = 0
        var marked = 0
        var changedFiles = 0
        var failed = false
    }

    /// The exit status when the project isn't set up for the macros, and nothing was changed.
    static let setupStatus: Int32 = 2

    /// Returns the tool's exit status: 0 when every file could be read and saved, 1 when one couldn't, and
    /// `setupStatus` when the project isn't set up for the macros.
    public static func run(arguments: [String],
                           output: (String) -> Void = { print($0) },
                           fileManager: FileManager = .default) -> Int32 {
        if arguments == ["--stdin"] { return convertStandardInput() }
        // What the command says with the trait off, for the tests, which can't run a tool built without it.
        if arguments.count == 2, arguments[0] == "--explain-setup" {
            output(SetupAdvice.traitOffMessage(root: arguments[1]))
            return 0
        }
        let options = ConversionOptions(arguments)
        // An option with no value would otherwise widen the run: say so, and change nothing.
        guard options.problems.isEmpty else {
            options.problems.forEach(output)
            return 1
        }
        // A project that isn't set up for the macros: change nothing, and say how to set it up.
        if !options.missingMacrosProducts.isEmpty {
            output(SetupAdvice.missingProductsMessage(options.missingMacrosProducts, root: options.root))
            return Self.setupStatus
        }
        var tally = Tally()
        // Each `--path` is checked before any file changes, so a typo can't leave a half-converted project.
        guard let chosen = resolve(chosenPaths: options.chosenPaths, root: options.root, output: output, fileManager: fileManager) else {
            return 1
        }
        let given = swiftFiles(in: options.paths, tally: &tally, output: output, fileManager: fileManager)
        let files: [String]
        if chosen.isEmpty {
            files = given
        } else if options.paths.isEmpty {
            // A chosen folder with no Swift files has nothing to convert: that is a mistake, not a success.
            guard let within = swiftFilesOfEach(chosen, choices: options.chosenPaths, output: output, fileManager: fileManager) else {
                return 1
            }
            files = within
        } else {
            // Targets and paths together: the files under the paths that belong to the targets.
            guard let within = filesUnder(chosen, among: given, choices: options.chosenPaths, output: output) else { return 1 }
            files = within
        }
        for file in files {
            convert(file: file, dryRun: options.dryRun, tally: &tally, output: output)
        }
        output(summary(of: tally, fileCount: files.count, dryRun: options.dryRun))
        return tally.failed ? 1 : 0
    }

    /// The Swift files in each of `paths`, once each, or `nil` after saying which path has none.
    private static func swiftFilesOfEach(_ paths: [String],
                                         choices: [String],
                                         output: (String) -> Void,
                                         fileManager: FileManager) -> [String]? {
        var found = [String]()
        var valid = true
        for (index, path) in paths.enumerated() {
            var isDirectory: ObjCBool = false
            _ = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            let inside = isDirectory.boolValue ? swiftFiles(in: path, fileManager: fileManager) : [path]
            if inside.isEmpty {
                output("\(choices[index]): has no Swift files")
                valid = false
            }
            found += inside
        }
        return valid ? Array(Set(found)).sorted() : nil
    }

    /// The `files` that are one of `paths` or under one, or `nil` after saying which path has none of them: it
    /// names nothing in the targets chosen, and the run changes nothing.
    private static func filesUnder(_ paths: [String],
                                   among files: [String],
                                   choices: [String],
                                   output: (String) -> Void) -> [String]? {
        func resolved(_ file: String) -> String { URL(fileURLWithPath: file).resolvingSymlinksInPath().path }
        let known = files.map { (file: $0, resolved: resolved($0)) }
        var valid = true
        for (index, path) in paths.enumerated()
        where !known.contains(where: { $0.resolved == path || $0.resolved.hasPrefix(path + "/") }) {
            output("\(choices[index]): has no Swift files in the targets chosen")
            valid = false
        }
        guard valid else { return nil }
        return known.filter { entry in paths.contains { entry.resolved == $0 || entry.resolved.hasPrefix($0 + "/") } }.map(\.file)
    }

    /// The absolute paths of what `--path` named, or `nil` after saying which of them is wrong: a path that
    /// isn't there, isn't a folder or a Swift file, or is outside `root`, the package or project.
    private static func resolve(chosenPaths: [String],
                                root: String?,
                                output: (String) -> Void,
                                fileManager: FileManager) -> [String]? {
        let base = URL(fileURLWithPath: root ?? fileManager.currentDirectoryPath).resolvingSymlinksInPath()
        var resolved = [String]()
        var valid = true
        for path in chosenPaths {
            let url = URL(fileURLWithPath: path, relativeTo: base).standardizedFileURL.resolvingSymlinksInPath()
            var isDirectory: ObjCBool = false
            if root != nil, url.path != base.path, !url.path.hasPrefix(base.path + "/") {
                output("\(path): is outside the package or project at \(base.path)")
                valid = false
            } else if !fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                output("\(path): no such file or folder")
                valid = false
            } else if !isDirectory.boolValue, url.pathExtension != "swift" {
                output("\(path): is not a Swift file or a folder")
                valid = false
            } else {
                resolved.append(url.path)
            }
        }
        return valid ? resolved : nil
    }

    /// The Swift files in the files and folders given, once each, in order. A path that isn't there fails the run.
    private static func swiftFiles(in paths: [String],
                                   tally: inout Tally,
                                   output: (String) -> Void,
                                   fileManager: FileManager) -> [String] {
        var files = [String]()
        for path in paths {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
                output("\(path): no such file or folder")
                tally.failed = true
                continue
            }
            files += isDirectory.boolValue ? swiftFiles(in: path, fileManager: fileManager) : [path]
        }
        return Array(Set(files)).sorted()
    }

    /// Converts one file, reports each of its step definitions, and saves it when it changed and this isn't a dry run.
    private static func convert(file: String, dryRun: Bool, tally: inout Tally, output: (String) -> Void) {
        guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
            output("\(file): can't be read")
            tally.failed = true
            return
        }
        let result = StepDefinitionConverter.convert(source)
        for entry in (result.converted + result.leftUnchanged).sorted(by: { $0.line < $1.line }) {
            output(entry.reason.map { "\(file):\(entry.line): left unchanged \(entry.stepDefinition): \($0)" }
                ?? "\(file):\(entry.line): converted \(entry.stepDefinition)")
        }
        tally.converted += result.converted.count
        tally.left += result.leftUnchanged.count
        guard result.source != source else { return }
        tally.marked += markers(in: result.source) - markers(in: source)
        tally.changedFiles += 1
        guard !dryRun else { return }
        do {
            try result.source.write(toFile: file, atomically: true, encoding: .utf8)
        } catch {
            output("\(file): can't be saved: \(error.localizedDescription)")
            tally.failed = true
        }
    }

    private static func summary(of tally: Tally, fileCount: Int, dryRun: Bool) -> String {
        let verb = dryRun ? "Would convert" : "Converted"
        let marked = tally.marked == 0 ? "" : ", \(tally.marked) \(dryRun ? "to mark" : "marked") with #warning"
        return "\(verb) \(tally.converted) step definition\(tally.converted == 1 ? "" : "s") "
            + "in \(tally.changedFiles) of \(fileCount) Swift file\(fileCount == 1 ? "" : "s"). "
            + "Left \(tally.left) unchanged\(marked)."
    }

    private static func markers(in source: String) -> Int {
        source.components(separatedBy: Rewriter.markerPrefix).count - 1
    }

    /// Reads one file's source from standard input, writes the converted source to standard output and the
    /// report to standard error, one line for each step definition: `<line>: converted <step definition>`
    /// or `<line>: left unchanged <step definition>: <reason>`. For tests, which run the tool as a program.
    private static func convertStandardInput() -> Int32 {
        let source = String(bytes: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let result = StepDefinitionConverter.convert(source)
        let report = (result.converted + result.leftUnchanged).sorted { $0.line < $1.line }.map { entry in
            entry.reason.map { "\(entry.line): left unchanged \(entry.stepDefinition): \($0)" }
                ?? "\(entry.line): converted \(entry.stepDefinition)"
        }
        FileHandle.standardOutput.write(Data(result.source.utf8))
        FileHandle.standardError.write(Data((report.joined(separator: "\n") + "\n").utf8))
        return 0
    }

    private static func swiftFiles(in folder: String, fileManager: FileManager) -> [String] {
        guard let enumerator = fileManager.enumerator(atPath: folder) else { return [] }
        let skipped: Set<String> = [".build", ".git", "Pods", "Carthage", "DerivedData", "node_modules"]
        var files = [String]()
        for case let relative as String in enumerator {
            if relative.split(separator: "/").contains(where: { skipped.contains(String($0)) }) {
                continue
            }
            if relative.hasSuffix(".swift") { files.append(URL(fileURLWithPath: folder).appendingPathComponent(relative).path) }
        }
        return files
    }
}
#endif
