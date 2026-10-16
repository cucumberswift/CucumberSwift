//
//  RunningLocation.swift
//  CucumberSwiftTesting
//
// A failed `#expect` is reported where it is written, in a step definition. CucumberSwift reports a failed
// XCTest assertion at its step's line in the feature file instead, so this runner does the same with an
// issue handling trait, which the generated tests have. Issue handling traits need Swift 6.2; before it,
// issues stay where they were recorded.

import Foundation
import Testing

#if !compiler(>=6.2)
/// Before Swift 6.2, which has issue handling traits, issues stay where they were recorded.
public struct FeatureFileIssuesTrait: SuiteTrait, TestTrait {
    public var isRecursive: Bool { true }
}
#endif

/// What issues were recorded while a step, or a scenario's hooks, ran. Swift Testing records an issue,
/// such as a failed `#expect`, without telling the code that is running, so the runner learns of it from
/// the issue handling trait, which reports it here. Before Swift 6.2 it has no way to, and the record
/// stays empty: a step that only fails an `#expect` is then reported as passed.
final class IssueRecord: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded = [String]()

    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func add(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(message)
    }
}

/// Where in a feature file the runner is: the step that is running, or the scenario while its hooks run.
/// It is a task-local value, so scenarios that run at the same time each see their own.
enum RunningLocation {
    struct Running: Sendable {
        let location: SourceLocation
        /// The step as it runs, such as "Then the basket has 3 cukes", or nil while a scenario hook runs.
        let step: String?
        /// Where the issues recorded now are noted, for the report.
        var record: IssueRecord?
    }

    /// The running step or hook of the current task, and of the tasks it creates, but not detached ones.
    @TaskLocal static var current: Running?
}

#if compiler(>=6.2)
extension Trait where Self == IssueHandlingTrait {
    /// Reports each issue recorded while a step or a hook runs, such as a failed `#expect`, at the step's
    /// line in its feature file, or the scenario's for a scenario hook, with comments that give the step as
    /// it ran, with an example's values, and where the issue was recorded. The tests that
    /// CucumberSwiftTestingPlugin generates have it.
    public static var reportedInFeatureFiles: Self {
        .compactMapIssues { issue in
            guard let running = RunningLocation.current,
                  let recorded = issue.sourceLocation,
                  !recorded.fileName.hasSuffix(".feature") else { return issue }
            running.record?.add(issue.description)
            var issue = issue
            if let step = running.step {
                issue.comments.append(Comment(rawValue: step))
            }
            issue.comments.append("Recorded at \(recorded.fileName):\(recorded.line)")
            issue.sourceLocation = running.location
            return issue
        }
    }
}
#else
extension Trait where Self == FeatureFileIssuesTrait {
    /// Does nothing before Swift 6.2. From Swift 6.2, reports each issue recorded while a step or a hook
    /// runs at its line in the feature file.
    public static var reportedInFeatureFiles: Self { Self() }
}
#endif
