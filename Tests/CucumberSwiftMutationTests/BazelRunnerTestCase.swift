//
//  BazelRunnerTestCase.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

/// True the first time `consume()` is called, false after.
final class FirstOnly: @unchecked Sendable {
    private let lock = NSLock()
    private var used = false
    func consume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        defer { used = true }
        return !used
    }
}

/// What the Bazel runner's tests share: a workspace copy, a runner on a fake `bazel`, and a fake that writes where Bazel does.
class BazelRunnerTestCase: TemporaryFolderTestCase {
    let target = BazelRunner.Target(label: "//Tests:AppTests")

    func makeCopy(workspaceFile: String = "MODULE.bazel") throws -> URL {
        let copy = folder.appendingPathComponent("work/workspace")
        try FileManager.default.createDirectory(at: copy, withIntermediateDirectories: true)
        try "module(name = \"app\")\n".write(to: copy.appendingPathComponent(workspaceFile), atomically: true, encoding: .utf8)
        return copy
    }

    func runner(
        _ target: BazelRunner.Target? = nil,
        commands: CommandRunning,
        cleanUp: CommandRunning? = nil,
        environment: [String: String] = [:]
    ) -> BazelRunner {
        BazelRunner(
            target: target ?? self.target,
            bazel: "/usr/bin/true",
            diskCache: folder.appendingPathComponent("cache"),
            commands: commands,
            cleanUpCommands: cleanUp ?? commands,
            environment: environment
        )
    }

    /// A `bazel` that writes the test's log where Bazel does, with `output` in it, and the coverage it leaves in the test's outputs.
    func commands(in copy: URL, output: String = "Executed 3 tests, with 0 failures", status: Int32 = 0, coverage: Bool = false) -> RecordingCommands {
        RecordingCommands { call in
            if call.command == "test" {
                let logs = copy.appendingPathComponent("bazel-testlogs/Tests/AppTests")
                try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
                try? output.write(to: logs.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                if coverage {
                    let run = logs.appendingPathComponent("test.outputs/_cucumberCoverage/run-1")
                    try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                    try? "{}".write(to: run.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
                }
            }
            return .finished(status, output: "bazel output")
        }
    }
}

extension RecordingCommands.Call {
    /// The arguments after the startup options, which start with the command: `build`, `test`, `clean` or `shutdown`.
    var afterStartup: [String] { Array(arguments.drop { $0.hasPrefix("--output_base=") }) }
    var command: String? { afterStartup.first }
}
#endif
