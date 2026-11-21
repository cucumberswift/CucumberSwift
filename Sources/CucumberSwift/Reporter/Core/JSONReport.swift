//
//  JSONReport.swift
//  CucumberSwift
//
//  The Cucumber JSON report: what it holds, and the recorder that builds it from a run's events and writes
//  it. CucumberSwift and CucumberSwiftTesting compile this file both, through a symlink, so the two runners
//  write the same report. It imports only Foundation: each runner's observer turns its own features,
//  scenarios and steps into the plain values here.
//

import Foundation

enum CucumberJSONReport {
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

        init(uri: String, title: String, description: String, line: UInt, tags: [String]) {
            self.uri = uri
//            #warning("Add better id logic so all whitespace is replaced")
            id = title.lowercased().replacingOccurrences(of: " ", with: "-")
            name = title
            self.description = description
            self.line = line
            self.tags = tags.map { Tag(line: 1, name: $0) }
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

        init(title: String, line: UInt, tags: [String]) {
//            #warning("Add better id logic so all whitespace is replaced")
            id = title.lowercased().replacingOccurrences(of: " ", with: "-")
            name = title
//            #warning("Fix this")
            description = ""
            self.line = line
            self.tags = tags.map { Tag(line: 1, name: $0) }
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
        var keyword: String
        var line: UInt
        var arguments: [String]

        init(name: String, keyword: String, line: UInt) {
            self.name = name
            self.keyword = keyword
            self.line = line
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
            try container.encode(keyword, forKey: .keyword)
            try container.encode(line, forKey: .line)
            try container.encode(arguments, forKey: .arguments)
        }
    }

    /// The report's default place: `_cucumberReport.json` in the documents folder. `nil` where there is
    /// no documents folder.
    static var defaultURL: URL? {
        let name = "_cucumberReport".appending(".json")
        guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory,
                                                                   in: .userDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: false) else { return nil }
        return documentDirectory.appendingPathComponent(name)
    }
}

/// Builds the report from a run's events, and writes it.
///
/// Each runner's observer calls it on the main actor, so it needs no lock of its own; what it shares with
/// other writers, the report file, `ReportFile` locks.
final class CucumberJSONRecorder {
    /// Identifies what an event is about, as the runner's own object does: the feature, scenario or step.
    typealias Key = ObjectIdentifier

    private let reportURL: () -> URL
    private let runner: String
    private let isParallel: () -> Bool
    private let staleAfter: () -> TimeInterval

    private(set) var features: [CucumberJSONReport.Feature] = []
    private var currentFeature: CucumberJSONReport.Feature?
    private var currentScenario: CucumberJSONReport.Scenario?
    private var currentStep: CucumberJSONReport.Step?
    /// The report's entry for each feature, scenario and step, by the object it describes. In a parallel
    /// run a worker runs scenarios of several features in turn, so the feature that started last is not
    /// always the feature of the scenario that starts now.
    private var featureEntries = [Key: CucumberJSONReport.Feature]()
    private var scenarioEntries = [Key: CucumberJSONReport.Scenario]()
    private var stepEntries = [Key: CucumberJSONReport.Step]()
    private let encoder: JSONEncoder = {
        var encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    /// - Parameters:
    ///   - reportURL: Asked each time the report is written, because the setting that decides it can
    ///     change after the recorder exists.
    ///   - runner: The runner that writes the report: `XCTest` or `Swift Testing`.
    ///   - isParallel: Whether this process is one of several parallel workers, which keep their features
    ///     when the suite starts again.
    ///   - staleAfter: Asked when the suite starts: how long a report can go unwritten before this process
    ///     takes it for an earlier run's, when no other rule decides.
    init(reportURL: @escaping () -> URL,
         runner: String,
         isParallel: @escaping () -> Bool = { false },
         staleAfter: @escaping () -> TimeInterval = { ReportFile.staleAfter }) {
        self.reportURL = reportURL
        self.runner = runner
        self.isParallel = isParallel
        self.staleAfter = staleAfter
    }

    // MARK: Events

    /// Joins the run that writes the report, which empties the report an earlier run left (#546).
    func suiteStarted() {
        ReportFile.at(reportURL()).joinRun(runner: runner, isParallel: isParallel(), staleAfter: staleAfter())
        defer { save() }
        // XCTest asks for CucumberTest's suite again while a parallel worker runs scenarios. Clearing the
        // features then would leave the scenario in progress with a feature that is no longer in the
        // report, and lose the rest of the worker's scenarios.
        guard !isParallel() else { return }
        features.removeAll()
        currentFeature = nil
        currentScenario = nil
        currentStep = nil
        featureEntries.removeAll()
        scenarioEntries.removeAll()
        stepEntries.removeAll()
    }

    func suiteFinished() {
        save()
    }

    func featureStarted(_ key: Key, make: () -> CucumberJSONReport.Feature) {
        currentFeature = entry(forFeature: key, make: make)
    }

    func scenarioStarted(_ key: Key,
                         feature: (key: Key, make: () -> CucumberJSONReport.Feature)?,
                         make: () -> CucumberJSONReport.Scenario) {
        let owner = feature.map { entry(forFeature: $0.key, make: $0.make) } ?? currentFeature
        let scenario = make()
        owner?.elements.append(scenario)
        scenarioEntries[key] = scenario
        currentScenario = scenario
        // A scenario that crashes the process is in the report, with the steps of an earlier write.
        save()
    }

    func stepStarted(_ key: Key, scenario: Key?, make: () -> CucumberJSONReport.Step) {
        let owner = scenario.flatMap { scenarioEntries[$0] } ?? currentScenario
        let step = make()
        owner?.steps.append(step)
        stepEntries[key] = step
        currentStep = step
    }

    func featureFinished() {
        save()
    }

    func scenarioFinished() {
        save()
    }

    func stepFinished(_ key: Key, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        let entry = stepEntries[key] ?? currentStep
        entry?.result = result
        entry?.duration = duration
    }

    /// The report's entry for a feature, added the first time it is asked for.
    private func entry(forFeature key: Key, make: () -> CucumberJSONReport.Feature) -> CucumberJSONReport.Feature {
        if let existing = featureEntries[key], features.contains(where: { $0 === existing }) {
            return existing
        }
        let feature = make()
        features.append(feature)
        featureEntries[key] = feature
        return feature
    }

    // MARK: Writing

    /// Writes the report. Every process of a test run writes to the same file: each parallel worker, and each
    /// test target's process, whichever runner it uses. So this merges the process's features into the report
    /// under a lock, which puts the features and scenarios in the order of their files, whichever ran first.
    ///
    /// It merges only where a scenario starts or finishes, where a feature finishes, and where the suite starts
    /// and finishes: a merge reads, parses, sorts and rewrites the whole report, and a merge for every step
    /// would grow with the report. A scenario whose process was killed is in the report without the steps
    /// that it ran; every scenario that finished is there whole.
    private func save() {
        guard let data = try? encoder.encode(features),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        ReportFile.at(reportURL()).merge(json)
    }
}
