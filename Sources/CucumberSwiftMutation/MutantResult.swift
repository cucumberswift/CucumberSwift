//
//  MutantResult.swift
//  CucumberSwiftMutation
//

import Foundation

/// A mutant and what the tests did with it.
public struct MutantResult: Equatable, Sendable {
    public let mutant: Mutant
    public let verdict: Verdict
    public let duration: TimeInterval
    /// The scenarios that ran the mutated code in the unmutated run, when the run measured it.
    public var coveredBy = [ScenarioID]()
    /// The scenarios that failed with the mutant, when the tests wrote a Cucumber JSON report. Empty when the mutant
    /// wasn't killed, or when the tests ended without a report, as when the change crashed them.
    public var killedBy = [ScenarioID]()

    public init(mutant: Mutant,
                verdict: Verdict,
                duration: TimeInterval,
                coveredBy: [ScenarioID] = [],
                killedBy: [ScenarioID] = []) {
        self.mutant = mutant
        self.verdict = verdict
        self.duration = duration
        self.coveredBy = coveredBy
        self.killedBy = killedBy
    }
}
