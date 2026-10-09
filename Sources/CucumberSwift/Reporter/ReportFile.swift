//
//  ReportFile.swift
//  CucumberSwift
//
//  The Cucumber JSON report on disk, which every worker of a parallel run writes to. Each worker keeps its
//  own features in memory and merges them into the file under an exclusive lock, so that the file holds
//  every worker's results. Simulator workers are processes on the same Mac, so the lock works across them
//  when the report is on the Mac.
//

import Foundation

final class ReportFile: @unchecked Sendable {
    private static let filesLock = NSLock()
    private static var files = [String: ReportFile]()

    let url: URL
    /// Taken exclusively for each read, merge and write of the report.
    private var writeLockPath: String { url.path + ".lock" }
    /// Held shared by every worker that writes the report, for as long as the worker runs.
    private var runLockPath: String { url.path + ".run" }
    private var runDescriptor: Int32 = -1
    private let joinLock = NSLock()
    private let writeLock = NSLock()

    /// The report at `url` for this process, which joins the report's run once.
    static func at(_ url: URL) -> ReportFile {
        filesLock.lock()
        defer { filesLock.unlock() }
        if let file = files[url.path] { return file }
        let file = ReportFile(url: url)
        files[url.path] = file
        return file
    }

    /// Adds a worker's features to the report's. A feature already in the report, by its URI, line and
    /// name, takes the worker's version of each of its scenarios, by line and name, and keeps the others'
    /// scenarios, in feature-file order. A worker writes its features again as it runs, so each write
    /// replaces what the worker wrote before.
    static func merge(_ ours: [[String: Any]], into report: [[String: Any]]) -> [[String: Any]] {
        var merged = report
        for feature in ours {
            let scenarios = feature["elements"] as? [[String: Any]] ?? []
            var updated = feature
            if let index = merged.firstIndex(where: { isSame(feature: $0, as: feature) }) {
                var elements = merged[index]["elements"] as? [[String: Any]] ?? []
                for scenario in scenarios {
                    if let existing = elements.firstIndex(where: { isSame(scenario: $0, as: scenario) }) {
                        elements[existing] = scenario
                    } else {
                        elements.append(scenario)
                    }
                }
                updated["elements"] = inFileOrder(elements)
                merged[index] = updated
            } else {
                updated["elements"] = inFileOrder(scenarios)
                merged.append(updated)
            }
        }
        return merged
    }

    private static func isSame(feature: [String: Any], as other: [String: Any]) -> Bool {
        feature["uri"] as? String == other["uri"] as? String
            && feature["line"] as? Int == other["line"] as? Int
            && feature["name"] as? String == other["name"] as? String
    }

    private static func isSame(scenario: [String: Any], as other: [String: Any]) -> Bool {
        scenario["line"] as? Int == other["line"] as? Int && scenario["name"] as? String == other["name"] as? String
    }

    private static func inFileOrder(_ scenarios: [[String: Any]]) -> [[String: Any]] {
        scenarios.enumerated()
            .sorted { ($0.element["line"] as? Int ?? 0, $0.offset) < ($1.element["line"] as? Int ?? 0, $1.offset) }
            .map(\.element)
    }

    init(url: URL) {
        self.url = url
    }

    deinit {
        if runDescriptor >= 0 { close(runDescriptor) }
    }

    /// Joins the run that writes the report, once. The first worker of a new run empties the report an
    /// earlier run left; every other worker of the run leaves it alone. A worker is the first when no other
    /// worker holds the run lock and the report hasn't been written for `staleAfter` seconds: Xcode can
    /// start a worker after another has finished, and it mustn't empty what that one wrote.
    func joinRun(staleAfter: TimeInterval = 60) {
        joinLock.lock()
        defer { joinLock.unlock() }
        guard runDescriptor < 0 else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let descriptor = open(runLockPath, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else { return }
        runDescriptor = descriptor
        // Holding the lock exclusively means no other worker is running; waiting for it while another
        // worker joins is what keeps two first workers from both emptying the report.
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0 {
            if isStale(after: staleAfter) { withWriteLock { write([]) } }
            flock(descriptor, LOCK_SH)
        } else {
            flock(descriptor, LOCK_SH)
        }
    }

    private func isStale(after seconds: TimeInterval) -> Bool {
        guard let modified = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else {
            return true
        }
        return Date().timeIntervalSince(modified) > seconds
    }

    /// Merges a worker's features, as the reporter encodes them, into the report.
    func merge(_ features: [[String: Any]]) {
        withWriteLock {
            write(Self.merge(features, into: read()))
        }
    }

    /// The features in the report: none when it is missing, empty or not a report.
    func read() -> [[String: Any]] {
        guard let data = try? Data(contentsOf: url),
              let features = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return features
    }

    private func withWriteLock(_ body: () -> Void) {
        writeLock.lock()
        defer { writeLock.unlock() }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let descriptor = open(writeLockPath, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else { return }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { return }
        defer { flock(descriptor, LOCK_UN) }
        body()
    }

    /// Writes to a temporary file in the report's folder and moves it into place, so that nothing reads
    /// half a report.
    private func write(_ features: [[String: Any]]) {
        guard let data = try? JSONSerialization.data(withJSONObject: features, options: [.prettyPrinted, .sortedKeys]) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
