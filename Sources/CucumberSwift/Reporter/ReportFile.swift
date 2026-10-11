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
    private static var warned = Set<String>()
    /// Where a warning goes: stderr, unless a test says otherwise.
    static var warningSink: (String) -> Void = { FileHandle.standardError.write(Data(($0 + "\n").utf8)) }

    let url: URL
    /// Taken exclusively for each read, merge and write of the report.
    private var writeLockPath: String { url.path + ".lock" }
    /// Held shared by every worker that writes the report, for as long as the worker runs.
    private var runLockPath: String { url.path + ".run" }
    private var runDescriptor: Int32 = -1
    private let joinLock = NSLock()
    private let writeLock = NSLock()
    /// How many times this process merged into the report, for the reporter's tests.
    private(set) var merges = 0

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
    /// replaces what the worker wrote before. The features are in the order of their files, which is the
    /// order a serial run lists them in, whichever worker wrote first.
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
        return inFileOrder(features: merged)
    }

    /// The report's bytes: the features, as the reporter encodes them, with their keys sorted, so that the
    /// report of a serial run and of a parallel run are written the same way, and one run's report is the
    /// same bytes each time it is written.
    static func serialize(_ features: [[String: Any]]) -> Data? {
        try? JSONSerialization.data(withJSONObject: features, options: [.prettyPrinted, .sortedKeys])
    }

    /// Two workers read one feature file from different places when each runs from a copy of the test
    /// bundle, as the UI test runner does on each Simulator clone, so the features are matched by their
    /// path inside the `.xctest` bundle when they have one.
    private static func identity(ofURI uri: String?) -> String? {
        guard let uri else { return nil }
        guard let bundle = uri.range(of: ".xctest/", options: .backwards) else { return uri }
        return String(uri[bundle.upperBound...])
    }

    private static func isSame(feature: [String: Any], as other: [String: Any]) -> Bool {
        identity(ofURI: feature["uri"] as? String) == identity(ofURI: other["uri"] as? String)
            && feature["line"] as? Int == other["line"] as? Int
            && feature["name"] as? String == other["name"] as? String
    }

    private static func isSame(scenario: [String: Any], as other: [String: Any]) -> Bool {
        scenario["line"] as? Int == other["line"] as? Int && scenario["name"] as? String == other["name"] as? String
    }

    /// Features in the order of their files, the order a serial run reads them in (sorted by URI), and
    /// features of one file in the order they are declared. The sort is stable.
    private static func inFileOrder(features: [[String: Any]]) -> [[String: Any]] {
        features.enumerated()
            .sorted {
                let (left, right) = (identity(ofURI: $0.element["uri"] as? String) ?? "", identity(ofURI: $1.element["uri"] as? String) ?? "")
                if left != right { return left < right }
                let (leftLine, rightLine) = ($0.element["line"] as? Int ?? 0, $1.element["line"] as? Int ?? 0)
                return (leftLine, $0.offset) < (rightLine, $1.offset)
            }
            .map(\.element)
    }

    private static func inFileOrder(_ scenarios: [[String: Any]]) -> [[String: Any]] {
        scenarios.enumerated()
            .sorted { ($0.element["line"] as? Int ?? 0, $0.offset) < ($1.element["line"] as? Int ?? 0, $1.offset) }
            .map(\.element)
    }

    /// Says on stderr that the report couldn't be written, once for each report: a missing report is
    /// otherwise silent, and every write after the first fails the same way.
    static func warn(_ url: URL, _ reason: String) {
        filesLock.lock()
        defer { filesLock.unlock() }
        guard warned.insert(url.path).inserted else { return }
        warningSink("CucumberSwift: couldn't write the Cucumber JSON report at \(url.path): \(reason)")
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
        // Getting the lock exclusively means no other worker holds the run, so this may be a new run's
        // first worker. Then `flock` below turns it into a shared lock, which on some systems drops the
        // lock for a moment, and another worker can take it exclusively. That worker finds a report the
        // first one has just written, which isn't stale, so it leaves it alone: two first workers never
        // both empty it, but only because of the age check.
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0, isStale(after: staleAfter) {
            withWriteLock { write([]) }
        }
        flock(descriptor, LOCK_SH)
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
            merges += 1
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
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            Self.warn(url, "the folder can't be created (\(error.localizedDescription))")
            return
        }
        let descriptor = open(writeLockPath, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else {
            Self.warn(url, "the lock file \(writeLockPath) can't be created (\(String(cString: strerror(errno))))")
            return
        }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else {
            Self.warn(url, "the lock file can't be locked (\(String(cString: strerror(errno))))")
            return
        }
        defer { flock(descriptor, LOCK_UN) }
        body()
    }

    /// Writes to a temporary file in the report's folder and moves it into place, so that nothing reads
    /// half a report.
    private func write(_ features: [[String: Any]]) {
        guard let data = Self.serialize(features) else {
            Self.warn(url, "the results can't be encoded as JSON")
            return
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            Self.warn(url, error.localizedDescription)
        }
    }
}
