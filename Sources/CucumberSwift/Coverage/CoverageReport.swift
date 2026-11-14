//
//  CoverageReport.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// A warning or an error about a coverage score, at a line of a feature file. Each runner records it as a
/// test issue of its own kind.
struct CoverageIssue: Equatable {
    enum Severity: Equatable {
        case warning
        case error
    }

    /// The score the issue is about.
    enum Kind: Equatable, CaseIterable {
        /// A feature's or a Rule's coverage.
        case coverage
        /// A feature's or a Rule's redundancy, and each scenario that adds no coverage of its own.
        case redundancy
        /// A feature's Mutation score, and each scenario that runs a mutant that no test detected, with
        /// ``Cucumber/mutationReport`` set.
        case mutation
    }

    let severity: Severity
    let message: String
    let file: URL?
    let line: Int
    var kind = Kind.coverage
}

/// A feature's scores as text: the summary that the run prints, and the issues for the scores past their levels.
struct CoverageReport {
    /// The gaps a message names, at most.
    static let gapsShown = 3
    /// The most changes a message lists before it counts the rest.
    static let changesShown = 3

    let scores: CoverageScores
    let settings: CoverageSettings

    /// The severity of a score past a level, or nil. A lower score is worse for coverage, a higher one for
    /// redundancy.
    static func severity(of score: Double, warning: CoverageLevel, error: CoverageLevel, isLowerWorse: Bool) -> CoverageIssue.Severity? {
        func isPast(_ level: CoverageLevel) -> Bool {
            guard case .percent(let value) = level else { return false }
            // The score as shown, so that a feature shown at 50% is at a level of 50.
            let shown = score.rounded()
            return isLowerWorse ? shown <= Double(value) : shown >= Double(value)
        }
        if isPast(error) { return .error }
        if isPast(warning) { return .warning }
        return nil
    }

    private static func levels(warning: CoverageLevel, error: CoverageLevel, comparison: String) -> String {
        [("error", error), ("warning", warning)].compactMap { name, level in
            guard case .percent(let value) = level else { return nil }
            return "\(name) \(comparison) \(value)%"
        }
        .joined(separator: ", ")
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// `count` and `noun`, plural unless `count` is 1, such as "1 function" or "6 functions".
    static func count(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }

    /// The time the redundant scenarios took, of all the scenarios' time, such as ", about 4.2 s of 12.6 s
    /// in redundant scenarios", or nothing with the redundancy score off.
    static func wasted(_ scores: CoverageScores) -> String {
        guard let wasted = scores.wastedTime else { return "" }
        return ", about \(seconds(wasted)) of \(seconds(scores.duration)) in redundant scenarios"
    }

    /// Seconds to two decimals below one second, as most scenarios take, and to one above it.
    static func seconds(_ value: TimeInterval) -> String {
        String(format: value < 1 ? "%.2f s" : "%.1f s", value)
    }

    /// `text` with spaces before it, to `width` characters.
    static func padded(_ text: String, _ width: Int) -> String {
        text.count >= width ? text : String(repeating: " ", count: width - text.count) + text
    }

    /// "Scenario overlaps the scenario at line 5. That scenario runs 4 regions this one doesn't. Only this one fails
    /// when >= at Basket.swift:21 is changed to >. Combine the best of both into one scenario, or into a Scenario
    /// Outline for different values."
    static func message(for overlap: CoverageScores.Overlap) -> String {
        var sentences = ["Scenario overlaps the scenario at line \(overlap.line)."]
        if overlap.regionsHere > 0 { sentences.append("This scenario runs \(count(overlap.regionsHere, "region")) that one doesn't.") }
        if overlap.regionsThere > 0 { sentences.append("That scenario runs \(count(overlap.regionsThere, "region")) this one doesn't.") }
        if !overlap.detectsHere.isEmpty { sentences.append("Only this one fails when \(listed(overlap.detectsHere)).") }
        if !overlap.detectsThere.isEmpty { sentences.append("Only that one fails when \(listed(overlap.detectsThere)).") }
        sentences.append("Combine the best of both into one scenario, or into a Scenario Outline for different values.")
        return sentences.joined(separator: " ")
    }

    /// "a, b or c", or "a, b, c or 2 other changes" past ``changesShown``.
    private static func listed(_ changes: [String]) -> String {
        var shown = Array(changes.prefix(changesShown))
        if changes.count > changesShown { shown.append("\(changes.count - changesShown) other \(changes.count - changesShown == 1 ? "change" : "changes")") }
        guard shown.count > 1, let last = shown.last else { return shown.first ?? "" }
        return shown.dropLast().joined(separator: ", ") + " or " + last
    }

    /// A part of a feature's summary, and its issues: on the line of its `Rule:`, or of its `Feature:` for
    /// the scenarios outside a Rule.
    static func report(_ part: CoverageScores.Part,
                       featureName: String,
                       featureLine: Int,
                       file: URL?,
                       settings: CoverageSettings) -> (summary: String, issues: [CoverageIssue]) {
        let report = CoverageReport(scores: part.scores, settings: settings)
        guard let rule = part.rule else {
            return (report.summary(name: featureName), report.issues(file: file, line: featureLine, subject: "Feature"))
        }
        return (report.summary(name: "\(featureName) › \(rule.title)"), report.issues(file: file, line: rule.line, subject: "Rule"))
    }

    func summary(name: String) -> String {
        var header = "CucumberSwift coverage: \(name): \(Self.percent(scores.coverage)) of the code its scenarios ran"
            + " (\(scores.coveredRegions) of \(scores.regionsInFunctionsRun) regions in \(Self.count(scores.functionsRun, "function"))),"
            + " \(Self.percent(scores.coverageOfAllCode)) of all measured code"
        if let redundancy = scores.redundancy {
            header += ", redundancy \(Self.percent(redundancy))\(Self.wasted(scores))"
        }
        var lines = [header, "    Share  Own regions      Time  Scenario"]
        for scenario in scores.scenarios {
            let share = Self.padded(Self.percent(scenario.share), 9)
            let own = Self.padded("\(scenario.ownRegions)", 13)
            let time = Self.padded(String(format: "%.2fs", scenario.duration), 10)
            lines.append("\(share)\(own)\(time)  \(scenario.name) (line \(scenario.line)\(note(for: scenario)))")
        }
        return lines.joined(separator: "\n")
    }

    /// What the summary adds after a scenario's line: that it adds nothing of its own, or the line it overlaps.
    private func note(for scenario: CoverageScores.ScenarioScore) -> String {
        if let overlap = scenario.overlap { return ", overlaps line \(overlap.line)" }
        guard scenario.addsNothing else { return "" }
        return scores.isMutationAware ? ", adds nothing of its own" : ", adds no coverage of its own"
    }

    /// The issues for the scores past their levels: at `line`, the line of the `subject`, "Feature" or
    /// "Rule", that the scores are for, and at the line of each scenario that adds nothing of its own.
    func issues(file: URL?, line: Int, subject: String) -> [CoverageIssue] {
        var issues = [CoverageIssue]()
        // Scenarios that ran no measured code, such as a UI test's, whose app runs in another process, have
        // nothing to score.
        guard scores.regionsInFunctionsRun > 0 else { return [] }
        if let severity = Self.severity(of: scores.coverage, warning: settings.warningLevel, error: settings.errorLevel, isLowerWorse: true) {
            var message = "\(subject) coverage \(Self.percent(scores.coverage)): its scenarios ran \(scores.coveredRegions) of the"
                + " \(scores.regionsInFunctionsRun) regions in the \(Self.count(scores.functionsRun, "function")) they entered"
                + " (\(Self.levels(warning: settings.warningLevel, error: settings.errorLevel, comparison: "at or below")))."
            let gaps = scores.gaps.prefix(Self.gapsShown).map { gap in
                let lines = gap.enteredBy.map(String.init).joined(separator: ", ")
                return "\(gap.function), \(Self.count(gap.regionsNotRun, "region")),"
                    + " entered by the \(gap.enteredBy.count == 1 ? "scenario at line" : "scenarios at lines") \(lines)"
            }
            if !gaps.isEmpty {
                message += " Not run: " + gaps.joined(separator: "; ") + "."
            }
            issues.append(CoverageIssue(severity: severity, message: message, file: file, line: line, kind: .coverage))
        }
        if let redundancy = scores.redundancy,
           let severity = Self.severity(of: redundancy, warning: settings.redundancyWarningLevel, error: settings.redundancyErrorLevel, isLowerWorse: false) {
            let reason = scores.isMutationAware
                ? " are redundant or overlap another, by the code they run after the Background and the mutants they detect"
                : " are redundant, because other scenarios run all the code they run after the Background"
            let message = "\(subject) redundancy: \(Self.percent(redundancy)) of its scenarios\(reason)\(Self.wasted(scores))"
                + " (\(Self.levels(warning: settings.redundancyWarningLevel, error: settings.redundancyErrorLevel, comparison: "at or above")))."
            issues.append(CoverageIssue(severity: severity, message: message, file: file, line: line, kind: .redundancy))
        }
        for step in scores.redundantSteps {
            guard let severity = Self.severity(of: step.percent, warning: settings.redundantStepWarningLevel, error: .off, isLowerWorse: false) else { continue }
            let message = "Redundant step. \(Self.percent(step.percent)) of the code in this step is repeated by the step at line \(step.similarTo). "
                + (step.suggestsOutline ? "Consider a Scenario Outline for different values." : "Consider moving it to the Background.")
            issues.append(CoverageIssue(severity: severity, message: message, file: file, line: step.line, kind: .redundancy))
        }
        if settings.redundancyWarningLevel != .off {
            issues += scenarioWarnings(file: file)
        }
        return issues
    }

    /// A warning at each scenario that adds nothing of its own, and at each that overlaps another.
    private func scenarioWarnings(file: URL?) -> [CoverageIssue] {
        var issues = [CoverageIssue]()
        // A Scenario Outline's examples get one warning between them, at the first, with their time.
        var warned = Set<String>()
        for scenario in scores.scenarios where scenario.addsNothing && warned.insert(scenario.group).inserted {
            let time = scores.scenarios.filter { $0.group == scenario.group }.reduce(0) { $0 + $1.duration }
            let message = scores.isMutationAware
                ? "Scenario adds nothing of its own: other scenarios run all the code it runs after the Background, and"
                    + " fail on every mutant it fails on."
                : "Scenario adds no coverage of its own: other scenarios run all the code it runs after the Background."
            issues.append(CoverageIssue(severity: .warning,
                                        message: message + " It took \(Self.seconds(time)). Consider a Scenario Outline for other values, or remove it.",
                                        file: file,
                                        line: scenario.line,
                                        kind: .redundancy))
        }
        for scenario in scores.scenarios {
            guard let overlap = scenario.overlap, warned.insert(scenario.group).inserted else { continue }
            issues.append(CoverageIssue(severity: .warning, message: Self.message(for: overlap), file: file, line: scenario.line, kind: .redundancy))
        }
        return issues
    }
}
