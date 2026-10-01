//
//  VerboseReporter.swift
//  CucumberSwift
//
//  Copyright © 2026 Tyler Thompson. All rights reserved.
//

import Foundation

/// Prints each feature, scenario and step as it runs, with its result and duration.
///
/// CucumberSwift installs it when the `CUCUMBER_VERBOSE` environment variable is `1` or `true`, or
/// when your `StepImplementation` returns `true` from `verbose`.
final class VerboseReporter: CucumberTestObserver {
    static let environmentKey = "CUCUMBER_VERBOSE"

    /// Whether the environment asks for verbose output.
    static func isEnabled(in environment: [String: String]) -> Bool {
        guard let value = environment[environmentKey]?.trimmingCharacters(in: .whitespaces).lowercased() else { return false }
        return value == "1" || value == "true"
    }

    private let write: (String) -> Void

    init(write: @escaping (String) -> Void = { print($0); fflush(stdout) }) {
        self.write = write
    }

    func testSuiteStarted(at _: Date) { write("[CucumberSwift] Test suite started") }
    func testSuiteFinished(at _: Date) { write("[CucumberSwift] Test suite finished") }

    func didStart(feature: Feature, at _: Date) {
        write("[CucumberSwift] Feature: \(feature.title)")
    }

    func didStart(scenario: Scenario, at _: Date) {
        write("[CucumberSwift]   Scenario: \(scenario.title)")
    }

    func didStart(step: Step, at _: Date) {
        write("[CucumberSwift]     \(step.keyword.toString()) \(step.match)")
    }

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift] Feature \"\(feature.title)\" \(describe(result)) \(format(duration))")
    }

    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift]   Scenario \"\(scenario.title)\" \(describe(result)) \(format(duration))")
    }

    func didFinish(step _: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        write("[CucumberSwift]       -> \(describe(result)) \(format(duration))")
    }

    private func describe(_ result: Reporter.Result) -> String {
        switch result {
            case .passed: return "passed"
            case .failed(let message): return message.map { "failed: \($0)" } ?? "failed"
            case .skipped: return "skipped"
            case .pending: return "pending"
            case .undefined: return "undefined"
            case .ambiguous: return "ambiguous"
        }
    }

    private func format(_ duration: Measurement<UnitDuration>) -> String {
        "(\(String(format: "%.3f", duration.converted(to: .seconds).value))s)"
    }
}
