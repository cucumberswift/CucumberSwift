//
//  CucumberReportAnnotator.swift
//  CucumberSwiftMutation
//

import Foundation

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
