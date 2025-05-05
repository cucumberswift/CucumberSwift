//
//  JSONReporter.swift
//  
//
//  Created by Tyler Thompson on 5/23/21.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation

public class CucumberJSONReporter: CucumberTestObserver {
    let reportURL: URL
    private(set) var features: [Feature] = []
    private var currentFeature: Feature?
    private var currentScenario: Scenario?
    private var currentStep: Step?
    private var encoder: JSONEncoder = {
        var encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    public init?() {
        let name = "_cucumberReport".appending(".json")
        if let documentDirectory = try? FileManager.default.url(for: .documentDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: nil,
                                                                create: false) {
            reportURL = documentDirectory.appendingPathComponent(name)
        } else {
            return nil
        }
    }

    public init(reportPath: URL) {
        reportURL = reportPath
    }

    public func testSuiteStarted(at: Date) {
        defer { try? encoder.encode(features).write(to: reportURL) }
        features.removeAll()
    }

    public func testSuiteFinished(at: Date) {
        try? encoder.encode(features).write(to: reportURL)
    }

    public func didStart(feature: CucumberSwift.Feature, at date: Date) {
        defer { try? encoder.encode(features).write(to: reportURL) }
        features.append(Feature(feature))
        currentFeature = features.last
    }

    public func didStart(scenario: CucumberSwift.Scenario, at date: Date) {
        defer { try? encoder.encode(features).write(to: reportURL) }
        currentFeature?.elements.append(Scenario(scenario))
        currentScenario = currentFeature?.elements.last
    }

    public func didStart(step: CucumberSwift.Step, at date: Date) {
        defer { try? encoder.encode(features).write(to: reportURL) }
        currentScenario?.steps.append(Step(step))
        currentStep = currentScenario?.steps.last
    }

    public func didFinish(feature: CucumberSwift.Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        try? encoder.encode(features).write(to: reportURL)
    }

    public func didFinish(scenario: CucumberSwift.Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        try? encoder.encode(features).write(to: reportURL)
    }

    public func didFinish(step: CucumberSwift.Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        defer { try? encoder.encode(features).write(to: reportURL) }
        currentStep?.result = result
        currentStep?.duration = duration
    }
}

extension CucumberJSONReporter {
    struct Tag: Encodable {
        let line: UInt
        let name: String
    }
    class Feature: Encodable {
        let uri: String
        let id: String
        let name: String
        let description: String
        let keyword: String = "Feature"
        var elements: [Scenario] = []
        let line: UInt
        var tags: [Tag] = []

        init(_ feature: CucumberSwift.Feature) {
            uri = feature.uri
//            #warning("Add better id logic so all whitespace is replaced")
            id = feature.title.lowercased().replacingOccurrences(of: " ", with: "-")
            name = feature.title
            description = feature.desc
            line = feature.location.line
            tags = feature.tags.map { Tag(line: 1, name: $0) }
        }
    }

    class Scenario: Encodable {
        let id: String
        let keyword = "Scenario"
        let type = "scenario"
        let name: String
        let description: String
        var steps: [Step] = []
        var line: UInt
        var tags: [Tag] = []

        init(_ scenario: CucumberSwift.Scenario) {
//            #warning("Add better id logic so all whitespace is replaced")
            id = scenario.title.lowercased().replacingOccurrences(of: " ", with: "-")
            name = scenario.title
//            #warning("Fix this")
            description = ""
            line = scenario.location.line
            tags = scenario.tags.map { Tag(line: 1, name: $0) }
        }
    }

    class Step: Encodable {
        enum CodingKeys: String, CodingKey {
            case result
            case name
            case keyword
            case line
            case arguments
        }

        enum ResultKeys: String, CodingKey {
            case status
            case errorMessage = "error_message"
            case duration
        }

        var result = Reporter.Result.pending
        var duration: Measurement<UnitDuration>?
        var name: String
        var keyword: CucumberSwift.Step.Keyword
        var line: UInt
        var arguments: [String]

        init(_ step: CucumberSwift.Step) {
            name = step.match
            keyword = step.keyword
            line = step.location.line
            arguments = []
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            var resultContainer = container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            switch result {
                case .passed: try resultContainer.encode("passed", forKey: .status)
                case .failed(let err):
                    try resultContainer.encode("failed", forKey: .status)
                    try resultContainer.encode(err?.description, forKey: .errorMessage)
                case .skipped: try resultContainer.encode("skipped", forKey: .status)
                case .pending: try resultContainer.encode("pending", forKey: .status)
                case .undefined: try resultContainer.encode("undefined", forKey: .status)
                case .ambiguous: try resultContainer.encode("ambiguous", forKey: .status)
            }
            if let duration = duration {
                if #available(iOS 13.0, macOS 10.15, tvOS 13, *) {
                    try resultContainer.encode(duration.converted(to: .nanoseconds).value, forKey: .duration)
                } else {
                    try resultContainer.encode(duration.converted(to: .seconds).value * 1_000_000_000, forKey: .duration)
                }
            }

            try container.encode(name, forKey: .name)
//            #warning("Fix this")
            try container.encode(keyword.toString(), forKey: .keyword)
            try container.encode(line, forKey: .line)
            try container.encode(arguments, forKey: .arguments)
        }
    }
}
