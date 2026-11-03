//
//  Verdict.swift
//  CucumberSwiftMutation
//

import Foundation

/// What happened when the tests ran against one mutant.
public enum Verdict: Equatable, Sendable {
    /// A test failed. `by` names the failed steps (`Scenario :: Given step`) when the run wrote a Cucumber
    /// JSON report, and is empty otherwise.
    case killed(by: [String])
    /// Every test passed: no test noticed the change.
    case survived
    /// The tests ran longer than the timeout, as when the change made a loop endless. Counts as detected.
    case timedOut
    /// The mutated code didn't build, so no test could notice it. Not counted in the score.
    case unviable

    public var name: String {
        switch self {
            case .killed: return "Killed"
            case .survived: return "Survived"
            case .timedOut: return "Timeout"
            case .unviable: return "CompileError"
        }
    }

    public var isDetected: Bool {
        switch self {
            case .killed, .timedOut: return true
            case .survived, .unviable: return false
        }
    }
}
