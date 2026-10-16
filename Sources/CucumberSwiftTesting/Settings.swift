//
//  Settings.swift
//  CucumberSwiftTesting
//
// The settings the runner reads besides CUCUMBER_TAGS, named as in CucumberSwift.

import Foundation

/// The static variables' values. Computed static variables over locked storage are safe to read and set
/// from any isolation, and don't warn in a consumer's Swift 6 target, as stored ones on a main-actor
/// class would.
enum CucumberSettings {
    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var storedReportPath: String?
        private var storedVerboseOutput = false

        var reportPath: String? {
            get { lock.withLock { storedReportPath } }
            set { lock.withLock { storedReportPath = newValue } }
        }

        var verboseOutput: Bool {
            get { lock.withLock { storedVerboseOutput } }
            set { lock.withLock { storedVerboseOutput = newValue } }
        }
    }

    private static let storage = Storage()

    static let reportPathEnvironmentKey = "CUCUMBER_REPORT_PATH"

    /// ``Cucumber/reportPath``.
    static var staticReportPath: String? {
        get { storage.reportPath }
        set { storage.reportPath = newValue }
    }

    static var staticVerboseOutput: Bool {
        get { storage.verboseOutput }
        set { storage.verboseOutput = newValue }
    }

    static var reportPath: String? { reportPath() }

    /// Where the JSON report is written: the static variable, then `CUCUMBER_REPORT_PATH`. Nil when neither
    /// is set, or is empty, so the report goes to its default place.
    static func reportPath(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let path = staticReportPath ?? environment[reportPathEnvironmentKey]
        let trimmed = path?.trimmingCharacters(in: .whitespaces)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

extension Cucumber {
    /// Where the Cucumber JSON report is written, a full path to a file, such as
    /// `/Users/me/reports/cucumber.json`. Without it the report is `_cucumberReport.json` in the documents
    /// folder. Set this, or the environment variable `CUCUMBER_REPORT_PATH`, to write it somewhere else; the
    /// runner creates the folder. This variable, when set, wins over the environment variable. Set it in
    /// your `StepImplementation`'s `setupSteps()`. A reporter made with
    /// ``CucumberJSONReporter/init(reportPath:)`` keeps the path it was given.
    nonisolated public static var reportPath: String? {
        get { CucumberSettings.staticReportPath }
        set { CucumberSettings.staticReportPath = newValue }
    }

    /// Whether the runner prints each feature, scenario and step, with its result and duration, as it
    /// runs. Off by default. The `CUCUMBER_VERBOSE` environment variable (`1` or `true`) and
    /// ``StepImplementation/verbose`` turn it on too.
    nonisolated public static var verboseOutput: Bool {
        get { CucumberSettings.staticVerboseOutput }
        set { CucumberSettings.staticVerboseOutput = newValue }
    }
}
