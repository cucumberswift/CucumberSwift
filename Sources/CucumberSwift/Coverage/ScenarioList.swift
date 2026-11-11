//
//  ScenarioList.swift
//  CucumberSwift
//
// The scenarios that `CUCUMBER_SCENARIOS` names, for both runners.

import Foundation

/// The scenarios that `CUCUMBER_SCENARIOS` names: run only these. The mutation-test tool sets it, because no build
/// tool can select a scenario that CucumberSwift generates while the tests run.
enum ScenarioList {
    static let variable = "CUCUMBER_SCENARIOS"

    /// Whether the scenario at `line` of the feature file `uri` runs. Every scenario runs without the variable. With it, a
    /// scenario runs only when the variable's comma-separated list holds `Features/Basket.feature:12`: the feature file's
    /// path inside its test bundle, as ``MutationReport/feature(ofURI:)`` reads it, a colon and the line of the scenario,
    /// or of the example of an outline, with `%` and `,` in a path written as `%25` and `%2C`, and a space at its start as `%20`. CucumberSwift's reports name scenarios the same way.
    static func runs(feature uri: String, line: Int, environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard let list = environment[variable] else { return true }
        let id = "\(MutationReport.feature(ofURI: uri)):\(line)"
        return list.split(separator: ",").contains { unescaped($0.trimmingCharacters(in: .whitespaces)) == id }
    }

    /// An entry with `%2C` read as `,`, `%20` as a space and `%25` as `%`: the mutation-test tool writes them so that a
    /// comma in a path doesn't split the list, and a space at its start isn't trimmed off.
    static func unescaped(_ entry: String) -> String {
        [("%2C", ","), ("%20", " "), ("%25", "%")].reduce(entry) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }
}
