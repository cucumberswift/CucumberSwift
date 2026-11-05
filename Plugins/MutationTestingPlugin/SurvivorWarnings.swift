import Foundation
import PackagePlugin

/// A surviving mutant, read from the tool's Stryker report, as a warning at its line: Xcode shows the warning in the
/// source file and in the issue navigator, and `swift package` prints it.
struct SurvivorWarning: Equatable {
    let file: String
    let line: Int
    let message: String

    /// The survivors in the report at `report`, with each file's path made absolute under `root`.
    static func read(report: URL, root: URL) -> [SurvivorWarning] {
        guard let data = try? Data(contentsOf: report),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: [String: Any]] else { return [] }
        var warnings = [SurvivorWarning]()
        for (path, file) in files.sorted(by: { $0.key < $1.key }) {
            let source = file["source"] as? String ?? ""
            for mutant in file["mutants"] as? [[String: Any]] ?? [] where mutant["status"] as? String == "Survived" {
                if let warning = warning(for: mutant, in: source, file: root.appending(path: path).path) {
                    warnings.append(warning)
                }
            }
        }
        return warnings.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
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
        let message = "No test failed after \(change). Add a scenario that checks this code."
        return SurvivorWarning(file: file, line: line, message: message)
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
