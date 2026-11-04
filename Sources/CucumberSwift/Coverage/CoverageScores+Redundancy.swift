//
//  CoverageScores+Redundancy.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// The redundancy score in its two modes: by the code the scenarios run, and, with mutation testing on, by the
/// mutants they detect too.
extension CoverageScores {
    /// What the redundancy score measured: the score, the redundant groups, and each group that overlaps
    /// another, with the group it overlaps.
    struct Redundancy {
        let score: Double
        let redundantGroups: Set<String>
        let overlaps: [String: String]
    }

    /// The redundant groups of `scenarios`, and their share of the groups. A group is a scenario, or a Scenario
    /// Outline's examples together, and its code is what its scenarios ran after their Background steps.
    ///
    /// A group is redundant when the groups kept run all of its code. Every group whose code the other groups don't
    /// all run is kept. The rest, which the other groups cover, are judged from the most code to the least, and in
    /// the order of the feature file between groups with as much code: each is kept unless the groups kept so far
    /// run its code. So of two groups that run the same code, the later one is redundant, and of a group and one
    /// that runs more of the same code, the smaller one is.
    ///
    /// With `detections`, the redundancy is mutation-aware: a group also brings the mutants it detects, and is
    /// redundant only when the groups kept run all its code and detect all its mutants. Groups that detect more are
    /// judged first. A group kept only for the mutants it detects runs code other groups run, so it overlaps the
    /// group that runs most of that code, and both are reported: one should take the best of the two.
    static func redundancy(of scenarios: [Scenario], detections: Detections?) -> Redundancy {
        var order = [String]()
        var groups = [String: Set<Int>]()
        var detected = [String: Set<String>]()
        for scenario in scenarios where !scenario.isTaggedRedundant {
            if groups[scenario.group] == nil { order.append(scenario.group) }
            groups[scenario.group, default: []].formUnion(scenario.countedRegions)
            detected[scenario.group, default: []].formUnion(detections?.kills[scenario.line] ?? [])
        }
        // A group with no code of its own beyond its Background has nothing to judge.
        let judged = order.filter { groups[$0]?.isEmpty == false }
        func code(of others: [String]) -> Set<Int> { others.reduce(into: Set<Int>()) { $0.formUnion(groups[$1] ?? []) } }
        func mutants(of others: [String]) -> Set<String> { others.reduce(into: Set<String>()) { $0.formUnion(detected[$1] ?? []) } }
        let covered = Set(judged.filter { group in
            let others = judged.filter { $0 != group }
            return (groups[group] ?? []).isSubset(of: code(of: others)) && (detected[group] ?? []).isSubset(of: mutants(of: others))
        })
        let place = Dictionary(uniqueKeysWithValues: judged.enumerated().map { ($1, $0) })
        let strongestFirst = judged.filter { covered.contains($0) }.sorted { left, right in
            let leftRank = (detected[left]?.count ?? 0, groups[left]?.count ?? 0, -(place[left] ?? 0))
            let rightRank = (detected[right]?.count ?? 0, groups[right]?.count ?? 0, -(place[right] ?? 0))
            return leftRank > rightRank
        }
        let notCovered = judged.filter { !covered.contains($0) }
        var keptCode = code(of: notCovered)
        var keptMutants = mutants(of: notCovered)
        var redundant = Set<String>()
        for group in strongestFirst {
            let regions = groups[group] ?? []
            let mutantsDetected = detected[group] ?? []
            if regions.isSubset(of: keptCode) && mutantsDetected.isSubset(of: keptMutants) {
                redundant.insert(group)
            } else {
                keptCode.formUnion(regions)
                keptMutants.formUnion(mutantsDetected)
            }
        }
        let overlaps = detections == nil ? [:] : self.overlaps(among: judged.filter { !redundant.contains($0) }, code: groups, detected: detected)
        let flagged = redundant.union(overlaps.keys)
        let score = judged.isEmpty ? 0 : 100 * Double(flagged.count) / Double(judged.count)
        return Redundancy(score: score, redundantGroups: redundant, overlaps: overlaps)
    }

    /// Each of the `kept` groups that is kept only for the mutants it detects, with the group it overlaps: the one
    /// that runs most of its code, and the first of those in the feature file. That group overlaps it too.
    private static func overlaps(among kept: [String], code groups: [String: Set<Int>], detected: [String: Set<String>]) -> [String: String] {
        func code(of others: [String]) -> Set<Int> { others.reduce(into: Set<Int>()) { $0.formUnion(groups[$1] ?? []) } }
        func mutants(of others: [String]) -> Set<String> { others.reduce(into: Set<String>()) { $0.formUnion(detected[$1] ?? []) } }
        var overlaps = [String: String]()
        for group in kept {
            let others = kept.filter { $0 != group }
            let regions = groups[group] ?? []
            // Kept only for the mutants it detects: the others run all its code, but miss one of its mutants.
            guard regions.isSubset(of: code(of: others)), !(detected[group] ?? []).isSubset(of: mutants(of: others)) else { continue }
            let shared = others.map { ($0, regions.intersection(groups[$0] ?? []).count) }
            guard let most = shared.map(\.1).max(), let partner = shared.first(where: { $0.1 == most })?.0 else { continue }
            overlaps[group] = partner
            if overlaps[partner] == nil { overlaps[partner] = group }
        }
        return overlaps
    }

    /// How `group` differs from `partner`: the code each runs after the Background that the other doesn't, and
    /// what the mutants change that each detects and the other doesn't.
    static func overlap(of group: String, with partner: String, in scenarios: [Scenario], detections: Detections?) -> Overlap? {
        let mine = scenarios.filter { $0.group == group && !$0.isTaggedRedundant }
        let theirs = scenarios.filter { $0.group == partner && !$0.isTaggedRedundant }
        guard let line = theirs.first?.line else { return nil }
        let code = { (group: [Scenario]) in group.reduce(into: Set<Int>()) { $0.formUnion($1.countedRegions) } }
        let mutants = { (group: [Scenario]) in group.reduce(into: Set<String>()) { $0.formUnion(detections?.kills[$1.line] ?? []) } }
        let changes = { (ids: Set<String>) in ids.map { detections?.changes[$0] ?? $0 }.sorted() }
        let (codeHere, codeThere) = (code(mine), code(theirs))
        let (detectedHere, detectedThere) = (mutants(mine), mutants(theirs))
        return Overlap(line: line,
                       regionsHere: codeHere.subtracting(codeThere).count,
                       regionsThere: codeThere.subtracting(codeHere).count,
                       detectsHere: changes(detectedHere.subtracting(detectedThere)),
                       detectsThere: changes(detectedThere.subtracting(detectedHere)))
    }
}
