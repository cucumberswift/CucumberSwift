//
//  RecordingCommands.swift
//  CucumberSwiftMutationTests
//

import Foundation
@testable import CucumberSwiftMutation

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
