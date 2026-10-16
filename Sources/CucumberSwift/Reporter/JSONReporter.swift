//
//  JSONReporter.swift
//  
//
//  Created by Tyler Thompson on 5/23/21.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation

public class CucumberJSONReporter: CucumberTestObserver {
    private let explicitReportURL: URL?
    private let defaultReportURL: URL
    /// Where the report is written: the path it was made with, else ``Cucumber/reportPath``, else the
    /// default. Read each time, because the reporter is made before `setupSteps()` sets the static variable.
    var reportURL: URL {
        if let explicitReportURL { return explicitReportURL }
        if let path = FeatureFlags.reportPath { return URL(fileURLWithPath: path) }
        return defaultReportURL
    }
    var features: [Feature] { recorder.features }
    private let recorder: CucumberJSONRecorder

    private static func makeRecorder(explicit: URL?, default defaultURL: URL) -> CucumberJSONRecorder {
        CucumberJSONRecorder(reportURL: {
            if let explicit { return explicit }
            if let path = FeatureFlags.reportPath { return URL(fileURLWithPath: path) }
            return defaultURL
        }, isParallel: { FeatureFlags.isParallelTesting })
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

    public func testSuiteStarted(at: Date) {
        recorder.suiteStarted()
    }

    public func testSuiteFinished(at: Date) {
        recorder.suiteFinished()
    }

    public func didStart(feature: CucumberSwift.Feature, at date: Date) {
        recorder.featureStarted(ObjectIdentifier(feature)) { Feature(feature) }
    }

    public func didStart(scenario: CucumberSwift.Scenario, at date: Date) {
        let owner = scenario.feature.map { feature in (key: ObjectIdentifier(feature), make: { Feature(feature) }) }
        recorder.scenarioStarted(ObjectIdentifier(scenario), feature: owner) { Scenario(scenario) }
    }

    public func didStart(step: CucumberSwift.Step, at date: Date) {
        recorder.stepStarted(ObjectIdentifier(step), scenario: step.scenario.map { ObjectIdentifier($0) }) { Step(step) }
    }

    public func didFinish(feature: CucumberSwift.Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder.featureFinished()
    }

    public func didFinish(scenario: CucumberSwift.Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder.scenarioFinished()
    }

    public func didFinish(step: CucumberSwift.Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder.stepFinished(ObjectIdentifier(step), result: result, duration: duration)
    }
}

extension CucumberJSONReporter {
    typealias Tag = CucumberJSONReport.Tag
    typealias Feature = CucumberJSONReport.Feature
    typealias Scenario = CucumberJSONReport.Scenario
    typealias Step = CucumberJSONReport.Step
}

extension CucumberJSONReport.Feature {
    convenience init(_ feature: CucumberSwift.Feature) {
        self.init(uri: feature.uri,
                  title: feature.title,
                  description: feature.desc,
                  line: feature.location.line,
                  tags: feature.tags)
    }
}

extension CucumberJSONReport.Scenario {
    convenience init(_ scenario: CucumberSwift.Scenario) {
        self.init(title: scenario.title, line: scenario.location.line, tags: scenario.tags)
    }
}

extension CucumberJSONReport.Step {
    convenience init(_ step: CucumberSwift.Step) {
        self.init(name: step.match, keyword: step.writtenKeyword, line: step.location.line)
    }
}
