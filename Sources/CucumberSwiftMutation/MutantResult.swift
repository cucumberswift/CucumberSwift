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

    public init(mutant: Mutant, verdict: Verdict, duration: TimeInterval) {
        self.mutant = mutant
        self.verdict = verdict
        self.duration = duration
    }
}
