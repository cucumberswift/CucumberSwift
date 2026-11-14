//
//  MutationScore.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// The mutation score: the share of the mutants that a test or a timeout detected, as Stryker counts it.
/// A mutant that didn't build, one that a comment in the code marks as ignored, and one in code that no scenario
/// runs are left out: the last is a coverage gap, not a test that misses a change.
public struct MutationScore: Equatable, Sendable {
    public let killed: Int
    public let timedOut: Int
    public let survived: Int
    public let unviable: Int
    public let ignored: Int
    public let noCoverage: Int

    public var detected: Int { killed + timedOut }
    public var counted: Int { detected + survived }

    /// 0 to 100, or `nil` when no mutant was counted.
    public var percent: Double? {
        counted == 0 ? nil : Double(detected) * 100 / Double(counted)
    }

    public init(_ results: [MutantResult]) {
        func count(_ matches: (Verdict) -> Bool) -> Int { results.filter { matches($0.verdict) }.count }
        killed = count { if case .killed = $0 { return true } else { return false } }
        timedOut = count { $0 == .timedOut }
        survived = count { $0 == .survived }
        unviable = count { $0 == .unviable }
        ignored = count { if case .ignored = $0 { return true } else { return false } }
        noCoverage = count { $0 == .noCoverage }
    }
}
#endif
