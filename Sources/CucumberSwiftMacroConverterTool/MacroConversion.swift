//
//  MacroConversion.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import Foundation

/// Converts the Swift files in the folders and files it is given, and reports what it did.
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
        // A project that isn't set up for the macros: change nothing, and say how to set it up.
        if !options.missingMacrosProducts.isEmpty {
            output(SetupAdvice.missingProductsMessage(options.missingMacrosProducts, root: options.root))
            return Self.setupStatus
        }
        var tally = Tally()
        let files = swiftFiles(in: options.paths, tally: &tally, output: output, fileManager: fileManager)
        for file in files {
            convert(file: file, dryRun: options.dryRun, tally: &tally, output: output)
        }
        output(summary(of: tally, fileCount: files.count, dryRun: options.dryRun))
        return tally.failed ? 1 : 0
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
