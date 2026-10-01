//
//  GeneratedTestNames.swift
//  CucumberSwift
//
//  The names of the tests CucumberSwift generates for each scenario and step.
//

import Foundation

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

extension String {
    func toClassString() -> String {
        camelCasingString()
            .lazy
            .drop { !$0.isLetter }
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .map(String.init)
            .joined()
            .capitalizingFirstLetter()
    }
}
