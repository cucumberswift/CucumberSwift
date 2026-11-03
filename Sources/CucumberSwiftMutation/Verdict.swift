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

/// A mutant and what the tests did with it.
public struct MutantResult: Equatable, Sendable {
    public let mutant: Mutant
    public let verdict: Verdict
    public let duration: TimeInterval

    public init(mutant: Mutant, verdict: Verdict, duration: TimeInterval) {
        self.mutant = mutant
        self.verdict = verdict
        self.duration = duration
    }
}

/// The mutation score: the share of the mutants that a test or a timeout detected, as Stryker counts it.
/// A mutant that didn't build is left out.
public struct MutationScore: Equatable, Sendable {
    public let killed: Int
    public let timedOut: Int
    public let survived: Int
    public let unviable: Int

    public init(_ results: [MutantResult]) {
        func count(_ matches: (Verdict) -> Bool) -> Int { results.filter { matches($0.verdict) }.count }
        killed = count { if case .killed = $0 { return true } else { return false } }
        timedOut = count { $0 == .timedOut }
        survived = count { $0 == .survived }
        unviable = count { $0 == .unviable }
    }

    public var detected: Int { killed + timedOut }
    public var counted: Int { detected + survived }

    /// 0 to 100, or `nil` when no mutant was counted.
    public var percent: Double? {
        counted == 0 ? nil : Double(detected) * 100 / Double(counted)
    }
}
