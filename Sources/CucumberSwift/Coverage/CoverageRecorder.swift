//
//  CoverageRecorder.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink. Each runner's
//  coverage reporter calls it with plain values, so it uses neither runner's types.
//

import Foundation

/// Writes each scenario's code coverage to a file, and a manifest of the scenarios that ran, for
/// ``Cucumber/coverage``.
///
/// A run writes everything to a folder of its own, `run-<id>`, inside the coverage folder, so that the
/// folders of several runs, such as the shards of one suite, can be collected in one place and merged.
final class CoverageRecorder {
    /// The manifest's contents.
    struct Manifest: Codable, Equatable {
        /// Changes when the manifest's form changes, so that a reader can refuse one it doesn't know.
        static let currentVersion = 1

        var version = Manifest.currentVersion
        var run: String
        var startDate: Date
        var binaries: [Binary]
        var scenarios: [ScenarioRecord]
        /// Each feature's scores, in the order the features finished.
        var features = [FeatureRecord]()
        /// Why no profile was written, when the run couldn't write any.
        var problem: String?
        /// Why the run has no scores, when it has profiles but couldn't read a coverage map.
        var scoresProblem: String?
    }

    /// The scores of a feature that finished: of its scenarios that aren't in a Rule, or of one of its
    /// Rules, which has scores of its own.
    struct FeatureRecord: Codable, Equatable {
        var feature: String
        var featureName: String
        var line: Int
        /// The title of the Rule these scores are for, or `nil` for the feature's scenarios outside a Rule.
        var rule: String?
        /// The line of the Rule these scores are for.
        var ruleLine: Int?
        var scores: CoverageScores
    }

    /// The scores of one part of a feature: the scenarios in `rule`, or, when it is `nil`, the scenarios
    /// that aren't in a Rule.
    struct PartScores: Equatable {
        let rule: ScenarioRule?
        let scores: CoverageScores
    }

    /// A binary built with code coverage. A report needs it, with the profiles, to map the counters back to
    /// source lines, and its UUID identifies the build that ran.
    struct Binary: Codable, Equatable {
        var path: String
        var uuid: String?
    }

    /// A scenario that finished, as the runner describes it.
    struct FinishedScenario {
        /// The feature file's URI, as the JSON report gives it.
        var feature: String
        var featureName: String
        var line: Int
        var name: String
        var tags: [String]
        /// How long the scenario took, in seconds.
        var duration: TimeInterval?
        /// The scenario's ``CoverageScores/Scenario/group``.
        var group: String?
        /// The Rule the scenario is in, which is scored on its own.
        var rule: ScenarioRule?
    }

    /// A scenario that ran, and its profile files, one for each binary, in the run's folder.
    struct ScenarioRecord: Codable, Equatable {
        /// The feature file's URI, as the JSON report gives it.
        var feature: String
        var featureName: String
        var line: Int
        var name: String
        var tags: [String]
        var profiles: [String]
        /// How long the scenario took, in seconds.
        var duration: Double?
    }

    let folder: URL
    let runID: String
    private let startDate: Date
    private let counters: ProfileCounters
    private var snapshot: ProfileCounters.Snapshot?
    private var scenarios = [ScenarioRecord]()
    private var features = [FeatureRecord]()
    private var problem: String?
    private let settings: CoverageSettings
    /// The code the scores measure, and how to work out which of it a scenario ran. Nil when no binary
    /// has a coverage map, as ``scoresProblem`` says.
    private(set) var code: MeasuredCode?
    private var functions = [(binary: Int, function: CoverageMap.Function, firstRegion: Int)]()
    private(set) var scoresProblem: String?
    /// The scenarios of each feature that hasn't finished, by its URI, for its scores.
    private var featureScenarios = [String: [(rule: ScenarioRule?, scenario: CoverageScores.Scenario)]]()

    var manifest: Manifest {
        Manifest(
            run: runID,
            startDate: startDate,
            binaries: counters.binaries.map { Binary(path: $0.path, uuid: $0.uuid) },
            scenarios: scenarios,
            features: features,
            problem: problem,
            scoresProblem: problem == nil ? scoresProblem : nil
        )
    }

    /// The coverage folder: `path` when given, else `_cucumberCoverage` in the documents folder, which on
    /// a Simulator is inside the Simulator.
    static func coverageFolder(path: String?) -> URL? {
        if let path { return URL(fileURLWithPath: path, isDirectory: true) }
        return (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?
            .appendingPathComponent("_cucumberCoverage", isDirectory: true)
    }

    /// The run's folder, `run-<id>` inside `coverageFolder`, which this creates.
    init(coverageFolder: URL,
         counters: ProfileCounters = .loaded(),
         settings: CoverageSettings = CoverageSettings(),
         runID: String = UUID().uuidString,
         startDate: Date = Date()) {
        self.folder = coverageFolder.appendingPathComponent("run-\(runID)")
        self.runID = runID
        self.startDate = startDate
        self.counters = counters
        self.settings = settings
        measureCode()
        if let version = counters.unsupportedVersions.first, counters.binaries.isEmpty {
            problem = "The profile format of this test process is version \(version), and CucumberSwift writes version \(ProfileCounters.supportedVersion), the one of Xcode 26."
        } else if counters.binaries.isEmpty {
            problem = "No binary in the test process was built with code coverage. Turn on code coverage for the test target."
        }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            problem = "Couldn't create \(folder.path): \(error.localizedDescription)"
        }
    }

    /// Numbers the regions of the functions the scores measure, from every binary with a coverage map.
    private func measureCode() {
        if let reason = settings.scoresOffReason {
            scoresProblem = reason
            return
        }
        #if canImport(Compression)
        let mapped = counters.binaries.enumerated().filter { $0.element.map != nil }
        guard !mapped.isEmpty else {
            scoresProblem = counters.binaries.compactMap(\.mapProblem).first
            return
        }
        // When the test bundle is the only binary, it holds the code under test too, as `swift test`
        // builds it.
        let testBundleHoldsAllCode = mapped.allSatisfy { $0.element.path.contains(".xctest/") }
        var measured = [MeasuredCode.Function]()
        for (index, binary) in mapped {
            for function in binary.map?.functions ?? [] where !function.regions.isEmpty {
                guard MeasuredCode.isMeasured(file: function.file,
                                              binary: binary.path,
                                              sources: settings.sources,
                                              testBundleHoldsAllCode: testBundleHoldsAllCode) else { continue }
                let first = measured.last?.regions.upperBound ?? 0
                measured.append(MeasuredCode.Function(name: ReadableName.of(function.name),
                                                      file: function.file,
                                                      line: function.line,
                                                      regions: first..<first + function.regions.count))
                functions.append((index, function, first))
            }
        }
        code = MeasuredCode(functions: measured)
        #else
        scoresProblem = "this platform can't read coverage maps"
        #endif
    }

    /// The regions that `counts`, from ``ProfileCounters/differences(since:)``, ran.
    func regions(ran counts: [[UInt8]]) -> Set<Int> {
        var ran = Set<Int>()
        #if canImport(Compression)
        for (binary, function, firstRegion) in functions where binary < counts.count {
            counts[binary].withUnsafeBytes { counts in
                // A function that didn't run has no region that ran.
                guard let entry = function.regions.first, function.value(entry.counter, counts: counts) > 0 else { return }
                for (index, region) in function.regions.enumerated() where function.value(region.counter, counts: counts) > 0 {
                    ran.insert(firstRegion + index)
                }
            }
        }
        #endif
        return ran
    }

    func scenarioStarted() {
        snapshot = problem == nil ? counters.snapshot() : nil
    }

    /// Writes what the scenario covered, and keeps it for its feature's scores. A scenario is named after
    /// its position in the run and its line, such as `S0003-L12`, so that its files sort in the order the
    /// scenarios ran.
    func scenarioFinished(_ finished: FinishedScenario) {
        guard let snapshot, problem == nil else { return }
        self.snapshot = nil
        let fileName = String(format: "S%04d-L%d", scenarios.count + 1, finished.line)
        let counts = counters.differences(since: snapshot)
        do {
            let profiles = try counters.writeProfiles(named: fileName, in: folder, counts: counts)
            scenarios.append(ScenarioRecord(
                feature: finished.feature,
                featureName: finished.featureName,
                line: finished.line,
                name: finished.name,
                tags: finished.tags,
                profiles: profiles,
                duration: finished.duration
            ))
        } catch {
            problem = "Couldn't write the scenario's coverage: \(error)"
            return
        }
        if code != nil {
            let scenario = CoverageScores.Scenario(name: finished.name,
                                                   line: finished.line,
                                                   tags: finished.tags,
                                                   duration: finished.duration ?? 0,
                                                   regions: regions(ran: counts),
                                                   group: finished.group)
            featureScenarios[finished.feature, default: []].append((finished.rule, scenario))
        }
    }

    /// The scores of the feature at `feature`, its URI, from the scenarios of it that ran: one for its
    /// scenarios outside a Rule, first, then one for each Rule, in the order of their lines. Empty when the
    /// run has no scores, or none of the feature's scenarios ran.
    func featureFinished(feature: String, featureName: String, line: Int) -> [PartScores] {
        guard problem == nil, let code, let ran = featureScenarios.removeValue(forKey: feature) else { return [] }
        let rules = Set(ran.compactMap(\.rule)).sorted { $0.line < $1.line }
        let parts: [ScenarioRule?] = (ran.contains { $0.rule == nil } ? [nil] : []) + rules
        return parts.map { rule in
            let scores = CoverageScores(scenarios: ran.filter { $0.rule == rule }.map(\.scenario), code: code, isRedundancy: settings.isRedundancy)
            features.append(FeatureRecord(feature: feature, featureName: featureName, line: line, rule: rule?.title, ruleLine: rule?.line, scores: scores))
            return PartScores(rule: rule, scores: scores)
        }
    }

    /// Writes `manifest.json` in the run's folder. Returns its URL, or nil if it couldn't be written.
    @discardableResult
    func writeManifest() -> URL? {
        let url = folder.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(manifest), (try? data.write(to: url)) != nil else { return nil }
        return url
    }
}
