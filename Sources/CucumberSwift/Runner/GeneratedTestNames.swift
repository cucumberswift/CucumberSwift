//
//  GeneratedTestNames.swift
//  CucumberSwift
//
//  The names of the tests CucumberSwift generates for each scenario and step.
//

import Foundation

/// A scenario that will run, with what goes before the name of its class (see `scenarioOrderPrefix`).
struct ScenarioToRun {
    let feature: Feature
    let scenario: Scenario
    let prefix: String
}

extension CucumberTest {
    private static let defaultDelimiter = "|"
    /// With readable test names, a scenario's test reads `Checkout › Pay with a gift card`.
    private static let readableDelimiter = " \u{203A} "

    /// A feature's, scenario's or step's text as it appears in the name of a generated test.
    static func generatedTestName(_ text: String) -> String {
        generatedTestName(text, readable: FeatureFlags.isReadableTestNames)
    }

    static func generatedTestName(_ text: String, readable: Bool) -> String {
        guard readable else { return text.toClassString() }
        return String(text.filter { !$0.isNewline }.map(readableNameCharacter)).trimmingCharacters(in: .whitespaces)
    }

    /// XCTest separates a test's class from its method with "/", and Xcode shows only what follows the
    /// last "." of a class name, as it would for a module, so a readable name can contain neither. A one
    /// dot leader (U+2024) looks like a full stop.
    private static func readableNameCharacter(_ character: Character) -> Character {
        switch character {
            case "/": return "-"
            case ".": return "\u{2024}"
            default: return character
        }
    }

    /// What goes before the name of a scenario's class with parallel testing, so that XCTest, which orders
    /// the classes it lists by name, runs them in the order of the feature files: the feature's position
    /// among all the features, then the scenario's position in its feature, each from 1 and zero-padded to
    /// at least two digits, or to the width of the count when that is wider. `F01 S02 › ` reads well in the
    /// test navigator, and `F01_S02_` is the camel-case form. A `.` would not sort, and Xcode shows only
    /// what follows one, so the prefix has none.
    static func scenarioOrderPrefix(feature: Int, of featureCount: Int, scenario: Int, of scenarioCount: Int, readable: Bool) -> String {
        let featurePosition = String(format: "%0*d", max(2, String(featureCount).count), feature)
        let scenarioPosition = String(format: "%0*d", max(2, String(scenarioCount).count), scenario)
        return readable ? "F\(featurePosition) S\(scenarioPosition)\(readableDelimiter)"
                        : "F\(featurePosition)_S\(scenarioPosition)_"
    }

    /// The prefix of each scenario that will run, in the order `scenarioSuites()` lists them. The positions
    /// count every feature and scenario in the files, before `CUCUMBER_TAGS` or `shouldRunWith` leave any
    /// out, so a scenario keeps its name whichever of them run. Empty without parallel testing: a serial
    /// run builds its suite in the order of the feature files already.
    static func scenariosToRun() -> [ScenarioToRun] {
        let allFeatures = Cucumber.shared.features
        var scenarios = [ScenarioToRun]()
        for feature in allFeatures.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
            for scenario in feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true) {
                var prefix = ""
                if FeatureFlags.isParallelTesting,
                   let featureIndex = allFeatures.firstIndex(where: { $0 === feature }),
                   let scenarioIndex = feature.scenarios.firstIndex(where: { $0 === scenario }) {
                    let readable = FeatureFlags.isReadableTestNames
                    let (featurePosition, scenarioPosition) = (featureIndex + 1, scenarioIndex + 1)
                    prefix = scenarioOrderPrefix(feature: featurePosition,
                                                 of: allFeatures.count,
                                                 scenario: scenarioPosition,
                                                 of: feature.scenarios.count,
                                                 readable: readable)
                }
                scenarios.append(ScenarioToRun(feature: feature, scenario: scenario, prefix: prefix))
            }
        }
        return scenarios
    }

    static func readFeatureScenarioDelimiter() -> String {
        let bundle = (Cucumber.shared as? StepImplementation)?.bundle
        return featureScenarioDelimiter(configured: bundle?.infoDictionary?["FeatureScenarioDelimiter"] as? String,
                                        readable: FeatureFlags.isReadableTestNames)
    }

    /// The Info.plist's `FeatureScenarioDelimiter` when there is one, and otherwise `|`, or ` › ` with
    /// readable test names.
    static func featureScenarioDelimiter(configured: String?, readable: Bool) -> String {
        configured ?? (readable ? readableDelimiter : defaultDelimiter)
    }
}

extension Step {
    /// The name of the test for the step at `index` of a scenario's `count` steps. XCTest may order a
    /// class's tests by name, so the name starts with the step's zero-padded position to keep that
    /// order the same as the feature file's: `Step002_ThenTheTotalIs99`, or with readable test names,
    /// `3 › Then the total is 99`.
    static func methodName(for text: String, at index: Int, of count: Int, readable: Bool) -> String {
        guard readable else {
            let position = String(format: "%0*d", max(3, String(count - 1).count), index)
            return "Step\(position)_" + CucumberTest.generatedTestName(text, readable: false)
        }
        let position = String(format: "%0*d", String(count).count, index + 1)
        return "\(position) \u{203A} " + CucumberTest.generatedTestName(text, readable: true)
    }
}
