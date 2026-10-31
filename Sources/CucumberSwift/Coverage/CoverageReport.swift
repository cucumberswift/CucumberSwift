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
        /// A feature's or a Rule's redundancy.
        case redundancy
        /// A scenario that adds no coverage of its own.
        case redundantScenario
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

    /// The time the redundant scenarios took, of all the scenarios' time, such as ", about 0.42 s of 1.26 s
    /// in redundant scenarios", or nothing with the redundancy score off.
    static func wasted(_ scores: CoverageScores) -> String {
        guard let wasted = scores.wastedTime else { return "" }
        return ", about \(seconds(wasted)) of \(seconds(scores.duration)) in redundant scenarios"
    }

    static func seconds(_ value: TimeInterval) -> String {
        String(format: "%.2f s", value)
    }

    /// `text` with spaces before it, to `width` characters.
    static func padded(_ text: String, _ width: Int) -> String {
        text.count >= width ? text : String(repeating: " ", count: width - text.count) + text
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
            let note = scenario.addsNothing ? ", adds no coverage of its own" : ""
            lines.append("\(share)\(own)\(time)  \(scenario.name) (line \(scenario.line)\(note))")
        }
        return lines.joined(separator: "\n")
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
            let message = "\(subject) redundancy \(Self.percent(redundancy)): \(Self.percent(redundancy)) of its scenarios run no code,"
                + " after their Background steps, that other scenarios don't run\(Self.wasted(scores))"
                + " (\(Self.levels(warning: settings.redundancyWarningLevel, error: settings.redundancyErrorLevel, comparison: "at or above")))."
            issues.append(CoverageIssue(severity: severity, message: message, file: file, line: line, kind: .redundancy))
        }
        if settings.redundancyWarningLevel != .off {
            // A Scenario Outline's examples get one warning between them, at the first, with their time.
            var warned = Set<String>()
            for scenario in scores.scenarios where scenario.addsNothing && warned.insert(scenario.group).inserted {
                let time = scores.scenarios.filter { $0.group == scenario.group }.reduce(0) { $0 + $1.duration }
                let message = "Scenario adds no coverage of its own: other scenarios run all of the code it runs after its Background steps."
                    + String(format: " It took %.2fs.", time)
                issues.append(CoverageIssue(severity: .warning, message: message, file: file, line: scenario.line, kind: .redundantScenario))
            }
        }
        return issues
    }
}
