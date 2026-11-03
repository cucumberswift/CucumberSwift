//
//  StrykerReport.swift
//  CucumberSwiftMutation
//

import Foundation

/// The report in the Stryker mutation testing report format, version 2, which viewers such as Mutation
/// Testing Elements read.
public struct StrykerReport: Encodable {
    struct Position: Encodable {
        let line: Int
        let column: Int
    }

    struct Location: Encodable {
        let start: Position
        let end: Position
    }

    struct MutantEntry: Encodable {
        let id: String
        let mutatorName: String
        let replacement: String
        let location: Location
        let status: String
        let statusReason: String?
    }

    struct SourceFile: Encodable {
        let language = "swift"
        let source: String
        var mutants: [MutantEntry]
    }

    struct Thresholds: Encodable {
        let high = 80
        let low = 60
    }

    struct Branding: Encodable {
        let homepageUrl = "https://github.com/cucumberswift/CucumberSwift"
    }

    struct Framework: Encodable {
        let name = "CucumberSwift mutation testing"
        let branding = Branding()
    }

    let schemaVersion = "2"
    let thresholds = Thresholds()
    var files = [String: SourceFile]()
    let framework = Framework()

    /// `sources` has each file's text, by its path relative to the package.
    public init(results: [MutantResult], sources: [String: String]) {
        for result in results {
            let mutant = result.mutant
            var file = files[mutant.file] ?? SourceFile(source: sources[mutant.file] ?? "", mutants: [])
            var reason: String?
            if case .killed(let by) = result.verdict, !by.isEmpty { reason = by.joined(separator: "; ") }
            if result.verdict == .survived { reason = "no test failed" }
            file.mutants.append(MutantEntry(
                id: String(mutant.id),
                mutatorName: mutant.mutator,
                replacement: mutant.replacement,
                location: Location(start: Position(line: mutant.line, column: mutant.column),
                                   end: Position(line: mutant.endLine, column: mutant.endColumn)),
                status: result.verdict.name,
                statusReason: reason))
            files[mutant.file] = file
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
