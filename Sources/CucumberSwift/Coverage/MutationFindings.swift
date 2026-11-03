//
//  MutationFindings.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// What a feature's Mutation test finds: of the mutants in the code that its scenarios run, the ones that no
/// test detected. Each of those is an error, on the feature and on each scenario that runs its code, so the test
/// fails when any survived. A scenario that passes with the code changed doesn't check that code.
struct MutationFindings: Equatable {
    /// The mutants in the feature's code that a test detected, and that count.
    let detected: Int
    let counted: Int
    let issues: [CoverageIssue]

    var survived: Int { counted - detected }

    /// The findings for a feature's `scenarios`, or nil when none of them runs the code of any mutant.
    /// `regions` returns the numbers of the measured regions that hold a file's line and column.
    static func make(report: MutationReport,
                     scenarios: [CoverageScores.Scenario],
                     regions: (String, Int, Int?) -> Set<Int>,
                     file: URL?,
                     featureLine: Int) -> MutationFindings? {
        var detected = 0
        var counted = 0
        var issues = [CoverageIssue]()
        for mutant in report.mutants where mutant.isCounted {
            let held = regions(mutant.file, mutant.line, mutant.column)
            let running = scenarios.filter { !$0.regions.isDisjoint(with: held) }
            guard !held.isEmpty, !running.isEmpty else { continue }
            counted += 1
            if mutant.isDetected {
                detected += 1
                continue
            }
            let message = "This scenario still passes when \(describe(mutant)). Add a step that checks this code."
            issues += running.map { CoverageIssue(severity: .error, message: message, file: file, line: $0.line, kind: .mutation) }
        }
        guard counted > 0 else { return nil }
        let findings = MutationFindings(detected: detected, counted: counted, issues: [])
        guard findings.survived > 0 else { return findings }
        let message = "Mutation testing: the scenarios still pass after \(findings.survived) of the \(counted) changes to the code "
            + "they run\(dated(report.date)). The scenarios that miss a change have an error."
        let summary = CoverageIssue(severity: .error, message: message, file: file, line: featureLine, kind: .mutation)
        return MutationFindings(detected: detected, counted: counted, issues: [summary] + issues)
    }

    /// `>= at Voting.swift:12 is changed to >`
    private static func describe(_ mutant: MutationReport.Mutant) -> String {
        let place = "\(URL(fileURLWithPath: mutant.file).lastPathComponent):\(mutant.line)"
        guard !mutant.original.isEmpty else { return "the code at \(place) is changed to \(mutant.replacement)" }
        return "\(mutant.original) at \(place) is changed to \(mutant.replacement)"
    }

    /// ", in the mutation report of 3 Nov 2026 at 14:05", or nothing without a date.
    private static func dated(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return ", in the mutation report of \(formatter.string(from: date))"
    }
}
