//
//  MutationSummary.swift
//  CucumberSwiftMutation
//

import Foundation

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
        lines.append("Killed \(score.killed), timed out \(score.timedOut), survived \(score.survived), did not build \(score.unviable), "
            + "ignored \(score.ignored), in code no scenario runs \(score.noCoverage)")
        lines.append("Run time: \(String(format: "%.0f", duration)) s")
        let survivors = results.filter { $0.verdict == .survived }
        if !survivors.isEmpty {
            lines.append("")
            lines.append("Mutants that no test noticed:")
            for result in survivors {
                lines.append("  \(result.mutant.summary)")
                if !result.coveredBy.isEmpty { lines.append("    Scenarios that run this code: " + result.coveredBy.map(\.description).joined(separator: ", ")) }
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
