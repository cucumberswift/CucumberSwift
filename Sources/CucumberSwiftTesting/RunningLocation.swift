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

/// Where in a feature file the runner is: the step that is running, or the scenario while its hooks run.
final class RunningLocation: @unchecked Sendable {
    static let shared = RunningLocation()

    private let lock = NSLock()
    private var location: SourceLocation?

    var current: SourceLocation? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return location
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            location = newValue
        }
    }
}

#if compiler(>=6.2)
extension Trait where Self == IssueHandlingTrait {
    /// Reports each issue recorded while a step or a hook runs, such as a failed `#expect`, at the step's
    /// line in its feature file, or the scenario's for a scenario hook, with a comment that says where it
    /// was recorded. The tests that CucumberSwiftTestingPlugin generates have it.
    public static var reportedInFeatureFiles: Self {
        .compactMapIssues { issue in
            guard let location = RunningLocation.shared.current,
                  let recorded = issue.sourceLocation,
                  !recorded.fileName.hasSuffix(".feature") else { return issue }
            var issue = issue
            issue.comments.append("Recorded at \(recorded.fileName):\(recorded.line)")
            issue.sourceLocation = location
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
