//
//  CoverageManifest.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, and with
//  cucumberswift coverage merge through a symlink of this file, so it uses neither runner's types.
//

import Foundation

/// The `manifest.json` that each run writes in its folder: the binaries, the scenarios that ran and their
/// files, the scores of the features that finished, and what `cucumberswift coverage merge` needs to score the
/// scenarios of several runs as one run.
struct CoverageManifest: Codable, Equatable {
    /// A binary built with code coverage. A report needs it, with the profiles, to map the counters back to
    /// source lines, and its UUID identifies the build that ran.
    struct Binary: Codable, Equatable {
        var path: String
        var uuid: String?
    }

    /// A scenario that ran, and its profile files, one for each binary, in the run's folder.
    struct ScenarioRecord: Codable, Equatable {
        /// The feature file's URI, as the JSON report gives it.
        var feature: String
        var featureName: String
        var line: Int
        var name: String
        var tags: [String]
        var profiles: [String]
        /// How long the scenario took, in seconds.
        var duration: Double?
        /// The line of the scenario's `Feature:`.
        var featureLine: Int?
        /// The feature file that the runner reports the feature's coverage issues on.
        var issueFile: String?
        /// The code the scenario ran, which the scores need. Nil when the run measures no code.
        var coverage: ScenarioCoverage?
    }

    /// The code a scenario ran, as numbers of the regions of ``CoverageManifest/measured``.
    struct ScenarioCoverage: Codable, Equatable {
        /// The regions one of the scenario's steps after its Background ran.
        struct Step: Codable, Equatable {
            var line: Int
            var regions: [Int]
        }

        var regions: [Int]
        /// The regions the scenario ran during its Background steps.
        var backgroundRegions: [Int]
        var steps: [Step]
        /// The scenario's ``CoverageScores/Scenario/group``.
        var group: String
        /// The title of the Rule the scenario is in.
        var rule: String?
        /// The line of the Rule the scenario is in.
        var ruleLine: Int?
    }

    /// A function the scores measure. The run numbers the regions of ``CoverageManifest/measured`` one after
    /// the other, in its order.
    struct MeasuredFunction: Codable, Equatable {
        /// The file name of the binary that holds the function.
        var binary: String
        /// The function's name as the binary's coverage map gives it, which is a mangled name for Swift.
        var name: String
        /// The function's name as the scores show it.
        var readableName: String
        var file: String
        var line: Int
        /// How many regions the function has.
        var regions: Int
        /// Where each region is, in region order: its first line, first column, last line and last column, with
        /// columns counted in UTF-8 bytes from 1. Nil in a manifest from before the spans were recorded.
        var spans: [[Int]]?
    }

    /// The levels a run checks its scores against, and the code it measures, from ``CoverageSettings``. A level is
    /// a percentage, or nil for off.
    struct Settings: Codable, Equatable {
        var warningLevel: Int?
        var errorLevel: Int?
        var redundancy: Bool
        var redundancyWarningLevel: Int?
        var redundancyErrorLevel: Int?
        var redundantStepWarningLevel: Int?
        /// The sources filter that picks the code the scores measure, sorted. Nil in a manifest from before it was
        /// recorded, and empty when the run measures all the code.
        var sources: [String]?
    }

    /// The scores of a feature that finished: of its scenarios that aren't in a Rule, or of one of its
    /// Rules, which has scores of its own.
    struct FeatureRecord: Codable, Equatable {
        var feature: String
        var featureName: String
        var line: Int
        /// The title of the Rule these scores are for, or `nil` for the feature's scenarios outside a Rule.
        var rule: String?
        /// The line of the Rule these scores are for.
        var ruleLine: Int?
        var scores: CoverageScores
    }

    /// Changes when the manifest's form changes, so that a reader can refuse one it doesn't know.
    static let currentVersion = 1

    var version = CoverageManifest.currentVersion
    var run: String
    var startDate: Date
    var binaries: [Binary]
    var scenarios: [ScenarioRecord]
    /// Each feature's scores, in the order the features finished.
    var features = [FeatureRecord]()
    /// Why no profile was written, when the run couldn't write any.
    var problem: String?
    /// Why the run has no scores, when it has profiles but couldn't read a coverage map, or doesn't score.
    var scoresProblem: String?
    /// The functions the scores measure. Nil when the run measures no code.
    var measured: [MeasuredFunction]?
    /// The levels the run checks its scores against.
    var settings: Settings?
}

extension CoverageManifest.Settings {
    /// The settings these levels are from.
    var coverageSettings: CoverageSettings {
        func level(_ percent: Int?) -> CoverageLevel { percent.map(CoverageLevel.percent) ?? .off }
        var settings = CoverageSettings()
        settings.warningLevel = level(warningLevel)
        settings.errorLevel = level(errorLevel)
        settings.isRedundancy = redundancy
        settings.redundancyWarningLevel = level(redundancyWarningLevel)
        settings.redundancyErrorLevel = level(redundancyErrorLevel)
        settings.redundantStepWarningLevel = level(redundantStepWarningLevel)
        return settings
    }

    init(_ settings: CoverageSettings) {
        func percent(_ level: CoverageLevel) -> Int? {
            guard case .percent(let value) = level else { return nil }
            return value
        }
        self.init(warningLevel: percent(settings.warningLevel),
                  errorLevel: percent(settings.errorLevel),
                  redundancy: settings.isRedundancy,
                  redundancyWarningLevel: percent(settings.redundancyWarningLevel),
                  redundancyErrorLevel: percent(settings.redundancyErrorLevel),
                  redundantStepWarningLevel: percent(settings.redundantStepWarningLevel),
                  sources: settings.sources.sorted())
    }
}
