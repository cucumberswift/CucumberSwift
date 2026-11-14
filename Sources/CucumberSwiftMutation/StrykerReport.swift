//
//  StrykerReport.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
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
        /// The IDs of the scenarios that failed with the mutant, and of those that ran its code: see ``testFiles``.
        let killedBy: [String]?
        let coveredBy: [String]?
    }

    struct TestDefinition: Encodable {
        let id: String
        let name: String
        let location: Location
    }

    struct TestFile: Encodable {
        var tests: [TestDefinition]
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
    /// The scenarios that the mutants name in `killedBy` and `coveredBy`, by feature file.
    var testFiles: [String: TestFile]?
    let framework = Framework()

    /// `sources` has each file's text, by its path relative to the package. `ran` has every scenario of the run
    /// without a change, so that the report lists them all in `testFiles`, and a test run can tell a report about other
    /// scenarios, as from other `CUCUMBER_TAGS`.
    public init(results: [MutantResult], sources: [String: String], ran: [ScenarioID] = []) {
        var scenarios = Set(ran)
        for result in results {
            let mutant = result.mutant
            scenarios.formUnion(result.killedBy)
            scenarios.formUnion(result.coveredBy)
            var file = files[mutant.file] ?? SourceFile(source: sources[mutant.file] ?? "", mutants: [])
            var reason: String?
            if case .killed(let by) = result.verdict, !by.isEmpty { reason = by.joined(separator: "; ") }
            if result.verdict == .survived {
                reason = result.coveredBy.isEmpty ? "no test failed" : "no test failed; ran by " + result.coveredBy.map(\.description).joined(separator: "; ")
            }
            if result.verdict == .noCoverage { reason = "no scenario ran this code" }
            if case .ignored(let comment) = result.verdict { reason = comment.isEmpty ? "ignored by a comment in the code" : comment }
            file.mutants.append(MutantEntry(
                id: String(mutant.id),
                mutatorName: mutant.mutator,
                replacement: mutant.replacement,
                location: Location(start: Position(line: mutant.line, column: mutant.column),
                                   end: Position(line: mutant.endLine, column: mutant.endColumn)),
                status: result.verdict.name,
                statusReason: reason,
                killedBy: result.killedBy.isEmpty ? nil : result.killedBy.map(\.id),
                coveredBy: result.coveredBy.isEmpty ? nil : result.coveredBy.map(\.id)))
            files[mutant.file] = file
        }
        guard !scenarios.isEmpty else { return }
        var testFiles = [String: TestFile]()
        for scenario in scenarios.sorted() {
            let start = Position(line: scenario.line, column: 1)
            let test = TestDefinition(id: scenario.id, name: scenario.name, location: Location(start: start, end: start))
            testFiles[scenario.feature, default: TestFile(tests: [])].tests.append(test)
        }
        self.testFiles = testFiles
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
#endif
