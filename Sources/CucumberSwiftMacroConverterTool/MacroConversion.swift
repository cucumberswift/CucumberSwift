//
//  MacroConversion.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import Foundation

/// Converts the Swift files in the folders and files it is given, and reports what it did.
public enum MacroConversion {
    /// Returns the tool's exit status: 0 when every file could be read and saved, 1 otherwise.
    public static func run(arguments: [String],
                           output: (String) -> Void = { print($0) },
                           fileManager: FileManager = .default) -> Int32 {
        if arguments == ["--stdin"] { return convertStandardInput() }
        let dryRun = arguments.contains("--dry-run")
        let paths = arguments.filter { $0 != "--dry-run" }
        var failed = false
        var files = [String]()
        for path in paths {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
                output("\(path): no such file or folder")
                failed = true
                continue
            }
            files += isDirectory.boolValue ? swiftFiles(in: path, fileManager: fileManager) : [path]
        }
        files = Array(Set(files)).sorted()

        var totalConverted = 0
        var totalLeft = 0
        var totalMarked = 0
        var changedFiles = 0
        for file in files {
            guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
                output("\(file): can't be read")
                failed = true
                continue
            }
            let result = StepDefinitionConverter.convert(source)
            for entry in (result.converted + result.leftUnchanged).sorted(by: { $0.line < $1.line }) {
                output(entry.reason.map { "\(file):\(entry.line): left unchanged \(entry.stepDefinition): \($0)" }
                    ?? "\(file):\(entry.line): converted \(entry.stepDefinition)")
            }
            totalConverted += result.converted.count
            totalLeft += result.leftUnchanged.count
            guard result.source != source else { continue }
            totalMarked += Self.markers(in: result.source) - Self.markers(in: source)
            changedFiles += 1
            if !dryRun {
                do {
                    try result.source.write(toFile: file, atomically: true, encoding: .utf8)
                } catch {
                    output("\(file): can't be saved: \(error.localizedDescription)")
                    failed = true
                }
            }
        }
        let verb = dryRun ? "Would convert" : "Converted"
        let marked = totalMarked == 0 ? "" : ", \(totalMarked) \(dryRun ? "to mark" : "marked") with #warning"
        output("\(verb) \(totalConverted) step definition\(totalConverted == 1 ? "" : "s") in \(changedFiles) of \(files.count) Swift file\(files.count == 1 ? "" : "s"). "
            + "Left \(totalLeft) unchanged\(marked).")
        return failed ? 1 : 0
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
