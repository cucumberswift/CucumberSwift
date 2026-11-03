//
//  MutationRun.swift
//  CucumberSwiftMutation
//

import Foundation

/// Finds the mutants in Swift files. The tool supplies it, because it needs swift-syntax.
public protocol MutantDiscovering {
    /// The mutants in `files`. Each `Mutant.file` is the file's path relative to `root`.
    func mutants(inFiles files: [URL], relativeTo root: URL) throws -> [Mutant]
}

/// One mutation testing run: copy the package, find the mutants, run the tests against each in the copy,
/// write the reports, delete the copy.
///
/// The user's files are never changed, so there is nothing to revert. The run compares the package before and
/// after, and fails if anything differs.
public final class MutationRun {
    /// The exit status of a run.
    public enum Status {
        public static let completed: Int32 = 0
        public static let failed: Int32 = 1
        public static let baselineFailed: Int32 = 3
        public static let projectChanged: Int32 = 4
        public static let cancelled: Int32 = 130
    }

    /// A mutant's run that proves nothing, so the whole run stops instead of counting it.
    enum RunError: Error, CustomStringConvertible {
        case noTestsRan(mutant: String, log: String)

        var description: String {
            switch self {
                case .noTestsRan(let mutant, let log):
                    return "the tests ran no test for \(mutant), although they did without the change. The output is in \(log)"
            }
        }
    }

    private let options: MutationOptions
    private let discoverer: MutantDiscovering
    private let runner: CommandRunning
    private let output: (String) -> Void
    private let lock = NSLock()
    private var workFolder: WorkFolder?
    private var before: ProjectFingerprint?
    private var cancelled = false

    private var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public init(
        options: MutationOptions,
        discoverer: MutantDiscovering,
        runner: CommandRunning = ProcessRunner(),
        log: @escaping (String) -> Void = { print($0) }
    ) {
        self.options = options
        self.discoverer = discoverer
        self.runner = runner
        output = log
    }

    /// Stops the running commands, then deletes the copy. A signal handler calls it: a command left running would keep
    /// writing into the copy while it is deleted.
    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
        ProcessRunner.cancelAll()
        cleanUp()
        lock.lock()
        let expected = before
        lock.unlock()
        // The run is over, but it still owes the check that it left the package alone.
        if let expected {
            let changed = ProjectFingerprint.take(of: options.root).differences(from: expected)
            output(changed.isEmpty ? "Cancelled. The package is unchanged." : "error: the cancelled run changed the package: \(changed.joined(separator: ", "))")
        }
    }

    /// Prints, unless the run was cancelled: the commands that the cancel stopped fail, and their errors would mislead.
    private func log(_ text: String) {
        if !isCancelled { output(text) }
    }

    /// Deletes the copy. It takes a lock and may be called more than once.
    public func cleanUp() {
        lock.lock()
        defer { lock.unlock() }
        workFolder?.remove()
        workFolder = nil
    }

    public func run() -> Int32 {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: options.root.appendingPathComponent("Package.swift").path) else {
            log("error: \(options.root.path) has no Package.swift. Run the command in a Swift package.")
            return Status.failed
        }
        let started = Date()
        let before = ProjectFingerprint.take(of: options.root, runner: runner)
        lock.lock()
        self.before = before
        lock.unlock()
        do {
            if let removed = try WorkFolder.cleanUpAfterDeadRun(lockFolder: options.output) {
                log("Removed the copy that an earlier run left behind: \(removed.path)")
            }
            let location = try WorkFolder.chooseLocation(explicit: options.workDirectory, root: options.root)
            let folder = try WorkFolder(copying: options.root, into: location, lockFolder: options.output, runner: runner)
            lock.lock()
            workFolder = folder
            lock.unlock()
            defer { cleanUp() }
            var status = try mutate(in: folder.copy, started: started)
            if isCancelled { return Status.cancelled }
            cleanUp()
            let after = ProjectFingerprint.take(of: options.root, runner: runner)
            let changed = after.differences(from: before)
            if !changed.isEmpty {
                log("error: the run changed the package, which it must never do: \(changed.joined(separator: ", "))")
                status = Status.projectChanged
            } else {
                log("The package is unchanged.")
            }
            return status
        } catch {
            if isCancelled { return Status.cancelled }
            cleanUp()
            log("error: \(error)")
            return Status.failed
        }
    }

    private func mutate(in copy: URL, started: Date) throws -> Int32 {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: options.output, withIntermediateDirectories: true)
        let mutants = try findMutants(in: copy)
        if options.dryRun {
            mutants.forEach { log("  \($0.id). \($0.summary)") }
            return Status.completed
        }
        guard !mutants.isEmpty else { return Status.completed }
        guard let timeout = runBaseline(in: copy) else { return Status.baselineFailed }

        let runs = options.output.appendingPathComponent("runs")
        try? fileManager.removeItem(at: runs)
        try fileManager.createDirectory(at: runs, withIntermediateDirectories: true)
        var sources = [String: String]()
        var results = [MutantResult]()
        for mutant in mutants {
            let result = try test(mutant, in: copy, runs: runs, timeout: timeout, sources: &sources)
            results.append(result)
            log("\(mutant.id)/\(mutants.count) \(mutant.summary): \(result.verdict.name) (\(String(format: "%.1f", result.duration)) s)")
        }

        let report = try StrykerReport(results: results, sources: sources).encoded()
        try report.write(to: options.output.appendingPathComponent("mutation-report.json"))
        let summary = MutationSummary.text(results: results, duration: Date().timeIntervalSince(started))
        try summary.write(to: options.output.appendingPathComponent("summary.txt"), atomically: true, encoding: .utf8)
        log("\n" + summary + "Reports are in \(options.output.path)")
        return Status.completed
    }

    /// The mutants in the copy's source files, in file and line order and numbered from 1.
    private func findMutants(in copy: URL) throws -> [Mutant] {
        let files = swiftFiles(in: copy)
        var mutants = try discoverer.mutants(inFiles: files, relativeTo: copy)
        mutants.sort { ($0.file, $0.offset, $0.replacement) < ($1.file, $1.offset, $1.replacement) }
        if let limit = options.maxMutants { mutants = Array(mutants.prefix(limit)) }
        log("Found \(mutants.count) mutants in \(files.count) files.")
        return mutants.enumerated().map { $1.numbered($0 + 1) }
    }

    /// Builds the copy and runs the tests without a change. Returns how long a mutant's tests may run, or `nil`
    /// after logging why the baseline can't prove anything: the package doesn't build, its tests fail, or they run no test.
    private func runBaseline(in copy: URL) -> TimeInterval? {
        log("Building the copy and running the tests \(options.baselineRuns) times without a change.")
        let build = runner.run(options.swift, ["build", "--build-tests"] + options.swiftArguments, in: copy, environment: [:], timeout: nil)
        try? build.output.write(to: options.output.appendingPathComponent("build.log"), atomically: true, encoding: .utf8)
        guard build.succeeded else {
            log("error: the package doesn't build, so no mutant can be tested.\n\(tail(build.output))")
            return nil
        }
        var baseline = 0.0
        for number in 1...options.baselineRuns {
            let result = runTests(in: copy, environment: [:], timeout: nil)
            guard result.succeeded else {
                log("error: the tests fail without any change (run \(number)), so a failing mutant would prove nothing. Fix them first.\n\(tail(result.output))")
                return nil
            }
            guard result.testsRun > 0 else {
                log("error: the tests ran no test (run \(number)), so no mutant could fail one. The output is in \(options.output.path)/baseline.log\n\(tail(result.output))")
                try? result.output.write(to: options.output.appendingPathComponent("baseline.log"), atomically: true, encoding: .utf8)
                return nil
            }
            baseline = max(baseline, result.duration)
        }
        let timeout = max(options.minimumTimeout, baseline * options.timeoutMultiplier)
        log("The tests take \(String(format: "%.1f", baseline)) s. A mutant times out after \(String(format: "%.0f", timeout)) s.")
        return timeout
    }

    private func test(_ mutant: Mutant, in copy: URL, runs: URL, timeout: TimeInterval, sources: inout [String: String]) throws -> MutantResult {
        let path = copy.appendingPathComponent(mutant.file)
        let original = try String(contentsOf: path, encoding: .utf8)
        sources[mutant.file] = original
        let mutated = try mutant.applied(to: original)
        try mutated.write(to: path, atomically: true, encoding: .utf8)
        // Put the file back whatever happens next. The copy is deleted anyway; this keeps the next mutant clean.
        defer { try? original.write(to: path, atomically: true, encoding: .utf8) }
        let started = Date()
        let build = runner.run(options.swift, ["build", "--build-tests"] + options.swiftArguments, in: copy, environment: [:], timeout: nil)
        guard build.succeeded else {
            return MutantResult(mutant: mutant, verdict: .unviable, duration: Date().timeIntervalSince(started))
        }
        let report = runs.appendingPathComponent("mutant-\(mutant.id).json")
        let result = runTests(in: copy, environment: ["CUCUMBER_REPORT_PATH": report.path, "CUCUMBERSWIFT_MUTANT": String(mutant.id)], timeout: timeout)
        try? result.output.write(to: runs.appendingPathComponent("mutant-\(mutant.id).log"), atomically: true, encoding: .utf8)
        if !result.timedOut, result.testsRun == 0 {
            throw RunError.noTestsRan(mutant: mutant.summary, log: runs.appendingPathComponent("mutant-\(mutant.id).log").path)
        }
        var verdict: Verdict
        if result.timedOut {
            verdict = .timedOut
        } else if result.status == 0 {
            verdict = .survived
        } else {
            verdict = .killed(by: [])
        }
        let outcome = MutantResult(mutant: mutant, verdict: verdict, duration: Date().timeIntervalSince(started))
        if let data = try? Data(contentsOf: report), let annotated = CucumberReportAnnotator.annotate(data, result: outcome) {
            try annotated.data.write(to: options.output.appendingPathComponent("cucumber-mutant-\(mutant.id).json"))
            if case .killed = verdict { verdict = .killed(by: annotated.failedSteps) }
        }
        return MutantResult(mutant: mutant, verdict: verdict, duration: outcome.duration)
    }

    private func runTests(in copy: URL, environment: [String: String], timeout: TimeInterval?) -> CommandResult {
        runner.run(options.swift, ["test", "--skip-build"] + options.swiftArguments, in: copy, environment: environment, timeout: timeout)
    }

    /// The Swift files under the source folders, in the copy, not in build folders.
    private func swiftFiles(in copy: URL) -> [URL] {
        var files = [URL]()
        for folder in options.sources {
            let root = copy.appendingPathComponent(folder)
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { continue }
            let base = root.pathComponents.count
            for case let url as URL in enumerator where url.pathExtension == "swift" {
                // Judge the path inside the source folder: the copy itself may sit under a .build folder.
                if !url.pathComponents.dropFirst(base).contains(".build") { files.append(url) }
            }
        }
        return files.sorted { $0.path < $1.path }
    }

    private func tail(_ output: String, lines: Int = 25) -> String {
        output.split(separator: "\n", omittingEmptySubsequences: false).suffix(lines).joined(separator: "\n")
    }
}
