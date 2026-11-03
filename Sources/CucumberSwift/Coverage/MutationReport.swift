//
//  MutationReport.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// The mutants of a `mutation-test` run, read from the Stryker report it writes, for each feature's
/// Mutation score. A test run doesn't mutate anything: it matches these mutants to the scenarios that run
/// their code, through the coverage it measures.
struct MutationReport: Equatable {
    struct Mutant: Equatable {
        /// The file, relative to the package, as the report gives it.
        let file: String
        let line: Int
        /// The first column of the changed text, 1-based and counted in UTF-8 bytes.
        let column: Int
        /// The change, such as `>= to >`.
        let change: String
        /// `Killed`, `Survived`, `Timeout` or `CompileError`, as the report gives it.
        let status: String

        /// Whether the mutant counts in the score: a mutant that didn't build doesn't.
        var isCounted: Bool { ["Killed", "Timeout", "Survived"].contains(status) }
        var isDetected: Bool { status == "Killed" || status == "Timeout" }
    }

    struct ReadError: Error, Equatable {
        let message: String
    }

    let mutants: [Mutant]
    /// When the report was written, as its file's modification date.
    let date: Date?

    /// The report at `path`, or the reason it can't be read.
    static func read(path: String) -> Result<MutationReport, ReadError> {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return .failure(ReadError(message: "no mutation report at \(path)")) }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: [String: Any]] else {
            return .failure(ReadError(message: "\(path) is not a mutation report in the Stryker format"))
        }
        var mutants = [Mutant]()
        for (file, contents) in files.sorted(by: { $0.key < $1.key }) {
            let source = contents["source"] as? String ?? ""
            for entry in contents["mutants"] as? [[String: Any]] ?? [] {
                if let mutant = mutant(from: entry, file: file, source: source) { mutants.append(mutant) }
            }
        }
        let date = (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
        return .success(MutationReport(mutants: mutants, date: date))
    }

    private static func mutant(from entry: [String: Any], file: String, source: String) -> Mutant? {
        guard let location = entry["location"] as? [String: [String: Int]],
              let line = location["start"]?["line"],
              let column = location["start"]?["column"],
              let status = entry["status"] as? String else { return nil }
        let replacement = entry["replacement"] as? String ?? ""
        let original = text(in: source, line: line, from: column, to: location["end"]?["column"] ?? column)
        return Mutant(file: file, line: line, column: column, change: original.isEmpty ? "to \(replacement)" : "\(original) to \(replacement)", status: status)
    }

    /// The text of `line` from `column` up to `endColumn`, 1-based and counted in UTF-8 bytes, as swift-syntax
    /// counts them.
    private static func text(in source: String, line: Int, from column: Int, to endColumn: Int) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.indices.contains(line - 1), column >= 1, endColumn > column else { return "" }
        let bytes = Array(lines[line - 1].utf8)
        guard endColumn - 1 <= bytes.count else { return "" }
        return String(bytes: bytes[(column - 1)..<(endColumn - 1)], encoding: .utf8) ?? ""
    }
}
