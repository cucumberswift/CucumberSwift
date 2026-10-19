//
//  JSONReporter.swift
//  CucumberSwiftTesting
//
// Writes the Cucumber JSON report as CucumberSwift does: the report's contents and the code that builds
// and writes it are CucumberSwift's own (Reporter/Core, shared through a symlink), so both runners write
// the same report for the same feature files.

import Foundation

/// Writes the Cucumber JSON report while the tests run. The runner installs one that writes to
/// ``Cucumber/reportPath``, or `CUCUMBER_REPORT_PATH`, or `_cucumberReport.json` in the documents folder;
/// make another with ``init(reportPath:)`` to write a second copy somewhere else.
///
/// Swift Testing runs the tests of a process together, so the report is written as the scenarios finish
/// and holds each scenario once, with the features and scenarios in the order of their feature files,
/// whichever test ran first.
public final class CucumberJSONReporter: CucumberTestObserver {
    private let explicitReportURL: URL?
    private let defaultReportURL: URL
    /// Where the report is written: the path it was made with, else ``Cucumber/reportPath``, else the
    /// default. Read each time, because the reporter is made before `setupSteps()` sets the static variable.
    var reportURL: URL {
        if let explicitReportURL { return explicitReportURL }
        if let path = CucumberSettings.reportPath { return URL(fileURLWithPath: path) }
        return defaultReportURL
    }
    private let recorder: CucumberJSONRecorder

    private static func makeRecorder(explicit: URL?, default defaultURL: URL) -> CucumberJSONRecorder {
        CucumberJSONRecorder(reportURL: {
            if let explicit { return explicit }
            if let path = CucumberSettings.reportPath { return URL(fileURLWithPath: path) }
            return defaultURL
            // Swift Testing doesn't promise the order of the tests in a suite.
        }, ordersByFile: true)
    }

    private static func entry(for feature: Feature) -> CucumberJSONReport.Feature {
        CucumberJSONReport.Feature(uri: uri(of: feature),
                                   title: feature.title,
                                   description: feature.desc,
                                   line: line(feature.location),
                                   tags: feature.tags)
    }

    /// A feature file's URI as CucumberSwift writes it: the `file://` URL of its copy in the test bundle, or
    /// of its path when the runner doesn't know the test bundle.
    private static func uri(of feature: Feature) -> String {
        if let reportURI = feature.reportURI { return reportURI }
        return feature.uri.contains("://") ? feature.uri : URL(fileURLWithPath: feature.uri).absoluteString
    }

    private static func line(_ location: Location) -> UInt {
        UInt(max(location.line, 0))
    }

    public init?() {
        guard let defaultURL = CucumberJSONReport.defaultURL else { return nil }
        explicitReportURL = nil
        defaultReportURL = defaultURL
        recorder = Self.makeRecorder(explicit: nil, default: defaultURL)
    }

    public init(reportPath: URL) {
        explicitReportURL = reportPath
        defaultReportURL = reportPath
        recorder = Self.makeRecorder(explicit: reportPath, default: reportPath)
    }

    public func testSuiteStarted(at _: Date) {
        recorder.suiteStarted()
    }

    public func testSuiteFinished(at _: Date) {
        recorder.suiteFinished()
    }

    public func didStart(feature: Feature, at _: Date) {
        recorder.featureStarted(ObjectIdentifier(feature)) { Self.entry(for: feature) }
    }

    public func didStart(scenario: Scenario, at _: Date) {
        let owner = scenario.feature.map { feature in (key: ObjectIdentifier(feature), make: { Self.entry(for: feature) }) }
        recorder.scenarioStarted(ObjectIdentifier(scenario), feature: owner) {
            CucumberJSONReport.Scenario(title: scenario.title, line: Self.line(scenario.location), tags: scenario.tags)
        }
    }

    public func didStart(step: Step, at _: Date) {
        recorder.stepStarted(ObjectIdentifier(step), scenario: step.scenario.map { ObjectIdentifier($0) }) {
            CucumberJSONReport.Step(name: step.match, keyword: step.keywordName, line: Self.line(step.location))
        }
    }

    public func didFinish(feature _: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        recorder.featureFinished()
    }

    public func didFinish(scenario _: Scenario, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        recorder.scenarioFinished()
    }

    public func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder.stepFinished(ObjectIdentifier(step), result: result, duration: duration)
    }
}
