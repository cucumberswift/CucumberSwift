//
//  Verdict.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
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
    /// A comment in the code marks the mutant as one no test can notice, such as an equivalent mutant: it isn't
    /// tested and isn't counted. `reason` is the comment's text after the marker.
    case ignored(reason: String)
    /// No scenario ran the mutated code in the unmutated run, so no scenario could detect it: it isn't tested. Code
    /// that no scenario runs is a coverage gap, which the Coverage score reports, so it isn't counted here.
    case noCoverage

    public var name: String {
        switch self {
            case .killed: return "Killed"
            case .survived: return "Survived"
            case .timedOut: return "Timeout"
            case .unviable: return "CompileError"
            case .ignored: return "Ignored"
            case .noCoverage: return "NoCoverage"
        }
    }

    public var isDetected: Bool {
        switch self {
            case .killed, .timedOut: return true
            case .survived, .unviable, .ignored, .noCoverage: return false
        }
    }
}
#endif
