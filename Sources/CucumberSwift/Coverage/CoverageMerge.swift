//
//  CoverageMerge.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, and with
//  cucumberswift-coverage-merge through a symlink of this file, so it uses neither runner's types.
//

import Foundation

/// The scores of the scenarios of several runs, scored as one run: the workers of a parallel run, or the
/// shards of a suite that ran on several machines. Each feature and each Rule gets the scores, the summary and
/// the issues that a run of all their scenarios, one at a time, gives them.
struct CoverageMerge {
    enum MergeError: Error, Equatable, CustomStringConvertible {
        case noRuns([String])
        case unreadable(String, String)
        case notMeasured(String, String)
        case differentBuilds(String)
        case differentSettings(String, String)

        var description: String {
            switch self {
                case .noRuns(let folders):
                    "no run folder, run-<id> with a manifest.json, in \(folders.joined(separator: ", "))"
                case .unreadable(let folder, let reason):
                    "can't read the manifest of \(folder): \(reason)"
                case .notMeasured(let folder, let reason):
                    "\(folder) has no code coverage to score: \(reason)"
                case .differentBuilds(let function):
                    "the runs measured different builds: \(function) has a different number of regions in each. Merge only the runs of one build."
                case .differentSettings(let first, let other):
                    "\(other) checks the scores against other levels than \(first). Set the same levels for every run."
            }
        }
    }

    /// A run's folder and its manifest.
    struct Run {
        let folder: URL
        let manifest: CoverageManifest
    }

    /// A feature, or one of its Rules, and its scores.
    struct FeatureScores {
        let featureName: String
        let featureLine: Int
        /// The feature file that the runners report the feature's issues on.
        let file: URL?
        let part: CoverageScores.Part
    }

    let runs: [Run]
    let settings: CoverageSettings
    /// Each feature's parts, features in the order of their files' paths.
    let features: [FeatureScores]
    /// How many scenarios were scored.
    let scenarioCount: Int
    /// How many scenarios ran in more than one run, and were scored once.
    let repeatedCount: Int
    /// The measured code of every run, numbered again as one build.
    let code: MeasuredCode
    /// Every scenario that was scored, once, with the regions it ran numbered as ``code`` numbers them.
    let scenarios: [MergedScenario]

    /// The folders of the runs in `folders`: each folder that has a `manifest.json`, and each `run-<id>`
    /// folder with one directly inside the others.
    static func runFolders(in folders: [URL]) -> [URL] {
        let fileManager = FileManager.default
        func isRun(_ folder: URL) -> Bool {
            fileManager.fileExists(atPath: folder.appendingPathComponent("manifest.json").path)
        }
        return folders.flatMap { folder -> [URL] in
            if isRun(folder) { return [folder] }
            let contents = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            return contents.filter { $0.lastPathComponent.hasPrefix("run-") && isRun($0) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    /// The runs in `folders`, as ``runFolders(in:)`` finds them.
    static func read(_ folders: [URL]) throws -> [Run] {
        let runFolders = runFolders(in: folders)
        guard !runFolders.isEmpty else { throw MergeError.noRuns(folders.map(\.path)) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try runFolders.map { folder in
            do {
                let manifest = try decoder.decode(CoverageManifest.self, from: Data(contentsOf: folder.appendingPathComponent("manifest.json")))
                guard manifest.version == CoverageManifest.currentVersion else {
                    throw MergeError.unreadable(folder.path, "its version is \(manifest.version), and this reads version \(CoverageManifest.currentVersion)")
                }
                return Run(folder: folder, manifest: manifest)
            } catch let error as MergeError {
                throw error
            } catch {
                throw MergeError.unreadable(folder.path, "\(error)")
            }
        }
    }

    /// The part of a feature file's URI that names the same file in every run: its path inside the test
    /// bundle, when it is in one, which is somewhere else in each Simulator. Otherwise the whole URI.
    static func featureKey(_ uri: String) -> String {
        guard let range = uri.range(of: ".xctest/", options: .backwards) else { return uri }
        return String(uri[range.upperBound...])
    }

    /// A function the runs measure, the same in every run of one build.
    private struct FunctionKey: Hashable {
        let binary: String
        let name: String
        let file: String
        /// Which of the functions with this binary, name and file it is, in the run's order.
        let occurrence: Int
    }

    /// A scenario as the merge scores it.
    struct MergedScenario {
        let feature: String
        let featureName: String
        let featureLine: Int
        let file: URL?
        let rule: ScenarioRule?
        let scenario: CoverageScores.Scenario
    }

    /// The functions of several runs of one build, and how each run's region numbers become the merged ones.
    struct Renumbering: Equatable {
        /// The measured functions of all the runs, each once, in the order the runs list them, with their regions
        /// numbered one after the other.
        let functions: [MeasuredCode.Function]
        /// Where each function's regions are placed, `spans` of the manifest's function: the first run's.
        let spans: [[[Int]]?]
        /// For each run, the merged number of each of its regions, by the region's number in the run.
        let maps: [[Int]]
    }

    /// Numbers the regions of the functions that `runs` measured again, as one build. Every run numbers its own
    /// regions, so a function is the same one in two runs when its binary, name, file and place among the
    /// functions with those three are. Throws ``MergeError/differentBuilds(_:)`` when the same function has a
    /// different number of regions in two runs.
    static func renumber(_ runs: [[CoverageManifest.MeasuredFunction]]) throws -> Renumbering {
        var functions = [MeasuredCode.Function]()
        var spans = [[[Int]]?]()
        var numbers = [FunctionKey: Range<Int>]()
        var maps = [[Int]]()
        for run in runs {
            var occurrences = [String: Int]()
            var map = [Int]()
            for function in run {
                let id = "\(function.binary)\u{0}\(function.name)\u{0}\(function.file)"
                let key = FunctionKey(binary: function.binary, name: function.name, file: function.file, occurrence: occurrences[id, default: 0])
                occurrences[id, default: 0] += 1
                let regions: Range<Int>
                if let known = numbers[key] {
                    guard known.count == function.regions else { throw MergeError.differentBuilds(function.readableName) }
                    regions = known
                } else {
                    let start = functions.last?.regions.upperBound ?? 0
                    regions = start..<start + function.regions
                    numbers[key] = regions
                    functions.append(MeasuredCode.Function(name: function.readableName, file: function.file, line: function.line, regions: regions))
                    spans.append(function.spans)
                }
                map += Array(regions)
            }
            maps.append(map)
        }
        return Renumbering(functions: functions, spans: spans, maps: maps)
    }

    init(runs: [Run]) throws {
        self.runs = runs
        guard let first = runs.first else { throw MergeError.noRuns([]) }
        for run in runs {
            guard run.manifest.problem == nil, run.manifest.measured != nil, run.manifest.settings != nil else {
                let reason = run.manifest.problem ?? run.manifest.scoresProblem
                    ?? "its manifest is from a version of CucumberSwift that doesn't record what the scores need"
                throw MergeError.notMeasured(run.folder.path, reason)
            }
            guard run.manifest.settings == first.manifest.settings else {
                throw MergeError.differentSettings(first.folder.path, run.folder.path)
            }
        }
        let settings = first.manifest.settings?.coverageSettings ?? CoverageSettings()
        self.settings = settings

        let renumbering = try Self.renumber(runs.map { $0.manifest.measured ?? [] })
        let renumbered = renumbering.maps
        let functions = renumbering.functions
        let code = MeasuredCode(functions: functions)
        self.code = code

        var seen = Set<[String]>()
        var scenarios = [MergedScenario]()
        var repeated = 0
        for (run, map) in zip(runs, renumbered) {
            func number(_ regions: [Int]) -> Set<Int> {
                Set(regions.compactMap { map.indices.contains($0) ? map[$0] : nil })
            }
            for record in run.manifest.scenarios {
                guard let coverage = record.coverage else { continue }
                let key = Self.featureKey(record.feature)
                guard seen.insert([key, "\(record.line)", record.name]).inserted else {
                    repeated += 1
                    continue
                }
                let scenario = CoverageScores.Scenario(name: record.name,
                                                       line: record.line,
                                                       tags: record.tags,
                                                       duration: record.duration ?? 0,
                                                       regions: number(coverage.regions),
                                                       group: coverage.group)
                    .with(backgroundRegions: number(coverage.backgroundRegions))
                    .with(steps: coverage.steps.map { CoverageScores.StepRun(line: $0.line, regions: number($0.regions)) })
                scenarios.append(MergedScenario(feature: key,
                                                featureName: record.featureName,
                                                featureLine: record.featureLine ?? 1,
                                                file: record.issueFile.flatMap(URL.init(string:)),
                                                rule: coverage.rule.map { ScenarioRule(title: $0, line: coverage.ruleLine ?? 0) },
                                                scenario: scenario))
            }
        }
        scenarioCount = scenarios.count
        repeatedCount = repeated
        self.scenarios = scenarios

        let byFeature = Dictionary(grouping: scenarios, by: \.feature)
        features = byFeature.keys.sorted().flatMap { key -> [FeatureScores] in
            let scenarios = byFeature[key] ?? []
            guard let first = scenarios.first else { return [] }
            let parts = CoverageScores.parts(of: scenarios.map { ($0.rule, $0.scenario) }, code: code, isRedundancy: settings.isRedundancy)
            return parts.map { FeatureScores(featureName: first.featureName, featureLine: first.featureLine, file: first.file, part: $0) }
        }
    }

    /// Prints each feature's and each Rule's summary, and its issues, as a compiler prints a warning or an
    /// error, with the feature file and line. Returns whether an issue is an error.
    func report(output: (String) -> Void) -> Bool {
        let repeated = repeatedCount == 0 ? "" : ", \(CoverageReport.count(repeatedCount, "scenario")) that ran again scored once"
        output("CucumberSwift coverage: \(CoverageReport.count(scenarioCount, "scenario")) from \(CoverageReport.count(runs.count, "run")) scored as one run\(repeated)")
        var hasError = false
        for feature in features {
            let report = CoverageReport.report(feature.part,
                                               featureName: feature.featureName,
                                               featureLine: feature.featureLine,
                                               file: feature.file,
                                               settings: settings)
            output(report.summary)
            for issue in report.issues {
                hasError = hasError || issue.severity == .error
                output("\(issue.file?.path ?? ""):\(max(issue.line, 1)): \(issue.severity == .warning ? "warning" : "error"): \(issue.message)")
            }
        }
        return hasError
    }
}
