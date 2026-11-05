//
//  RunnerSupport.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}

final class CopyListing: @unchecked Sendable {
    var names = [String]()
}

/// A runner that runs nothing and counts what the run asks of it.
final class SpyRunner: TestRunner, @unchecked Sendable {
    struct PrepareFailure: Error, CustomStringConvertible {
        let description = "cannot prepare"
    }

    private let prepared: Counter
    private let cleaned: Counter
    private let buildStatus: Bool
    private let testsRun: Int
    private let prepareFails: Bool
    let excludedFromCopy: [String]
    var onPrepare: (URL) -> Void = { _ in }

    init(prepared: Counter, cleaned: Counter, buildStatus: Bool = true, testsRun: Int = 3, prepareFails: Bool = false, excluded: [String] = []) {
        self.prepared = prepared
        self.cleaned = cleaned
        self.buildStatus = buildStatus
        self.testsRun = testsRun
        self.prepareFails = prepareFails
        excludedFromCopy = excluded
    }

    func prepare(copy: URL) throws {
        prepared.increment()
        onPrepare(copy)
        if prepareFails { throw PrepareFailure() }
    }

    func build(in copy: URL, timeout: TimeInterval?) -> BuildResult {
        BuildResult(succeeded: buildStatus, duration: 1)
    }

    func test(in copy: URL, request: TestRequest) -> TestRun {
        TestRun(status: 0, duration: 1, testsRun: testsRun)
    }

    func cleanUp(copy: URL) {
        cleaned.increment()
    }
}

/// Runs nothing and records each command, as `FakeRunner` does for `swift`.
final class RecordingCommands: CommandRunning, @unchecked Sendable {
    struct Call: Equatable {
        let executable: String
        let arguments: [String]
        let environment: [String: String]
        let timeout: TimeInterval?
    }

    private let lock = NSLock()
    private var recorded = [Call]()
    private let handler: (Call) -> CommandResult

    var calls: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    init(handler: @escaping (Call) -> CommandResult = { _ in .finished(0) }) {
        self.handler = handler
    }

    func run(_ executable: String, _ arguments: [String], in directory: URL, environment: [String: String], timeout: TimeInterval?) -> CommandResult {
        // The commands that copy and delete are real, as with `FakeRunner`; only the build tools are replaced.
        if ["/bin/cp", "/bin/chmod", "/usr/bin/git"].contains(executable) {
            return ProcessRunner().run(executable, arguments, in: directory, environment: environment, timeout: timeout)
        }
        let call = Call(executable: executable, arguments: arguments, environment: environment, timeout: timeout)
        lock.lock()
        recorded.append(call)
        lock.unlock()
        return handler(call)
    }
}
