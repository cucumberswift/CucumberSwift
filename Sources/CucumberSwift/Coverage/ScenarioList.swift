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
    /// or of the example of an outline, with `%` and `,` in a path written as `%25` and `%2C`. An entry is read exactly as written, spaces and tabs included. CucumberSwift's reports name scenarios the same way.
    static func runs(feature uri: String, line: Int, environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard let list = environment[variable] else { return true }
        let path = MutationReport.feature(ofURI: uri)
        let absolute = uri.hasPrefix("file:") ? (URL(string: uri)?.path ?? uri) : uri
        return list.split(separator: ",").contains {
            let entry = unescaped(String($0))
            return entry == "\(absolute):\(line)" || names(entry: entry, path: path, line: line)
        }
    }

    /// Whether `entry` names the scenario at `line` of the feature at `path`: exactly, or, for a Swift scenario, by its file's
    /// path from the package's folder. A Swift scenario that runs outside the mutation-test tool's copy of the package
    /// reports the absolute path of its file, and `Tests/ShopTests/BasketFeature.swift:12`, the id that the tool's report
    /// names it by, ends that path. An entry that starts with `/` is read exactly, against the file's absolute path as well, so that an entry for a file in
    /// the tool's copy that was written before ids were package-relative still selects it.
    private static func names(entry: String, path: String, line: Int) -> Bool {
        if entry == "\(path):\(line)" { return true }
        guard path.hasPrefix("/"), path.hasSuffix(".swift"), !entry.hasPrefix("/"), let colon = entry.lastIndex(of: ":"),
              Int(entry[entry.index(after: colon)...]) == line else { return false }
        return path.hasSuffix("/" + entry[..<colon])
    }

    /// An entry with `%2C` read as `,` and `%25` as `%`: the mutation-test tool writes them so that a comma in a path
    /// doesn't split the list.
    static func unescaped(_ entry: String) -> String {
        [("%2C", ","), ("%25", "%")].reduce(entry) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }
}
