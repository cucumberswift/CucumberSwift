//
//  ProcessRunner.swift
//  CucumberSwiftMutation
//

import Foundation

private final class Registry: @unchecked Sendable {
    private let lock = NSLock()
    private var pids = Set<Int32>()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func add(_ pid: Int32) {
        lock.lock()
        pids.insert(pid)
        lock.unlock()
    }

    func remove(_ pid: Int32) {
        lock.lock()
        pids.remove(pid)
        lock.unlock()
    }

    /// Marks the registry cancelled, and returns the commands to stop.
    func cancel() -> Set<Int32> {
        lock.lock()
        defer { lock.unlock() }
        cancelled = true
        return pids
    }
}

private final class Collected: @unchecked Sendable {
    private let lock = NSLock()
    private var value = Data()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ data: Data) {
        lock.lock()
        value = data
        lock.unlock()
    }
}

public struct ProcessRunner: CommandRunning {
    /// The commands that are running, so that a signal can stop them: a command that outlives the tool keeps
    /// writing into the copy that the tool is deleting.
    private static let registry = Registry()

    /// A runner for the commands that must run even when the run is cancelled, such as `git status` to check
    /// that the package is unchanged.
    private let ignoresCancellation: Bool

    /// Stops every running command and its children, and refuses to start another. Called when the run is cancelled.
    public static func cancelAll() {
        for pid in registry.cancel() { terminateTree(of: pid) }
    }

    /// Stops a process and everything it started: `swift test` runs the tests in a child process, which a
    /// signal to `swift test` alone would leave running.
    static func terminateTree(of root: Int32) {
        let pids = descendants(of: root) + [root]
        // Children first, so none can start another once its parent is gone.
        for pid in pids.reversed() { kill(pid, SIGTERM) }
        Thread.sleep(forTimeInterval: 1)
        for pid in pids.reversed() where kill(pid, 0) == 0 { kill(pid, SIGKILL) }
    }

    static func descendants(of root: Int32) -> [Int32] {
        let ps = Process()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-A", "-o", "pid=,ppid="]
        let pipe = Pipe()
        ps.standardOutput = pipe
        guard (try? ps.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        ps.waitUntilExit()
        var children = [Int32: [Int32]]()
        let text = String(bytes: data, encoding: .utf8) ?? ""
        for line in text.split(separator: "\n") {
            let fields = line.split(separator: " ").compactMap { Int32($0) }
            if fields.count == 2 { children[fields[1], default: []].append(fields[0]) }
        }
        var found = [Int32]()
        var queue = [root]
        while let next = queue.popLast() {
            for child in children[next] ?? [] where !found.contains(child) {
                found.append(child)
                queue.append(child)
            }
        }
        return found
    }

    public init(ignoresCancellation: Bool = false) {
        self.ignoresCancellation = ignoresCancellation
    }

    public func run(
        _ executable: String,
        _ arguments: [String],
        in directory: URL,
        environment: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) -> CommandResult {
        guard ignoresCancellation || !Self.registry.isCancelled else {
            return CommandResult(status: 130, output: "Cancelled", timedOut: false, duration: 0)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let start = Date()
        do {
            try process.run()
        } catch {
            return CommandResult(status: 127, output: "Couldn't run \(executable): \(error)", timedOut: false, duration: 0)
        }
        Self.registry.add(process.processIdentifier)
        defer { Self.registry.remove(process.processIdentifier) }
        // Read while the command runs, so a long output can't fill the pipe and stop it.
        let collected = Collected()
        let reading = DispatchGroup()
        reading.enter()
        DispatchQueue.global().async {
            collected.set(pipe.fileHandleForReading.readDataToEndOfFile())
            reading.leave()
        }
        let timedOut = wait(for: process, timeout: timeout)
        reading.wait()
        return CommandResult(
            status: process.terminationStatus,
            output: String(bytes: collected.data, encoding: .utf8) ?? "",
            timedOut: timedOut,
            duration: Date().timeIntervalSince(start)
        )
    }

    /// Waits for the process to end, or stops it and its children at the timeout. Returns whether it timed out.
    private func wait(for process: Process, timeout: TimeInterval?) -> Bool {
        guard let timeout else {
            process.waitUntilExit()
            return false
        }
        let finished = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            process.waitUntilExit()
            finished.signal()
        }
        guard finished.wait(timeout: .now() + timeout) == .timedOut else { return false }
        Self.terminateTree(of: process.processIdentifier)
        process.waitUntilExit()
        return true
    }
}
