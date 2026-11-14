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
    typealias Manifest = CoverageManifest
    typealias FeatureRecord = CoverageManifest.FeatureRecord
    typealias Binary = CoverageManifest.Binary
    typealias ScenarioRecord = CoverageManifest.ScenarioRecord
    typealias PartScores = CoverageScores.Part

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
        /// The line of the feature's `Feature:`.
        var featureLine: Int?
        /// The feature file that the runner reports the feature's coverage issues on.
        var issueFile: URL?
    }

    /// How long before a run starts the runs it deletes with `removesEarlierRuns` started, at least. The
    /// workers of one parallel run start seconds apart, so none deletes another's folder.
    static let earlierRunAge: TimeInterval = 60 * 60

    let folder: URL
    let runID: String
    private let startDate: Date
    private let counters: ProfileCounters
    private var snapshot: ProfileCounters.Snapshot?
    /// What the counters gained during the running scenario's Background steps.
    private var backgroundCounts: [[UInt8]]?
    private var stepSnapshot: ProfileCounters.Snapshot?
    /// The regions each of the running scenario's steps after its Background ran.
    private var stepRuns = [CoverageScores.StepRun]()
    private var scenarios = [ScenarioRecord]()
    private var features = [FeatureRecord]()
    private var problem: String?
    private let settings: CoverageSettings
    /// The code the scores measure, and how to work out which of it a scenario ran. Nil when no binary
    /// has a coverage map, as ``scoresProblem`` says.
    private(set) var code: MeasuredCode?
    private var functions = [(binary: Int, function: CoverageMap.Function, firstRegion: Int)]()
    /// The functions the scores measure, as the manifest lists them for `cucumberswift coverage merge`.
    private var measured: [CoverageManifest.MeasuredFunction]?
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
            scoresProblem: problem == nil ? scoresProblem : nil,
            measured: problem == nil ? measured : nil,
            settings: CoverageManifest.Settings(settings)
        )
    }

    /// The coverage folder: `path` when given, else `_cucumberCoverage` in the documents folder, which on
    /// a Simulator is inside the Simulator.
    static func coverageFolder(path: String?) -> URL? {
        if let path { return URL(fileURLWithPath: path, isDirectory: true) }
        return (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?
            .appendingPathComponent("_cucumberCoverage", isDirectory: true)
    }

    /// Deletes the folders of the runs in `coverageFolder` that were created more than ``earlierRunAge``
    /// before `date`.
    static func removeRuns(in coverageFolder: URL, before date: Date) {
        let fileManager = FileManager.default
        let folders = (try? fileManager.contentsOfDirectory(at: coverageFolder, includingPropertiesForKeys: [.creationDateKey])) ?? []
        for folder in folders where folder.lastPathComponent.hasPrefix("run-") {
            guard let created = try? folder.resourceValues(forKeys: [.creationDateKey]).creationDate,
                  created < date.addingTimeInterval(-earlierRunAge) else { continue }
            try? fileManager.removeItem(at: folder)
        }
    }

    /// The run's folder, `run-<id>` inside `coverageFolder`, which this creates. With `removesEarlierRuns`,
    /// it first deletes the folders that earlier runs left there, as in the default coverage folder, which
    /// nothing else empties. A folder that you set may collect several runs to merge, and is left as it is.
    init(coverageFolder: URL,
         counters: ProfileCounters = .loaded(),
         settings: CoverageSettings = CoverageSettings(),
         runID: String = UUID().uuidString,
         startDate: Date = Date(),
         removesEarlierRuns: Bool = false) {
        if removesEarlierRuns {
            Self.removeRuns(in: coverageFolder, before: startDate)
        }
        self.folder = coverageFolder.appendingPathComponent("run-\(runID)")
        self.runID = runID
        self.startDate = startDate
        self.counters = counters
        self.settings = settings
        measureCode()
        if let version = counters.unsupportedVersions.first, counters.binaries.isEmpty {
            problem = "The profile format of this test process is version \(version), and CucumberSwift writes versions 8 and 10, the ones of Xcode 16 and Xcode 26."
        } else if counters.binaries.isEmpty {
            problem = "No binary in the test process was built with code coverage. Turn on code coverage for the test target."
        }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            problem = "Couldn't create \(folder.path): \(error.localizedDescription)"
        }
    }

    /// Numbers the regions of the functions the scores measure, from every binary with a coverage map. A run
    /// that doesn't score, as ``CoverageSettings/scoresOffReason`` says, still measures them, for
    /// `cucumberswift coverage merge`.
    private func measureCode() {
        scoresProblem = settings.scoresOffReason
        #if canImport(Compression)
        let mapped = counters.binaries.enumerated().filter { $0.element.map != nil }
        guard !mapped.isEmpty else {
            scoresProblem = counters.binaries.compactMap(\.mapProblem).first ?? scoresProblem
            return
        }
        // When the test bundle is the only binary, it holds the code under test too, as `swift test`
        // builds it.
        let testBundleHoldsAllCode = mapped.allSatisfy { $0.element.path.contains(".xctest/") }
        var measured = [MeasuredCode.Function]()
        var listed = [CoverageManifest.MeasuredFunction]()
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
                listed.append(CoverageManifest.MeasuredFunction(binary: URL(fileURLWithPath: binary.path).lastPathComponent,
                                                                name: function.name,
                                                                readableName: ReadableName.of(function.name),
                                                                file: function.file,
                                                                line: function.line,
                                                                regions: function.regions.count,
                                                                spans: function.regions.map { [$0.lineStart, $0.columnStart, $0.lineEnd, $0.columnEnd] }))
            }
        }
        code = MeasuredCode(functions: measured)
        self.measured = listed
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
        backgroundCounts = nil
        stepSnapshot = nil
        stepRuns = []
    }

    func stepStarted() {
        stepSnapshot = problem == nil && code != nil ? counters.snapshot() : nil
    }

    /// Notes the regions the step at `line` ran, unless it is one of the Background's.
    func stepFinished(line: Int, isBackground: Bool) {
        guard let snapshot = stepSnapshot else { return }
        stepSnapshot = nil
        guard !isBackground else { return }
        stepRuns.append(CoverageScores.StepRun(line: line, regions: regions(ran: counters.differences(since: snapshot))))
    }

    /// Notes the code the running scenario ran so far: its Background steps, which have just finished.
    /// The redundancy leaves that code out.
    func backgroundFinished() {
        guard let snapshot, code != nil else { return }
        backgroundCounts = counters.differences(since: snapshot)
    }

    /// Writes what the scenario covered, and keeps it for its feature's scores. A scenario is named after
    /// its position in the run and its line, such as `S0003-L12`, so that its files sort in the order the
    /// scenarios ran.
    func scenarioFinished(_ finished: FinishedScenario) {
        guard let snapshot, problem == nil else { return }
        self.snapshot = nil
        let fileName = String(format: "S%04d-L%d", scenarios.count + 1, finished.line)
        let counts = counters.differences(since: snapshot)
        let scenario = code.map { _ in
            CoverageScores.Scenario(name: finished.name,
                                    line: finished.line,
                                    tags: finished.tags,
                                    duration: finished.duration ?? 0,
                                    regions: regions(ran: counts),
                                    group: finished.group)
                .with(backgroundRegions: backgroundCounts.map(regions(ran:)) ?? [])
                .with(steps: stepRuns)
        }
        do {
            let profiles = try counters.writeProfiles(named: fileName, in: folder, counts: counts)
            scenarios.append(ScenarioRecord(
                feature: finished.feature,
                featureName: finished.featureName,
                line: finished.line,
                name: finished.name,
                tags: finished.tags,
                profiles: profiles,
                duration: finished.duration,
                featureLine: finished.featureLine,
                issueFile: finished.issueFile?.absoluteString,
                coverage: scenario.map { Self.coverage(of: $0, rule: finished.rule) }
            ))
        } catch {
            problem = "Couldn't write the scenario's coverage: \(error)"
            return
        }
        if let scenario {
            featureScenarios[finished.feature, default: []].append((finished.rule, scenario))
        }
    }

    /// The code `scenario`, in `rule`, ran, as the manifest records it.
    static func coverage(of scenario: CoverageScores.Scenario, rule: ScenarioRule?) -> CoverageManifest.ScenarioCoverage {
        CoverageManifest.ScenarioCoverage(regions: scenario.regions.sorted(),
                                          backgroundRegions: scenario.backgroundRegions.sorted(),
                                          steps: scenario.steps.map { .init(line: $0.line, regions: $0.regions.sorted()) },
                                          group: scenario.group,
                                          rule: rule?.title,
                                          ruleLine: rule?.line)
    }

    /// The scores of the feature at `feature`, its URI, from the scenarios of it that ran: one for its
    /// scenarios outside a Rule, first, then one for each Rule, in the order of their lines. Empty when the
    /// run has no scores, or none of the feature's scenarios ran.
    func featureFinished(feature: String, featureName: String, line: Int) -> [PartScores] {
        guard let ran = featureScenarios.removeValue(forKey: feature),
              problem == nil, settings.scoresOffReason == nil, let code else { return [] }
        let parts = CoverageScores.parts(of: ran, code: code, isRedundancy: settings.isRedundancy)
        for part in parts {
            features.append(FeatureRecord(feature: feature,
                                          featureName: featureName,
                                          line: line,
                                          rule: part.rule?.title,
                                          ruleLine: part.rule?.line,
                                          scores: part.scores))
        }
        return parts
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
