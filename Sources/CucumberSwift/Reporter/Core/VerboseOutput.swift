//
//  VerboseOutput.swift
//  CucumberSwift
//
//  What verbose output prints, in the words and layout both runners use. CucumberSwift and
//  CucumberSwiftTesting compile this file both, through a symlink: each runner's observer gives it plain
//  values, so a log reads the same whichever runner wrote it.
//

import Foundation

struct VerboseOutput {
    static let environmentKey = "CUCUMBER_VERBOSE"

    private let isEnabled: () -> Bool
    private let output: (String) -> Void

    /// Whether the environment asks for verbose output: `CUCUMBER_VERBOSE` is `1` or `true`.
    static func isEnabled(in environment: [String: String]) -> Bool {
        guard let value = environment[environmentKey]?.trimmingCharacters(in: .whitespaces).lowercased() else { return false }
        return value == "1" || value == "true"
    }

    private static func describe(_ result: Reporter.Result) -> String {
        switch result {
            case .passed: return "passed"
            case .failed(let message): return message.map { "failed: \($0)" } ?? "failed"
            case .skipped: return "skipped"
            case .pending: return "pending"
            case .undefined: return "undefined"
            case .ambiguous: return "ambiguous"
        }
    }

    private static func format(_ duration: Measurement<UnitDuration>) -> String {
        "(\(String(format: "%.3f", duration.converted(to: .seconds).value))s)"
    }

    /// - Parameter isEnabled: Asked before every line, because the setting can change after the output
    ///   exists: `setupSteps()` runs after the runner has built its reporters.
    init(isEnabled: @escaping () -> Bool = { true }, write: @escaping (String) -> Void = { print($0); fflush(stdout) }) {
        self.isEnabled = isEnabled
        self.output = write
    }

    private func write(_ line: String) {
        if isEnabled() { output(line) }
    }

    func suiteStarted() { write("[CucumberSwift] Test suite started") }
    func suiteFinished() { write("[CucumberSwift] Test suite finished") }

    func featureStarted(title: String) {
        write("[CucumberSwift] Feature: \(title)")
    }

    func scenarioStarted(title: String) {
        write("[CucumberSwift]   Scenario: \(title)")
    }

    func stepStarted(keyword: String, match: String) {
        write("[CucumberSwift]     \(keyword) \(match)")
    }

    func featureFinished(title: String, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift] Feature \"\(title)\" \(Self.describe(result)) \(Self.format(duration))")
    }

    func scenarioFinished(title: String, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift]   Scenario \"\(title)\" \(Self.describe(result)) \(Self.format(duration))")
    }

    func stepFinished(result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift]       -> \(Self.describe(result)) \(Self.format(duration))")
    }
}
