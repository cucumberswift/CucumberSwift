//
//  ReportFile.swift
//  CucumberSwift
//
//  The Cucumber JSON report on disk, which every process of a test run writes to: each worker of a parallel
//  run, and each test target's process, whichever runner it uses. Each process keeps its own features in
//  memory and merges them into the file under an exclusive lock, so that the file holds every process's
//  results. Simulator processes run on the same Mac, so the lock works across them when the report is on
//  the Mac.
//

import Foundation

/// The command that started a test process, which tells one run's workers from the next run's. `swift test`
/// starts the XCTest process and then the Swift Testing process, and `xcodebuild` starts each test bundle and
/// each parallel worker on the Mac, so the workers of one run have the same starter, and the next run has a
/// new one. Known by its process ID and the time it started, because the system reuses process IDs.
struct RunStarter: Equatable {
    /// The commands that start every test process of a run, and only that run's, by the name the system
    /// gives the process. `swift-test` is a link to `swift-package`, whose name its process takes.
    static let commands: Set<String> = ["swift-package", "swift-test", "xcodebuild"]

    /// The starter of this process: its parent, when the parent is one of the `commands`. Otherwise `nil`,
    /// and only the report's age tells runs apart. Xcode starts each test process under a `debugserver` of
    /// its own, and on a Simulator `launchd` starts the test processes of every run.
    static let current = command(getppid())

    let pid: Int32
    let started: Int64

    var recorded: String { "\(pid) \(started)" }

    /// Whether the starter has exited, so its run is over: no process has its ID, or the process that has it
    /// started at another time. A starter whose state can't be read is taken to be running.
    var hasExited: Bool {
        Self.process(pid).map { $0.map { $0.started != started } ?? true } ?? false
    }

    /// The process with the ID when its name is one of `commands`.
    static func command(_ pid: Int32, in commands: Set<String> = RunStarter.commands) -> RunStarter? {
        guard case let .some(.some(process)) = process(pid), commands.contains(process.name) else { return nil }
        return RunStarter(pid: pid, started: process.started)
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
        let name = withUnsafeBytes(of: &info.kp_proc.p_comm) { String(bytes: $0.prefix { $0 != 0 }, encoding: .utf8) }
        return (Int64(start.tv_sec) * 1_000_000 + Int64(start.tv_usec), name ?? "")
        #else
        return nil
        #endif
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
}

/// What the run lock file records about the run that writes a report: the command that started it, and the
/// test bundles that have joined it, each with its runner. A bundle runs once in a run, with each runner, so a
/// bundle that joins again starts a new run. That is how a rerun in Xcode, or on a Simulator, is told from
/// the run before it: neither has a command that starts every process of a run.
struct RunRecord: Equatable {
    /// The name of the test bundle this process runs, from the `XCTestBundlePath` that Xcode, `xcodebuild`
    /// and a Simulator set, without its folders, which change with each install. `nil` for `swift test`, whose
    /// one bundle runs once with each runner.
    static var currentBundle: String? {
        ProcessInfo.processInfo.environment["XCTestBundlePath"].map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    var starter: RunStarter?
    var keys = Set<String>()

    var recorded: String {
        ([starter?.recorded ?? ""] + keys.sorted()).joined(separator: "\n")
    }

    static func key(runner: String, bundle: String?) -> String {
        "\(runner) \(bundle ?? "")"
    }

    init(starter: RunStarter? = nil) {
        self.starter = starter
    }

    /// The record from the run lock file's text: the starter on the first line, a bundle's key on each line
    /// after it. Anything that can't be read is no record.
    init(recorded: String) {
        let lines = recorded.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        starter = lines.first.flatMap { RunStarter(recorded: $0) }
        keys = Set(lines.dropFirst().filter { !$0.isEmpty })
    }

    /// Whether a worker that no other worker is running beside starts a new run.
    ///
    /// - The recorded command has exited: the run it started is over.
    /// - The recorded command is `current`, which is still running: this is the same run, whatever the
    ///   report's age, as `swift test` starts the Swift Testing process after the XCTest process has finished.
    /// - Nothing was recorded, and this process has a command: no run of that command has written the report.
    /// - A bundle that is not one of several parallel workers joins with the same runner again.
    /// - Otherwise, when the report is stale.
    func isNewRun(by current: RunStarter?, key: String, isParallel: Bool, isStale: () -> Bool) -> Bool {
        if let starter {
            if starter.hasExited { return true }
            if starter == current { return false }
        } else if current != nil {
            return true
        }
        if !isParallel, keys.contains(key) { return true }
        return isStale()
    }
}

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
    /// How long a report can go unwritten before a worker takes it for an earlier run's: 10 minutes, so that
    /// a slow test target of the same run, such as a UI target that waits for a Simulator to boot, never
    /// empties what the targets before it wrote.
    static let staleAfter: TimeInterval = 600

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

    /// Joins the run that writes the report, once. The first process of a new run empties the report an
    /// earlier run left; every other process of the run leaves it alone. Every process that writes the report
    /// is a worker: each parallel worker, and each test target's process, whichever runner it uses.
    ///
    /// The first worker of a run records, in the run lock file, the command that started it and the test
    /// bundles that have joined it. A worker starts a new run when no other worker holds the run lock and
    /// ``RunRecord/isNewRun(by:key:isParallel:isStale:)`` says so.
    /// - Parameters:
    ///   - runner: The runner that writes: `XCTest` or `Swift Testing`.
    ///   - bundle: The name of the test bundle that the process runs, `nil` where it can't be known.
    ///   - isParallel: Whether the process is one of several workers that run one test bundle.
    ///   - run: The command that started this process, `swift test` or `xcodebuild`. `nil` when the process
    ///     doesn't tell runs apart.
    func joinRun(runner: String,
                 bundle: String? = RunRecord.currentBundle,
                 isParallel: Bool = false,
                 run: RunStarter? = .current,
                 staleAfter: TimeInterval = ReportFile.staleAfter) {
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
        // first one has just written, which isn't stale, and the run this worker recorded, so it leaves
        // it alone: two first workers never both empty it.
        let key = RunRecord.key(runner: runner, bundle: bundle)
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0 {
            // The decision, the report's reset and the record are one step under the write lock, so no
            // worker updates the record while this one reads it.
            withWriteLock {
                var record = RunRecord(recorded: recordedRun())
                if record.isNewRun(by: run, key: key, isParallel: isParallel, isStale: { isStale(after: staleAfter) }) {
                    write([])
                    record = RunRecord(starter: run)
                }
                record.keys.insert(key)
                store(record)
            }
            flock(descriptor, LOCK_SH)
        } else {
            // Another worker holds the run. Waiting for the shared lock lets a first worker that is still
            // deciding finish, so that it doesn't discard this worker's key. The bundle is recorded, or
            // running it again alone wouldn't be known as a new run.
            flock(descriptor, LOCK_SH)
            withWriteLock {
                var record = RunRecord(recorded: recordedRun())
                record.keys.insert(key)
                store(record)
            }
        }
    }

    /// The run recorded in the run lock file.
    private func recordedRun() -> String {
        var bytes = [UInt8](repeating: 0, count: 4_096)
        let count = pread(runDescriptor, &bytes, bytes.count, 0)
        return count > 0 ? String(bytes: bytes[..<count], encoding: .utf8) ?? "" : ""
    }

    private func store(_ record: RunRecord) {
        let bytes = Array(record.recorded.utf8)
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
