//
//  BazelRunner.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// Builds a Bazel test target with `bazel build` and tests it with `bazel test`, with code coverage on.
///
/// CucumberSwift's settings reach the tests as `--test_env=K=V`, because Bazel gives a test only the variables it is
/// told to: the tool's own `CUCUMBER_*` variables go the same way, as they do with SwiftPM, where the tests inherit them.
/// The test count comes from the test's own log in `bazel-testlogs`, which `bazel test` writes whether or not it prints it.
/// Bazel's `test.xml` can't give it: Bazel writes that file itself, with one test for the target.
///
/// A project builds with LLVM's coverage format under `bazel coverage` and here: the runner passes
/// `--features=llvm_coverage_map_format`, because the bundle doesn't link with Bazel's default, gcov's. A run of some
/// scenarios sets `CUCUMBER_SCENARIOS`, as the SwiftPM runner does: a filter selects tests by the names the bundle
/// declares, and CucumberSwift generates one for each scenario while the bundle runs.
///
/// The disk cache is shared by every copy and every run, so a new copy, which Bazel builds in a folder of its own, finds
/// what an earlier one built. The copy's output base is deleted with `bazel clean --expunge` after the run: Bazel keeps
/// one for each workspace folder, and the copies are deleted.
public final class BazelRunner: TestRunner, @unchecked Sendable {
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    /// What to build and test.
    public struct Target: Equatable, Sendable {
        /// The test target's label, such as `//Tests:AppTests`.
        public var label: String
        /// More arguments for every `bazel build` and `bazel test`, such as `--config=ci`.
        public var arguments: [String]

        /// The package folder and the target's name: `Tests` and `AppTests` for `//Tests:AppTests`. Nil for a label
        /// of another repository, whose test logs aren't in the workspace's package folders.
        var package: (folder: String, name: String)? {
            guard label.hasPrefix("//") else { return nil }
            let path = label.dropFirst(2)
            let parts = path.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let folder = String(parts[0])
            let name = parts.count > 1 ? String(parts[1]) : String(folder.split(separator: "/").last ?? "")
            return name.isEmpty ? nil : (folder, name)
        }

        public init(label: String, arguments: [String] = []) {
            self.label = label
            self.arguments = arguments
        }
    }

    /// The files whose presence says a folder is a Bazel workspace.
    static let workspaceFiles = ["MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE"]

    /// The disk cache every run shares, in the user's caches folder.
    public static var defaultDiskCache: URL? {
        try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("CucumberSwiftMutation/bazel-disk-cache", isDirectory: true)
    }

    private let target: Target
    private let bazel: String
    private let diskCache: URL?
    private let commands: CommandRunning
    /// Runs the clean-up, which must work after a cancel, when the other commands don't.
    private let cleanUpCommands: CommandRunning
    /// The tool's environment. Its `CUCUMBER_*` variables reach the tests.
    private let environment: [String: String]
    private let lock = NSLock()
    private var runs = 0

    /// The Bazel to run: `bazel` as a full path, or found in the folders of PATH and where Homebrew and Bazelisk put it.
    private var executable: String? {
        if bazel.contains("/") { return FileManager.default.isExecutableFile(atPath: bazel) ? bazel : nil }
        let folders = (environment["PATH"] ?? "").split(separator: ":").map(String.init) + ["/opt/homebrew/bin", "/usr/local/bin"]
        return folders.map { "\($0)/\(bazel)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// What every `bazel build` and `bazel test` gets, so that the test reuses what the build made: coverage on, in
    /// LLVM's format, and the shared disk cache.
    private var common: [String] {
        var arguments = ["--collect_code_coverage", "--features=llvm_coverage_map_format", "--features=-gcc_coverage_map_format"]
        if let diskCache, !target.arguments.contains(where: { $0.hasPrefix("--disk_cache") }) {
            arguments.append("--disk_cache=\(diskCache.path)")
        }
        return arguments + target.arguments
    }

    public init(
        target: Target,
        bazel: String = "bazel",
        diskCache: URL? = BazelRunner.defaultDiskCache,
        commands: CommandRunning = ProcessRunner(),
        cleanUpCommands: CommandRunning = ProcessRunner(ignoresCancellation: true),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.target = target
        self.bazel = bazel
        self.diskCache = diskCache
        self.commands = commands
        self.cleanUpCommands = cleanUpCommands
        self.environment = environment
    }

    public func prepare(copy: URL) throws {
        guard Self.workspaceFiles.contains(where: { FileManager.default.fileExists(atPath: copy.appendingPathComponent($0).path) }) else {
            throw Failure(description: "\(copy.path) has no MODULE.bazel")
        }
        guard target.package != nil else {
            throw Failure(description: "\(target.label) isn't a label in this workspace: --bazel-target needs one that starts with //, such as //Tests:AppTests")
        }
        guard executable != nil else {
            throw Failure(description: "Couldn't find \(bazel). Install Bazel, or pass --bazel with its path.")
        }
        if let diskCache { try FileManager.default.createDirectory(at: diskCache, withIntermediateDirectories: true) }
        _ = try makeFolder(runnerFolder(for: copy))
    }

    public func build(in copy: URL, timeout: TimeInterval?) -> BuildResult {
        guard let executable else { return BuildResult(succeeded: false) }
        let result = commands.run(executable, ["build", target.label] + common, in: copy, environment: [:], timeout: timeout)
        return BuildResult(succeeded: result.succeeded, duration: result.duration, log: write(result.output, named: "build", in: copy))
    }

    public func test(in copy: URL, request: TestRequest) -> TestRun {
        guard let executable else { return TestRun(status: 127) }
        let folder = runnerFolder(for: copy)
        let number = nextRun()
        var settings = environment.filter { $0.key.hasPrefix("CUCUMBER_") }
        settings.merge(request.settings) { _, new in new }
        settings.merge(request.scenarioSettings) { _, new in new }
        var arguments = ["test", target.label] + common + ["--nocache_test_results", "--test_output=all"]
        var report: URL?
        if request.writesReport {
            // The test's sandbox allows writes only to the test's own folders and what it is told: the report folder.
            let reports = folder.appendingPathComponent("reports")
            try? FileManager.default.createDirectory(at: reports, withIntermediateDirectories: true)
            report = reports.appendingPathComponent("report-\(number).json")
            settings["CUCUMBER_REPORT_PATH"] = report?.path
            arguments.append("--sandbox_writable_path=\(reports.resolvingSymlinksInPath().path)")
        }
        // CucumberSwift writes its coverage into the test's outputs when no path is set: Bazel gives the test a folder for it.
        if request.measuresCoverage { settings["CUCUMBER_COVERAGE"] = "YES" }
        for (key, value) in settings.sorted(by: { $0.key < $1.key }) { arguments.append("--test_env=\(key)=\(value)") }
        let result = commands.run(executable, arguments, in: copy, environment: [:], timeout: request.timeout)
        let log = testLog(in: copy)
        let output = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
        return TestRun(
            status: result.status,
            timedOut: result.timedOut,
            duration: result.duration,
            testsRun: CommandResult(status: 0, output: output, timedOut: false, duration: 0).testsRun,
            log: write(result.output, named: "test-\(number)", in: copy),
            cucumberReport: report.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil },
            coverageFolder: request.measuresCoverage ? keepCoverage(from: log.deletingLastPathComponent(), as: number, in: folder) : nil
        )
    }

    /// The test's log in `bazel-testlogs`, which Bazel writes to the copy's convenience link.
    private func testLog(in copy: URL) -> URL {
        let (folder, name) = target.package ?? ("", "")
        let logs = copy.appendingPathComponent("bazel-testlogs").appendingPathComponent(folder)
        return logs.appendingPathComponent(name).appendingPathComponent("test.log")
    }

    /// Copies the coverage the test left in its outputs to a folder of its own, because the next test run replaces the outputs.
    private func keepCoverage(from testFolder: URL, as number: Int, in folder: URL) -> URL? {
        let source = testFolder.appendingPathComponent("test.outputs/_cucumberCoverage")
        let destination = folder.appendingPathComponent("coverage-\(number)")
        guard FileManager.default.fileExists(atPath: source.path) else { return nil }
        try? FileManager.default.removeItem(at: destination)
        return (try? FileManager.default.copyItem(at: source.resolvingSymlinksInPath(), to: destination)) == nil ? nil : destination
    }

    /// Stops the server and deletes the output base of the copy, which Bazel keeps outside it. Killing `bazel` leaves
    /// the server running, so this runs after a cancel too.
    public func cleanUp(copy: URL) {
        guard let executable, FileManager.default.fileExists(atPath: copy.path) else { return }
        let result = cleanUpCommands.run(executable, ["clean", "--expunge"], in: copy, environment: [:], timeout: 120)
        if !result.succeeded {
            _ = cleanUpCommands.run(executable, ["shutdown"], in: copy, environment: [:], timeout: 60)
        }
    }

    private func nextRun() -> Int {
        lock.lock()
        defer { lock.unlock() }
        runs += 1
        return runs
    }

    private func write(_ output: String, named name: String, in copy: URL) -> URL? {
        guard let folder = try? makeFolder(runnerFolder(for: copy).appendingPathComponent("logs")) else { return nil }
        let url = folder.appendingPathComponent("\(name).log")
        return (try? output.write(to: url, atomically: true, encoding: .utf8)) == nil ? nil : url
    }
}
#endif
