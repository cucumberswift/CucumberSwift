//
//  Reports.swift
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

/// Adds what the run found to a Cucumber JSON report that the tests wrote, as an `embeddings` entry on a step.
public enum CucumberReportAnnotator {
    public struct Annotated {
        public let data: Data
        /// The failed steps, as `Scenario :: Given step`.
        public let failedSteps: [String]
    }

    /// The annotated report, or `nil` when `data` is not a Cucumber JSON report.
    ///
    /// A killed mutant is noted on each failed step. A survivor is noted on the last step of each scenario, because
    /// those are the scenarios that ran against it and did not notice.
    public static func annotate(_ data: Data, result: MutantResult) -> Annotated? {
        guard var features = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return nil }
        let note = [
            "mutant": result.mutant.id,
            "mutator": result.mutant.mutator,
            "change": "\(result.mutant.original) → \(result.mutant.replacement)",
            "location": "\(result.mutant.file):\(result.mutant.line):\(result.mutant.column)",
            "status": result.verdict.name
        ] as [String: Any]
        guard let noteData = try? JSONSerialization.data(withJSONObject: note, options: [.sortedKeys]) else { return nil }
        let embedding: [String: Any] = ["mime_type": "application/json", "data": noteData.base64EncodedString()]
        var failed = [String]()
        for featureIndex in features.indices {
            var elements = features[featureIndex]["elements"] as? [[String: Any]] ?? []
            for elementIndex in elements.indices {
                var steps = elements[elementIndex]["steps"] as? [[String: Any]] ?? []
                let scenario = elements[elementIndex]["name"] as? String ?? ""
                for stepIndex in steps.indices {
                    let status = (steps[stepIndex]["result"] as? [String: Any])?["status"] as? String
                    let isLast = stepIndex == steps.indices.last
                    let marks = status == "failed" || (result.verdict == .survived && isLast)
                    guard marks else { continue }
                    if status == "failed" {
                        let keyword = (steps[stepIndex]["keyword"] as? String ?? "").trimmingCharacters(in: .whitespaces)
                        failed.append("\(scenario) :: \(keyword) \(steps[stepIndex]["name"] as? String ?? "")")
                    }
                    steps[stepIndex]["embeddings"] = (steps[stepIndex]["embeddings"] as? [[String: Any]] ?? []) + [embedding]
                }
                elements[elementIndex]["steps"] = steps
            }
            features[featureIndex]["elements"] = elements
        }
        guard let output = try? JSONSerialization.data(withJSONObject: features, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return Annotated(data: output, failedSteps: failed)
    }
}

/// The text a run prints at its end and writes to `summary.txt`.
public enum MutationSummary {
    public static func text(results: [MutantResult], duration: TimeInterval) -> String {
        let score = MutationScore(results)
        var lines = [String]()
        if let percent = score.percent {
            lines.append("Mutation score: \(String(format: "%.1f", percent))% (\(score.detected) of \(score.counted) mutants detected)")
        } else {
            lines.append("Mutation score: none, because no mutant was tested")
        }
        lines.append("Killed \(score.killed), timed out \(score.timedOut), survived \(score.survived), did not build \(score.unviable)")
        lines.append("Run time: \(String(format: "%.0f", duration)) s")
        let survivors = results.filter { $0.verdict == .survived }
        if !survivors.isEmpty {
            lines.append("")
            lines.append("Mutants that no test noticed:")
            for result in survivors { lines.append("  \(result.mutant.summary)") }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
