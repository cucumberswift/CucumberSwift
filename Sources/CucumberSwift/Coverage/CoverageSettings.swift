//
//  CoverageSettings.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink. Each runner
//  declares the public static variables on its own `Cucumber`, over the storage here.
//

import Foundation

/// A level that a coverage score is checked against, in percent, or `off` to not check it. Write a
/// number for a level, such as `Cucumber.coverageWarningLevel = 70`.
public enum CoverageLevel: Equatable, Sendable, ExpressibleByIntegerLiteral {
    case percent(Int)
    case off

    public init(integerLiteral value: Int) {
        self = .percent(value)
    }

    /// A number from 0 to 100, or `NO`, `OFF` or `FALSE` in any case, with spaces around it ignored. Any
    /// other value is not a level.
    init?(_ text: String?) {
        guard let text = text?.trimmingCharacters(in: .whitespaces) else { return nil }
        if ["NO", "OFF", "FALSE"].contains(text.uppercased()) {
            self = .off
        } else if let value = Int(text), (0...100).contains(value) {
            self = .percent(value)
        } else {
            return nil
        }
    }
}

/// What the coverage scores are checked against, and the code they measure.
struct CoverageSettings: Equatable {
    /// The static variables' values, which win over the environment variables.
    final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var levels = [String: CoverageLevel]()
        private var storedRedundancy: Bool?
        private var storedSources: [String]?
        private var storedRecordsIssuesInSuites: Bool?
        private var storedMutationReport: String?
        private var storedMutationTesting: Bool?

        var mutationTesting: Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedMutationTesting
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedMutationTesting = newValue
            }
        }

        var mutationReport: String? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedMutationReport
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedMutationReport = newValue
            }
        }

        var recordsIssuesInSuites: Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedRecordsIssuesInSuites
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedRecordsIssuesInSuites = newValue
            }
        }

        var redundancy: Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedRedundancy
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedRedundancy = newValue
            }
        }

        var sources: [String]? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedSources
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedSources = newValue
            }
        }

        func level(_ name: String) -> CoverageLevel? {
            lock.lock()
            defer { lock.unlock() }
            return levels[name]
        }

        func setLevel(_ name: String, _ value: CoverageLevel?) {
            lock.lock()
            defer { lock.unlock() }
            levels[name] = value
        }
    }

    static let warningLevelVariable = "CUCUMBER_COVERAGE_WARNING_LEVEL"
    static let errorLevelVariable = "CUCUMBER_COVERAGE_ERROR_LEVEL"
    static let redundancyVariable = "CUCUMBER_REDUNDANCY"
    static let redundancyWarningLevelVariable = "CUCUMBER_REDUNDANCY_WARNING_LEVEL"
    static let redundancyErrorLevelVariable = "CUCUMBER_REDUNDANCY_ERROR_LEVEL"
    static let redundantStepWarningLevelVariable = "CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL"
    static let sourcesVariable = "CUCUMBER_COVERAGE_SOURCES"
    static let recordsIssuesInSuitesVariable = "CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES"
    static let mutationReportVariable = "CUCUMBER_MUTATION_REPORT"
    static let mutationTestingVariable = "CUCUMBER_MUTATION_TESTING"

    static let storage = Storage()

    /// A feature whose coverage is at or below this gets a warning.
    var warningLevel: CoverageLevel = 80
    /// A feature whose coverage is at or below this gets an error, which fails a test. Off by default, so
    /// that coverage only warns until a project sets a level (#507).
    var errorLevel: CoverageLevel = .off
    /// On by default. It has no effect with coverage off, which scores nothing.
    var isRedundancy = true
    /// A feature whose redundancy is at or above this gets a warning, and so does each scenario that adds
    /// no coverage of its own.
    var redundancyWarningLevel: CoverageLevel = 30
    /// A feature whose redundancy is at or above this gets an error.
    var redundancyErrorLevel: CoverageLevel = .off
    /// A step outside the Background gets a warning when this share of the code it runs is redundant: the
    /// functions that other scenarios run in exactly the same way.
    var redundantStepWarningLevel: CoverageLevel = 50
    /// Why the runner scores nothing, though it writes the coverage files, or nil when it scores.
    var scoresOffReason: String?
    /// Parts of the paths of the files to measure. Empty to measure the default files.
    var sources = [String]()
    /// Whether the Swift Testing runner records a feature's issues on its suite, where an error fails the
    /// suite, instead of printing them. Off by default, because Xcode stops the test process when a suite
    /// records an issue (#509). The XCTest runner doesn't read it.
    var recordsIssuesInSuites = false
    /// Whether each feature gets a Mutation test, with coverage on: off by default.
    var isMutationTesting = false
    /// The Stryker report of a `mutation-test` run, whose mutants the Mutation test checks.
    var mutationReport: String?

    /// The settings: each static variable, then its environment variable, then its default.
    static func read(environment: [String: String]) -> CoverageSettings {
        var settings = CoverageSettings()
        func level(_ name: String, _ variable: String, _ defaultLevel: CoverageLevel) -> CoverageLevel {
            storage.level(name) ?? CoverageLevel(environment[variable]) ?? defaultLevel
        }
        settings.warningLevel = level("warning", warningLevelVariable, settings.warningLevel)
        settings.errorLevel = level("error", errorLevelVariable, settings.errorLevel)
        settings.isRedundancy = storage.redundancy ?? FeatureFlagValue.bool(environment[redundancyVariable]) ?? true
        settings.redundancyWarningLevel = level("redundancyWarning", redundancyWarningLevelVariable, settings.redundancyWarningLevel)
        settings.redundancyErrorLevel = level("redundancyError", redundancyErrorLevelVariable, settings.redundancyErrorLevel)
        settings.redundantStepWarningLevel = level("redundantStepWarning", redundantStepWarningLevelVariable, settings.redundantStepWarningLevel)
        settings.recordsIssuesInSuites = storage.recordsIssuesInSuites
            ?? FeatureFlagValue.bool(environment[recordsIssuesInSuitesVariable]) ?? false
        settings.isMutationTesting = storage.mutationTesting ?? FeatureFlagValue.bool(environment[mutationTestingVariable]) ?? false
        // The static variable wins even when it is blank, as for the sources: it can turn off a path the environment sets.
        settings.mutationReport = (storage.mutationReport ?? environment[mutationReportVariable])
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .flatMap { $0.isEmpty ? nil : $0 }
        settings.sources = (storage.sources ?? environment[sourcesVariable].map { $0.components(separatedBy: ",") } ?? [])
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return settings
    }
}
