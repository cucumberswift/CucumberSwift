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
    /// How the findings look up the code under test: the measured regions at a file's line and column, and a file's
    /// text now, or nil when it can't be read.
    struct CodeLookup {
        let regions: (String, Int, Int?) -> Set<Int>
        let currentSource: (String) -> String?
    }

    /// The mutants in the feature's code that a test detected, and that count.
    let detected: Int
    let counted: Int
    let issues: [CoverageIssue]
    /// The mutants each scenario detected, by the scenario's line: the IDs of the mutants it failed with. A mutant
    /// that the report names no scenario for, as when the change crashed the tests, counts for every scenario that
    /// runs its code, so that no scenario looks weaker than it is.
    let kills: [Int: Set<String>]
    /// What each mutant in ``kills`` changes, by its ID, such as `>= at Voting.swift:12 is changed to >`.
    let changes: [String: String]
    /// Whether a file changed after the report was written, so that the report can't say what the scenarios detect.
    let isOutOfDate: Bool

    var survived: Int { counted - detected }

    /// The findings for a feature's `scenarios`, or nil when none of them runs the code of any mutant. A mutant in a
    /// file that changed since the report was written isn't scored: the feature gets an error that the report is out of
    /// date instead, because a report about other code proves nothing about this code.
    static func make(report: MutationReport,
                     scenarios: [CoverageScores.Scenario],
                     code: CodeLookup,
                     file: URL?,
                     featureLine: Int,
                     feature: String = "") -> MutationFindings? {
        var detected = 0
        var counted = 0
        var issues = [CoverageIssue]()
        if let issue = otherScenarios(in: report, scenarios: scenarios, feature: feature, file: file, featureLine: featureLine) {
            return MutationFindings(detected: 0, counted: 0, issues: [issue], kills: [:], changes: [:], isOutOfDate: true)
        }
        var kills = [Int: Set<String>]()
        var changes = [String: String]()
        var stale = Set<String>()
        var checked = [String: Bool]()
        for mutant in report.mutants where mutant.isCounted {
            let held = code.regions(mutant.file, mutant.line, mutant.column)
            let running = scenarios.filter { !$0.regions.isDisjoint(with: held) }
            guard !held.isEmpty, !running.isEmpty else { continue }
            checked[mutant.file] = checked[mutant.file] ?? isUnchanged(mutant.file, report: report, code: code)
            guard checked[mutant.file] == true else {
                stale.insert(URL(fileURLWithPath: mutant.file).lastPathComponent)
                continue
            }
            counted += 1
            if mutant.isDetected {
                detected += 1
                let named = Set(mutant.killedBy.filter { isSame(feature: $0.feature, as: feature) }.map(\.line))
                let credited = mutant.killedBy.isEmpty ? running : scenarios.filter { named.contains($0.line) }
                credited.forEach { kills[$0.line, default: []].insert(mutant.id) }
                changes[mutant.id] = describe(mutant)
                continue
            }
            let message = "This scenario still passes when \(describe(mutant)). Add a step that checks this code."
            issues += running.map { CoverageIssue(severity: .error, message: message, file: file, line: $0.line, kind: .mutation) }
        }
        var summary = [CoverageIssue]()
        if !stale.isEmpty {
            let message = "The mutation report is out of date: \(stale.sorted().joined(separator: ", ")) changed after it was written"
                + "\(dated(report.date)). Run `cucumberswift-mutation-test` again."
            summary.append(CoverageIssue(severity: .error, message: message, file: file, line: featureLine, kind: .mutation))
        }
        guard counted > 0 || !stale.isEmpty else { return nil }
        let survived = counted - detected
        if survived > 0 {
            let message = "Mutation testing: the scenarios still pass after \(survived) of the \(counted) changes to the code "
                + "they run\(dated(report.date)). The scenarios that miss a change have an error."
            summary.append(CoverageIssue(severity: .error, message: message, file: file, line: featureLine, kind: .mutation))
        }
        return MutationFindings(detected: detected,
                                counted: counted,
                                issues: summary + issues,
                                kills: kills,
                                changes: changes,
                                isOutOfDate: !stale.isEmpty)
    }

    /// An error when the report is about other scenarios than the feature's, as when the command ran with other
    /// `CUCUMBER_TAGS` than the tests: some of the feature's scenarios weren't in its run, so it says nothing about them.
    /// Nil when they all were, or when the report doesn't list its scenarios.
    private static func otherScenarios(in report: MutationReport,
                                       scenarios: [CoverageScores.Scenario],
                                       feature: String,
                                       file: URL?,
                                       featureLine: Int) -> CoverageIssue? {
        guard !report.scenarios.isEmpty else { return nil }
        let ran = Set(report.scenarios.filter { isSame(feature: $0.feature, as: feature) }.map(\.line))
        let missing = scenarios.filter { !ran.contains($0.line) }
        guard !missing.isEmpty else { return nil }
        let lines = missing.map { String($0.line) }.joined(separator: ", ")
        let message = "The mutation report is from a run of other scenarios: the "
            + (missing.count == 1 ? "scenario at line \(lines) wasn't" : "scenarios at lines \(lines) weren't")
            + " in it\(dated(report.date)). Run `cucumberswift-mutation-test` with the same CUCUMBER_TAGS as these tests."
        return CoverageIssue(severity: .error, message: message, file: file, line: featureLine, kind: .mutation)
    }

    /// Whether two features' paths inside their test bundles name the same file. One may be longer when a run
    /// found no bundle in the path, so either may end with the other.
    private static func isSame(feature: String, as other: String) -> Bool {
        feature == other || feature.hasSuffix("/" + other) || other.hasSuffix("/" + feature)
    }

    /// Whether `file` reads now as the report recorded it. A file that can't be read, as on a device that can't see
    /// the Mac's files, or that the report has no text for, counts as unchanged: there's nothing to compare.
    private static func isUnchanged(_ file: String, report: MutationReport, code: CodeLookup) -> Bool {
        guard let recorded = report.sources[file], !recorded.isEmpty, let current = code.currentSource(file) else { return true }
        return recorded == current
    }

    /// `>= at Voting.swift:12 is changed to >`
    static func describe(_ mutant: MutationReport.Mutant) -> String {
        let place = "\(URL(fileURLWithPath: mutant.file).lastPathComponent):\(mutant.line)"
        guard !mutant.original.isEmpty else { return "the code at \(place) is changed to \(mutant.replacement)" }
        // A mutant that removes code, such as a call or the `!` of a negation, has no replacement.
        guard !mutant.replacement.isEmpty else { return "\(mutant.original) at \(place) is removed" }
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
