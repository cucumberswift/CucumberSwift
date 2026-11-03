//
//  CommandRunning.swift
//  CucumberSwiftMutation
//

import Foundation

/// What a finished command printed, and how it ended.
public struct CommandResult: Equatable, Sendable {
    public let status: Int32
    public let output: String
    /// The command was stopped because it ran longer than its timeout.
    public let timedOut: Bool
    public let duration: TimeInterval

    public var succeeded: Bool { status == 0 && !timedOut }

    /// How many tests the output says ran. `swift test` prints XCTest's total as `Executed 5 tests` and Swift
    /// Testing's as `Test run with 3 tests`, and a package may use either or both.
    public var testsRun: Int {
        largestCount(after: "Executed ") + largestCount(after: "Test run with ")
    }

    /// The largest number that follows `prefix` and is followed by " test" in the output.
    private func largestCount(after prefix: String) -> Int {
        guard let expression = try? NSRegularExpression(pattern: "\(prefix)([0-9]+) tests?") else { return 0 }
        let matches = expression.matches(in: output, range: NSRange(output.startIndex..., in: output))
        let counts = matches.compactMap { match -> Int? in
            Range(match.range(at: 1), in: output).flatMap { Int(output[$0]) }
        }
        return counts.max() ?? 0
    }
}

/// Runs a command to its end, or stops it, and the commands it started, at a timeout.
public protocol CommandRunning: Sendable {
    func run(
        _ executable: String,
        _ arguments: [String],
        in directory: URL,
        environment: [String: String],
        timeout: TimeInterval?
    ) -> CommandResult
}
