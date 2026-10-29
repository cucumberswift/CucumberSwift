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
        /// Why no profile was written, when the run couldn't write any.
        var problem: String?
    }

    /// A binary built with code coverage. A report needs it, with the profiles, to map the counters back to
    /// source lines, and its UUID identifies the build that ran.
    struct Binary: Codable, Equatable {
        var path: String
        var uuid: String?
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
    }

    let folder: URL
    let runID: String
    private let startDate: Date
    private let counters: ProfileCounters
    private var snapshot: ProfileCounters.Snapshot?
    private var scenarios = [ScenarioRecord]()
    private var problem: String?

    /// The run's folder, `run-<id>` inside `coverageFolder`, which this creates.
    init(coverageFolder: URL, counters: ProfileCounters = .loaded(), runID: String = UUID().uuidString, startDate: Date = Date()) {
        self.folder = coverageFolder.appendingPathComponent("run-\(runID)")
        self.runID = runID
        self.startDate = startDate
        self.counters = counters
        if counters.binaries.isEmpty {
            problem = "No binary in the test process was built with code coverage. Turn on code coverage for the test target."
        }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            problem = "Couldn't create \(folder.path): \(error.localizedDescription)"
        }
    }

    func scenarioStarted() {
        snapshot = problem == nil ? counters.snapshot() : nil
    }

    /// Writes what the scenario covered. A scenario is named after its position in the run and its line,
    /// such as `S0003-L12`, so that its files sort in the order the scenarios ran.
    func scenarioFinished(feature: String, featureName: String, line: Int, name: String, tags: [String]) {
        guard let snapshot, problem == nil else { return }
        self.snapshot = nil
        let fileName = String(format: "S%04d-L%d", scenarios.count + 1, line)
        do {
            let profiles = try counters.writeProfiles(named: fileName, in: folder, since: snapshot)
            scenarios.append(ScenarioRecord(feature: feature, featureName: featureName, line: line, name: name,
                                            tags: tags, profiles: profiles))
        } catch ProfileCounters.WriteError.continuousMode {
            problem = "LLVM_PROFILE_FILE uses %c (continuous mode), which writes only to its own file. Remove %c to measure each scenario."
        } catch {
            problem = "Couldn't write the scenario's coverage: \(error)"
        }
    }

    var manifest: Manifest {
        Manifest(run: runID, startDate: startDate,
                 binaries: counters.binaries.map { Binary(path: $0.path, uuid: $0.uuid) },
                 scenarios: scenarios, problem: problem)
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

    /// The coverage folder: `path` when given, else `_cucumberCoverage` in the documents folder, which on
    /// a Simulator is inside the Simulator.
    static func coverageFolder(path: String?) -> URL? {
        if let path { return URL(fileURLWithPath: path, isDirectory: true) }
        return (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?
            .appendingPathComponent("_cucumberCoverage", isDirectory: true)
    }
}
