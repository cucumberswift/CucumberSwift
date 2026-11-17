//
//  SurvivorWarning.swift
//  CucumberSwiftMutation
//
//  Shared with the Mutation Testing plugin through Plugins/MutationTestingPlugin/SurvivorWarning.swift, a symlink,
//  because a plugin can't import a library. So it uses only Foundation.
//

#if os(macOS) || os(Linux)
import Foundation

/// A surviving mutant, read from the tool's Stryker report, as a warning. The command-line tool prints it in the
/// compiler's format with `--format xcode`, which Xcode shows at its line. The plugin reports it as a diagnostic, which
/// `swift package` prints and Xcode lists at the end of the command's report.
public struct SurvivorWarning: Equatable {
    public let file: String
    public let line: Int
    public let column: Int
    public let message: String

    /// `/path/Basket.swift:22:27: warning: No test failed after …`, the compiler's format.
    public var xcodeLine: String { "\(file):\(line):\(column): warning: \(message)" }

    /// The survivors in the report at `report`, with each file's path made absolute under `root`, in file and line order.
    public static func read(report: URL, root: URL) -> [SurvivorWarning] {
        guard let data = try? Data(contentsOf: report),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: [String: Any]] else { return [] }
        var warnings = [SurvivorWarning]()
        for (path, file) in files.sorted(by: { $0.key < $1.key }) {
            let source = file["source"] as? String ?? ""
            for mutant in file["mutants"] as? [[String: Any]] ?? [] where mutant["status"] as? String == "Survived" {
                if let warning = warning(for: mutant, in: source, file: root.appendingPathComponent(path).path) {
                    warnings.append(warning)
                }
            }
        }
        return warnings.sorted { ($0.file, $0.line, $0.column) < ($1.file, $1.line, $1.column) }
    }

    private static func warning(for mutant: [String: Any], in source: String, file: String) -> SurvivorWarning? {
        guard let location = mutant["location"] as? [String: [String: Int]],
              let line = location["start"]?["line"],
              let column = location["start"]?["column"],
              let endLine = location["end"]?["line"],
              let endColumn = location["end"]?["column"] else { return nil }
        let replacement = mutant["replacement"] as? String ?? ""
        let original = text(in: source, from: (line, column), to: (endLine, endColumn))
        let change: String
        if replacement.isEmpty {
            change = original.isEmpty ? "removing this code" : "removing \(original)"
        } else {
            change = original.isEmpty ? "changing this code to \(replacement)" : "changing \(original) to \(replacement)"
        }
        // The place is in the text too: a plugin's warning isn't shown at its line, in Xcode or `swift package`.
        let place = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        let message = "No test failed after \(change) at \(place). Add a scenario that checks this code."
        return SurvivorWarning(file: file, line: line, column: column, message: message)
    }

    /// The text from `start` up to `end`, as line and column, both 1-based and counted in UTF-8 bytes, as swift-syntax
    /// counts them. Empty when the positions aren't in `source`.
    private static func text(in source: String, from start: (line: Int, column: Int), to end: (line: Int, column: Int)) -> String {
        let bytes = Array(source.utf8)
        var lineStarts = [0]
        for (index, byte) in bytes.enumerated() where byte == UInt8(ascii: "\n") { lineStarts.append(index + 1) }
        guard lineStarts.indices.contains(start.line - 1), lineStarts.indices.contains(end.line - 1) else { return "" }
        let from = lineStarts[start.line - 1] + start.column - 1
        let to = lineStarts[end.line - 1] + end.column - 1
        guard from >= 0, from <= to, to <= bytes.count else { return "" }
        return String(bytes: bytes[from..<to], encoding: .utf8) ?? ""
    }
}
#endif
