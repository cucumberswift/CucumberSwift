//
//  SwiftPMRunner.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// Builds a Swift package with `swift build --build-tests` and tests it with `swift test --skip-build`.
///
/// It runs every scenario whatever `TestRequest.scenarios` says. `swift test --filter` knows only the tests that the
/// bundle declares, and CucumberSwift generates one for each scenario while the bundle runs, so no filter can select
/// one: it runs no test, and succeeds. A mutant still gets the verdict of the whole suite, only slower.
public final class SwiftPMRunner: TestRunner, @unchecked Sendable {
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    private let swift: String
    /// What every `swift build` and `swift test` gets, such as `--disable-sandbox`.
    private let arguments: [String]
    private let commands: CommandRunning
    private let lock = NSLock()
    private var runs = 0

    public init(swift: String = "/usr/bin/swift", arguments: [String] = [], commands: CommandRunning = ProcessRunner()) {
        self.swift = swift
        self.arguments = arguments
        self.commands = commands
    }

    /// The runner for the options: their `swift` and the arguments they give every command.
    public convenience init(options: MutationOptions, commands: CommandRunning = ProcessRunner()) {
        self.init(swift: options.swift, arguments: options.swiftArguments, commands: commands)
    }

    public func prepare(copy: URL) throws {
        guard FileManager.default.fileExists(atPath: copy.appendingPathComponent("Package.swift").path) else {
            throw Failure(description: "\(copy.path) has no Package.swift")
        }
        _ = try makeFolder(runnerFolder(for: copy))
    }

    public func build(in copy: URL, timeout: TimeInterval?) -> BuildResult {
        // As `swift test --enable-code-coverage` builds, so that a run can measure the code each scenario runs. Every
        // build uses the same flags, so a mutant's rebuilds only what it changed.
        let coverage = ["-Xswiftc", "-profile-generate", "-Xswiftc", "-profile-coverage-mapping"]
        let result = commands.run(swift, ["build", "--build-tests"] + arguments + coverage, in: copy, environment: [:], timeout: timeout)
        return BuildResult(succeeded: result.succeeded, duration: result.duration, log: write(result.output, named: "build", in: copy), started: result.started)
    }

    public func test(in copy: URL, request: TestRequest) -> TestRun {
        let folder = runnerFolder(for: copy)
        let number = nextRun()
        var environment = request.settings
        var report: URL?
        var coverage: URL?
        if request.writesReport {
            let file = folder.appendingPathComponent("reports/report-\(number).json")
            environment["CUCUMBER_REPORT_PATH"] = file.path
            report = file
        }
        if request.measuresCoverage {
            let folder = folder.appendingPathComponent("coverage-\(number)")
            environment["CUCUMBER_COVERAGE"] = "YES"
            environment["CUCUMBER_COVERAGE_PATH"] = folder.path
            coverage = folder
        }
        let result = commands.run(swift, ["test", "--skip-build"] + arguments, in: copy, environment: environment, timeout: request.timeout)
        var run = TestRun(
            status: result.status,
            timedOut: result.timedOut,
            duration: result.duration,
            testsRun: result.testsRun,
            log: write(result.output, named: "test-\(number)", in: copy),
            cucumberReport: report.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil },
            coverageFolder: coverage.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        )
        run.started = result.started
        return run
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
