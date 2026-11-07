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
    /// A scenario that the report names: its feature file's path inside the test bundle, and its line.
    struct Scenario: Hashable {
        let feature: String
        let line: Int
    }

    struct Mutant: Equatable {
        /// The mutant's ID in the report.
        var id = ""
        /// The file, relative to the package, as the report gives it.
        let file: String
        let line: Int
        /// The first column of the changed text, 1-based and counted in UTF-8 bytes.
        let column: Int
        /// The text the mutant replaced, such as `>=`, and what replaced it, such as `>`. The original is empty
        /// when the report's source doesn't have it.
        let original: String
        let replacement: String
        /// `Killed`, `Survived`, `Timeout` or `CompileError`, as the report gives it.
        let status: String
        /// The scenarios that failed with the mutant. Empty when the report doesn't name them, as when the change
        /// crashed the tests before they wrote their report.
        var killedBy = [Scenario]()

        /// Whether the mutant counts in the score: a mutant that didn't build doesn't.
        var isCounted: Bool { ["Killed", "Timeout", "Survived"].contains(status) }
        var isDetected: Bool { status == "Killed" || status == "Timeout" }
    }

    struct ReadError: Error, Equatable {
        let message: String
    }

    let mutants: [Mutant]
    /// Each file's text when the run made its mutants, by the file's path relative to the package. The Mutation
    /// test compares it with the file now: a report about other code than the code under test proves nothing.
    let sources: [String: String]
    /// When the report was written, as its file's modification date.
    let date: Date?
    /// The scenarios of the run without a change, from the report's `testFiles`. Empty when the report doesn't list
    /// them, as a report by an earlier version of the command doesn't.
    var scenarios = Set<Scenario>()

    /// The report at `path`, or the reason it can't be read.
    static func read(path: String) -> Result<MutationReport, ReadError> {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return .failure(ReadError(message: "no mutation report at \(path)")) }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: [String: Any]] else {
            return .failure(ReadError(message: "\(path) is not a mutation report in the Stryker format"))
        }
        var mutants = [Mutant]()
        var sources = [String: String]()
        for (file, contents) in files.sorted(by: { $0.key < $1.key }) {
            let source = contents["source"] as? String ?? ""
            sources[file] = source
            for entry in contents["mutants"] as? [[String: Any]] ?? [] {
                if let mutant = mutant(from: entry, file: file, source: source) { mutants.append(mutant) }
            }
        }
        let date = (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
        var report = MutationReport(mutants: mutants, sources: sources, date: date)
        let testFiles = json["testFiles"] as? [String: [String: Any]] ?? [:]
        report.scenarios = Set(testFiles.values.flatMap { $0["tests"] as? [[String: Any]] ?? [] }
            .compactMap { ($0["id"] as? String).flatMap(scenario(fromID:)) })
        return .success(report)
    }

    private static func mutant(from entry: [String: Any], file: String, source: String) -> Mutant? {
        guard let location = entry["location"] as? [String: [String: Int]],
              let line = location["start"]?["line"],
              let column = location["start"]?["column"],
              let status = entry["status"] as? String else { return nil }
        let replacement = entry["replacement"] as? String ?? ""
        let original = text(in: source, from: (line, column), to: (location["end"]?["line"] ?? line, location["end"]?["column"] ?? column))
        var mutant = Mutant(file: file, line: line, column: column, original: original, replacement: replacement, status: status)
        mutant.id = entry["id"] as? String ?? "\(file):\(line):\(column)"
        mutant.killedBy = (entry["killedBy"] as? [String] ?? []).compactMap(scenario(fromID:))
        return mutant
    }

    /// The scenario with the report's test ID `Features/Basket.feature:12`.
    private static func scenario(fromID id: String) -> Scenario? {
        guard let colon = id.lastIndex(of: ":"), let line = Int(id[id.index(after: colon)...]) else { return nil }
        return Scenario(feature: String(id[..<colon]), line: line)
    }

    /// The path of the feature file at `uri` inside its test bundle: after the last `.xctest/`, where Xcode puts the
    /// feature files, or `.bundle/`, where SwiftPM puts a target's resources. The whole path when it has neither. The
    /// mutation-test tool names scenarios the same way, in `ScenarioID`, and the two must agree.
    static func feature(ofURI uri: String) -> String {
        let path = uri.hasPrefix("file:") ? (URL(string: uri)?.path ?? uri) : uri
        let marker = [".xctest/", ".bundle/"].compactMap { path.range(of: $0, options: .backwards) }.max { $0.upperBound < $1.upperBound }
        return marker.map { String(path[$0.upperBound...]) } ?? path
    }

    /// The text from `start` up to `end`, as line and column, both 1-based and counted in UTF-8 bytes, as swift-syntax
    /// counts them. Empty when the positions aren't in `source`.
    static func text(in source: String, from start: (line: Int, column: Int), to end: (line: Int, column: Int)) -> String {
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
