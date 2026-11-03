//
//  MutationFindings.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// A feature's Mutation score: of the mutants in the code that its scenarios run, how many a test detected,
/// and a warning on each scenario that runs a mutant no test detected.
struct MutationFindings: Equatable {
    /// The mutants in the feature's code that a test detected, and that count.
    let detected: Int
    let counted: Int
    let issues: [CoverageIssue]

    var percent: Double { counted == 0 ? 100 : Double(detected) * 100 / Double(counted) }

    /// The findings for a feature's `scenarios`, or nil when none of them runs the code of any mutant.
    /// `regions` returns the numbers of the measured regions that hold a file's line.
    static func make(report: MutationReport,
                     scenarios: [CoverageScores.Scenario],
                     regions: (String, Int) -> Set<Int>,
                     file: URL?,
                     featureLine: Int) -> MutationFindings? {
        var detected = 0
        var counted = 0
        var issues = [CoverageIssue]()
        for mutant in report.mutants where mutant.isCounted {
            let held = regions(mutant.file, mutant.line)
            let running = scenarios.filter { !$0.regions.isDisjoint(with: held) }
            guard !held.isEmpty, !running.isEmpty else { continue }
            counted += 1
            if mutant.isDetected {
                detected += 1
                continue
            }
            let place = "\(URL(fileURLWithPath: mutant.file).lastPathComponent):\(mutant.line)"
            for scenario in running {
                let message = "Mutant survived: changing \(mutant.change) at \(place) made no step of this scenario fail. "
                    + "This scenario runs that code. Add a step that checks it."
                issues.append(CoverageIssue(severity: .warning, message: message, file: file, line: scenario.line, kind: .mutation))
            }
        }
        guard counted > 0 else { return nil }
        let findings = MutationFindings(detected: detected, counted: counted, issues: [])
        guard detected < counted else { return findings }
        let message = "Mutation score \(CoverageReport.percent(findings.percent)): its scenarios detected \(detected) of the "
            + "\(counted) mutants in the code they run\(dated(report.date)). Each scenario that runs a surviving mutant has a warning."
        let summary = CoverageIssue(severity: .warning, message: message, file: file, line: featureLine, kind: .mutation)
        return MutationFindings(detected: detected, counted: counted, issues: [summary] + issues)
    }

    /// ", from the mutation report of 3 Nov 2026 at 14:05", or nothing without a date.
    private static func dated(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return ", from the mutation report of \(formatter.string(from: date))"
    }
}
