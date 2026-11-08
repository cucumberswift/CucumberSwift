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
        guard JSONSerialization.isValidJSONObject(features) else { return nil }
        return try? JSONSerialization.data(withJSONObject: features, options: [.prettyPrinted, .sortedKeys])
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
    /// earlier run left; every other worker of the run leaves it alone. Every process that writes the report
    /// is a worker: each parallel worker, and each test target's process, whichever runner it uses.
    ///
    /// A worker is the first of a new run when no other worker holds the run lock, and either the report
    /// hasn't been written for `staleAfter` seconds or the process that started the last run's workers has
    /// exited. Xcode can start a worker after another has finished, and `swift test` starts the Swift Testing
    /// process after the XCTest process has finished, and neither may empty what the earlier one wrote.
    /// - Parameter run: The process that started this worker, which `swift test` and `xcodebuild` start once
    ///   for each run. `nil` when that process doesn't tell runs apart.
    func joinRun(run: RunStarter? = .current, staleAfter: TimeInterval = 60) {
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
        // first one has just written, which isn't stale, and the run this worker recorded, whose starter is
        // running, so it leaves it alone: two first workers never both empty it.
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0 {
            if isStale(after: staleAfter) || RunStarter(recorded: recordedRun())?.hasExited == true {
                withWriteLock { write([]) }
            }
            record(run)
        }
        flock(descriptor, LOCK_SH)
    }

    /// The run the last first worker recorded in the run lock file.
    private func recordedRun() -> String {
        var bytes = [UInt8](repeating: 0, count: 128)
        let count = pread(runDescriptor, &bytes, bytes.count, 0)
        return count > 0 ? String(decoding: bytes[..<count], as: UTF8.self) : ""
    }

    private func record(_ run: RunStarter?) {
        let bytes = Array((run?.recorded ?? "").utf8)
        ftruncate(runDescriptor, 0)
        _ = pwrite(runDescriptor, bytes, bytes.count, 0)
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
        defer { if descriptor >= 0 { close(descriptor) } }
        guard descriptor >= 0, flock(descriptor, LOCK_EX) == 0 else {
            Self.warn(url, "the lock file \(writeLockPath) can't be created or locked (\(String(cString: strerror(errno))))")
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

/// The command that started a test process, which tells one run's workers from the next run's. `swift test`
/// starts the XCTest process and then the Swift Testing process, and `xcodebuild` starts each test bundle and
/// each parallel worker on the Mac, so the workers of one run have the same starter, and the next run has a
/// new one. Known by its process ID and the time it started, because the system reuses process IDs.
struct RunStarter: Equatable {
    /// The commands that start every test process of a run, and only that run's, by the name the system
    /// gives the process. `swift-test` is a link to `swift-package`, whose name the process takes.
    static let commands: Set<String> = ["swift-package", "swift-test", "xcodebuild"]

    let pid: Int32
    let started: Int64

    /// The starter of this process: its parent, when the parent is one of the `commands`. Otherwise `nil`,
    /// and only the report's age tells runs apart. Xcode starts each test process under a `debugserver` of
    /// its own, and on a Simulator `launchd` starts the test processes of every run.
    static let current = command(getppid())

    /// The process with the ID when it is one of the `commands`.
    static func command(_ pid: Int32) -> RunStarter? {
        guard case let .some(.some(process)) = process(pid), commands.contains(process.name) else { return nil }
        return RunStarter(pid: pid, started: process.started)
    }

    init(pid: Int32, started: Int64) {
        self.pid = pid
        self.started = started
    }

    /// The running process with the ID, whatever started it. `nil` when there is none, or it can't be read.
    init?(process pid: Int32) {
        guard case let .some(.some(process)) = Self.process(pid) else { return nil }
        self.init(pid: pid, started: process.started)
    }

    /// The starter recorded in the run lock file, `<process ID> <start time>`.
    init?(recorded: String) {
        let parts = recorded.split(separator: " ")
        guard parts.count == 2, let pid = Int32(parts[0]), let started = Int64(parts[1]) else { return nil }
        self.init(pid: pid, started: started)
    }

    var recorded: String { "\(pid) \(started)" }

    /// Whether the starter has exited, so its run is over: no process has its ID, or the process that has it
    /// started at another time. A starter whose state can't be read is taken to be running.
    var hasExited: Bool {
        switch Self.process(pid) {
        case .none: return false
        case .some(.none): return true
        case let .some(.some(process)): return process.started != started
        }
    }

    /// The process with the ID, as its start time in microseconds and its name: `nil` when it can't be read,
    /// and `.some(nil)` when there's no such process.
    private static func process(_ pid: Int32) -> (started: Int64, name: String)?? {
        #if canImport(Darwin)
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var query = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&query, UInt32(query.count), &info, &size, nil, 0) == 0 else { return nil }
        guard size > 0 else { return .some(nil) }
        let start = info.kp_proc.p_un.__p_starttime
        let name = withUnsafeBytes(of: &info.kp_proc.p_comm) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        return (Int64(start.tv_sec) * 1_000_000 + Int64(start.tv_usec), name)
        #else
        return nil
        #endif
    }
}
