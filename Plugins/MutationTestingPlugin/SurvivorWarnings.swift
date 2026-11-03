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
              let endColumn = location["end"]?["column"] else { return nil }
        let replacement = mutant["replacement"] as? String ?? ""
        let original = text(in: source, line: line, from: column, to: endColumn)
        let change = original.isEmpty ? "to \(replacement)" : "\(original) to \(replacement)"
        let message = "Mutant survived: changing \(change) made no test fail. Add a scenario that checks this code."
        return SurvivorWarning(file: file, line: line, message: message)
    }

    /// The text of `line` from `column` up to `endColumn`, both 1-based and counted in UTF-8 bytes, as swift-syntax
    /// counts them.
    private static func text(in source: String, line: Int, from column: Int, to endColumn: Int) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.indices.contains(line - 1), column >= 1, endColumn > column else { return "" }
        let bytes = Array(lines[line - 1].utf8)
        guard endColumn - 1 <= bytes.count else { return "" }
        return String(bytes: bytes[(column - 1)..<(endColumn - 1)], encoding: .utf8) ?? ""
    }
}
