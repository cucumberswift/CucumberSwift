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

/// One mutation testing run: copy the project, find the mutants, run the tests against each in the copy,
/// write the reports, delete the copy. A `TestRunner` builds the copy and runs its tests: SwiftPM for a package,
/// `xcodebuild` for an Xcode project.
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
    private let testRunner: TestRunner
    private let output: (String) -> Void
    private let lock = NSLock()
    private var workFolder: WorkFolder?
    private var before: ProjectFingerprint?
    private var cancelled = false

    /// The Cucumber report of the first run without a change.
    private var baselineReport: URL { options.output.appendingPathComponent("cucumber-baseline.json") }

    private var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public init(
        options: MutationOptions,
        discoverer: MutantDiscovering,
        runner: CommandRunning = ProcessRunner(),
        testRunner: TestRunner? = nil,
        log: @escaping (String) -> Void = { print($0) }
    ) {
        self.options = options
        self.discoverer = discoverer
        self.runner = runner
        self.testRunner = testRunner ?? options.makeRunner(commands: runner)
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

    /// Lets the runner clean up, then deletes the copy. It takes a lock and may be called more than once.
    public func cleanUp() {
        lock.lock()
        defer { lock.unlock() }
        if let workFolder { testRunner.cleanUp(copy: workFolder.copy) }
        workFolder?.remove()
        workFolder = nil
    }

    public func run() -> Int32 {
        if let problem = options.rootProblem {
            log("error: \(problem)")
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
            let folder = try WorkFolder(copying: options.root, into: location, lockFolder: options.output, excluding: testRunner.excludedFromCopy, runner: runner)
            lock.lock()
            workFolder = folder
            lock.unlock()
            defer { cleanUp() }
            try testRunner.prepare(copy: folder.copy)
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
        let coverage = ScenarioCoverage.read(inRunsUnder: options.output.appendingPathComponent("coverage"))
        if let coverage {
            log("Coverage: \(coverage.scenarios.count) scenarios ran. A mutant in code that no scenario runs isn't tested.")
        } else {
            log("No coverage of the scenarios: the package doesn't measure it with CucumberSwift, so every mutant is tested.")
        }

        let runs = options.output.appendingPathComponent("runs")
        try? fileManager.removeItem(at: runs)
        try fileManager.createDirectory(at: runs, withIntermediateDirectories: true)
        var sources = [String: String]()
        var results = [MutantResult]()
        for mutant in mutants {
            var result = try test(mutant, in: copy, runs: runs, timeout: timeout, coverage: coverage, sources: &sources)
            if let coverage { result.coveredBy = coverage.scenarios(running: mutant) }
            results.append(result)
            log("\(mutant.id)/\(mutants.count) \(mutant.summary): \(result.verdict.name) (\(String(format: "%.1f", result.duration)) s)")
        }

        let ran = (try? Data(contentsOf: baselineReport)).flatMap(CucumberReportAnnotator.scenarios(in:)) ?? []
        let report = try StrykerReport(results: results, sources: sources, ran: ran).encoded()
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
        log("Found \(mutants.count) \(mutants.count == 1 ? "mutant" : "mutants") in \(files.count) \(files.count == 1 ? "file" : "files").")
        return mutants.enumerated().map { $1.numbered($0 + 1) }
    }

    /// Builds the copy and runs the tests without a change. Returns how long a mutant's tests may run, or `nil`
    /// after logging why the baseline can't prove anything: the project doesn't build, its tests fail, or they run no test.
    private func runBaseline(in copy: URL) -> TimeInterval? {
        log("Building the copy and running the tests \(options.baselineRuns) times without a change.")
        let build = testRunner.build(in: copy, timeout: nil)
        let buildOutput = contents(of: build.log)
        try? buildOutput.write(to: options.output.appendingPathComponent("build.log"), atomically: true, encoding: .utf8)
        guard build.succeeded else {
            log("error: the project doesn't build, so no mutant can be tested.\n\(tail(buildOutput))")
            return nil
        }
        var baseline = 0.0
        // Start from nothing, so a stale folder from an earlier run can't pass for this run's coverage.
        let coverageFolder = options.output.appendingPathComponent("coverage")
        try? FileManager.default.removeItem(at: coverageFolder)
        try? FileManager.default.removeItem(at: baselineReport)
        for number in 1...options.baselineRuns {
            // The first run measures the code each scenario runs, into regions.json, and writes the Cucumber report that
            // lists every scenario the run tests, for the report's `testFiles`; the mutants' runs measure nothing.
            let request = number == 1
                ? TestRequest(settings: ["CUCUMBER_COVERAGE_REGIONS": "YES"], measuresCoverage: true, writesReport: true)
                : TestRequest()
            let result = testRunner.test(in: copy, request: request)
            let output = contents(of: result.log)
            guard result.succeeded else {
                log("error: the tests fail without any change (run \(number)), so a failing mutant would prove nothing. Fix them first.\n\(tail(output))")
                return nil
            }
            guard result.testsRun > 0 else {
                log("error: the tests ran no test (run \(number)), so no mutant could fail one. The output is in \(options.output.path)/baseline.log\n\(tail(output))")
                try? output.write(to: options.output.appendingPathComponent("baseline.log"), atomically: true, encoding: .utf8)
                return nil
            }
            if number == 1 { keep(result, as: baselineReport, coverage: coverageFolder) }
            baseline = max(baseline, result.duration)
        }
        let timeout = max(options.minimumTimeout, baseline * options.timeoutMultiplier)
        log("The tests take \(String(format: "%.1f", baseline)) s. A mutant times out after \(String(format: "%.0f", timeout)) s.")
        return timeout
    }

    /// Copies the baseline's Cucumber report and coverage out of the runner's folders, which are deleted with the copy.
    private func keep(_ baseline: TestRun, as report: URL, coverage: URL) {
        if let source = baseline.cucumberReport { try? FileManager.default.copyItem(at: source, to: report) }
        if let source = baseline.coverageFolder { try? FileManager.default.copyItem(at: source, to: coverage) }
    }

    private func test(
        _ mutant: Mutant,
        in copy: URL,
        runs: URL,
        timeout: TimeInterval,
        coverage: ScenarioCoverage?,
        sources: inout [String: String]
    ) throws -> MutantResult {
        let path = copy.appendingPathComponent(mutant.file)
        let original = try String(contentsOf: path, encoding: .utf8)
        sources[mutant.file] = original
        // A comment in the code marks it as one no test can notice: neither tested nor counted.
        if let reason = mutant.ignoredReason { return MutantResult(mutant: mutant, verdict: .ignored(reason: reason), duration: 0) }
        // No scenario ran this code without the change, so none can notice the change: don't spend a build on it.
        if let coverage, coverage.scenarios(running: mutant).isEmpty { return MutantResult(mutant: mutant, verdict: .noCoverage, duration: 0) }
        let mutated = try mutant.applied(to: original)
        try mutated.write(to: path, atomically: true, encoding: .utf8)
        // Put the file back whatever happens next. The copy is deleted anyway; this keeps the next mutant clean.
        defer { try? original.write(to: path, atomically: true, encoding: .utf8) }
        let started = Date()
        guard testRunner.build(in: copy, timeout: nil).succeeded else {
            return MutantResult(mutant: mutant, verdict: .unviable, duration: Date().timeIntervalSince(started))
        }
        let settings = ["CUCUMBERSWIFT_MUTANT": String(mutant.id), "CUCUMBER_COVERAGE": "NO"]
        let result = testRunner.test(in: copy, request: TestRequest(settings: settings, writesReport: true, timeout: timeout))
        let logFile = runs.appendingPathComponent("mutant-\(mutant.id).log")
        try? contents(of: result.log).write(to: logFile, atomically: true, encoding: .utf8)
        if !result.timedOut, result.testsRun == 0 {
            throw RunError.noTestsRan(mutant: mutant.summary, log: logFile.path)
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
        var killedBy = [ScenarioID]()
        let report = result.cucumberReport.flatMap { try? Data(contentsOf: $0) }
        // The report as the run wrote it, next to its log.
        if let report { try? report.write(to: runs.appendingPathComponent("mutant-\(mutant.id).json")) }
        if let report, let annotated = CucumberReportAnnotator.annotate(report, result: outcome) {
            try annotated.data.write(to: options.output.appendingPathComponent("cucumber-mutant-\(mutant.id).json"))
            if case .killed = verdict {
                verdict = .killed(by: annotated.failedSteps)
                killedBy = annotated.failedScenarios
            }
        }
        return MutantResult(mutant: mutant, verdict: verdict, duration: outcome.duration, killedBy: killedBy)
    }

    /// What the runner wrote to `log`, or nothing when it wrote no log.
    private func contents(of log: URL?) -> String {
        log.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    }
}

// Reading the copy's files and the tools' output.
extension MutationRun {
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
