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
    static let sourcesVariable = "CUCUMBER_COVERAGE_SOURCES"

    static let storage = Storage()

    /// A feature whose coverage is at or below this gets a warning.
    var warningLevel: CoverageLevel = 80
    /// A feature whose coverage is at or below this gets an error, which fails a test.
    var errorLevel: CoverageLevel = 50
    var isRedundancy = false
    /// A feature whose redundancy is at or above this gets a warning, and so does each scenario that adds
    /// no coverage of its own.
    var redundancyWarningLevel: CoverageLevel = 30
    /// A feature whose redundancy is at or above this gets an error.
    var redundancyErrorLevel: CoverageLevel = .off
    /// Parts of the paths of the files to measure. Empty to measure the default files.
    var sources = [String]()

    /// The settings: each static variable, then its environment variable, then its default.
    static func read(environment: [String: String]) -> CoverageSettings {
        var settings = CoverageSettings()
        func level(_ name: String, _ variable: String, _ defaultLevel: CoverageLevel) -> CoverageLevel {
            storage.level(name) ?? CoverageLevel(environment[variable]) ?? defaultLevel
        }
        settings.warningLevel = level("warning", warningLevelVariable, settings.warningLevel)
        settings.errorLevel = level("error", errorLevelVariable, settings.errorLevel)
        settings.isRedundancy = storage.redundancy ?? FeatureFlagValue.bool(environment[redundancyVariable]) ?? false
        settings.redundancyWarningLevel = level("redundancyWarning", redundancyWarningLevelVariable, settings.redundancyWarningLevel)
        settings.redundancyErrorLevel = level("redundancyError", redundancyErrorLevelVariable, settings.redundancyErrorLevel)
        settings.sources = (storage.sources ?? environment[sourcesVariable].map { $0.components(separatedBy: ",") } ?? [])
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return settings
    }
}
