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
    private let isParallel: () -> Bool
    private let ordersByFile: Bool

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
    ///   - isParallel: Whether this process is one of several workers that write the report. Then a write
    ///     merges into the report under a lock instead of replacing it.
    ///   - ordersByFile: Whether a serial write puts the features and scenarios in the order of their files,
    ///     whichever ran first. A runner that doesn't promise an order of its tests turns it on.
    init(reportURL: @escaping () -> URL, isParallel: @escaping () -> Bool = { false }, ordersByFile: Bool = false) {
        self.reportURL = reportURL
        self.isParallel = isParallel
        self.ordersByFile = ordersByFile
    }

    // MARK: Events

    func suiteStarted() {
        if isParallel() {
            // XCTest asks for CucumberTest's suite again while a worker runs scenarios. Clearing the
            // features then would leave the scenario in progress with a feature that is no longer in the
            // report, and lose the rest of the worker's scenarios. The report is where the run starts over.
            ReportFile.at(reportURL()).joinRun()
            save(atBoundary: true)
            return
        }
        // Clears a stale report before the run, whichever kind of run it is.
        defer { save(atBoundary: true) }
        features.removeAll()
        currentFeature = nil
        currentScenario = nil
        currentStep = nil
        featureEntries.removeAll()
        scenarioEntries.removeAll()
        stepEntries.removeAll()
    }

    func suiteFinished() {
        save(atBoundary: true)
    }

    func featureStarted(_ key: Key, make: () -> CucumberJSONReport.Feature) {
        defer { save() }
        currentFeature = entry(forFeature: key, make: make)
    }

    func scenarioStarted(_ key: Key,
                         feature: (key: Key, make: () -> CucumberJSONReport.Feature)?,
                         make: () -> CucumberJSONReport.Scenario) {
        defer { save() }
        let owner = feature.map { entry(forFeature: $0.key, make: $0.make) } ?? currentFeature
        let scenario = make()
        owner?.elements.append(scenario)
        scenarioEntries[key] = scenario
        currentScenario = scenario
    }

    func stepStarted(_ key: Key, scenario: Key?, make: () -> CucumberJSONReport.Step) {
        defer { save() }
        let owner = scenario.flatMap { scenarioEntries[$0] } ?? currentScenario
        let step = make()
        owner?.steps.append(step)
        stepEntries[key] = step
        currentStep = step
    }

    func featureFinished() {
        save(atBoundary: true)
    }

    func scenarioFinished() {
        save(atBoundary: true)
    }

    func stepFinished(_ key: Key, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        defer { save() }
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

    /// Writes the report. With parallel testing on, every worker writes to the same file, so this merges
    /// the worker's features into it under a lock; otherwise it is the run's only writer and replaces it.
    ///
    /// A parallel run merges only where a scenario or a feature finishes, and where the worker's suite
    /// starts and finishes: a merge reads, parses and rewrites the whole report, and a merge for every step
    /// of every worker would grow with the report. A run that orders the report by file does the same, for the
    /// same reason: it sorts and rewrites the whole report each time. A scenario that never finishes, because
    /// its worker was killed, isn't in the report; every scenario that finished is.
    private func save(atBoundary: Bool = false) {
        let isParallel = isParallel()
        if (isParallel || ordersByFile) && !atBoundary { return }
        guard let data = try? encoder.encode(features),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        let url = reportURL()
        if isParallel {
            ReportFile.at(url).merge(json)
        } else {
            // Written by the same code as a parallel run's report, so the two are the same bytes.
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                let report = ordersByFile ? ReportFile.merge(json, into: []) : json
                try ReportFile.serialize(report)?.write(to: url, options: .atomic)
            } catch {
                ReportFile.warn(url, error.localizedDescription)
            }
        }
    }
}
