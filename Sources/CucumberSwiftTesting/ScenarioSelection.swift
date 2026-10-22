//
//  ScenarioSelection.swift
//  CucumberSwiftTesting
//
// Which scenarios and examples run, and the step definitions the runner suggests and the hook failures it
// reports, and the messages for steps it can't match: parts of the runner that CucumberSwift's options
// (`shouldRunWith`, `generateRegexLiterals`) decide.

import Foundation
import Testing

extension Cucumber {
    /// CucumberSwift's message for a step that no step definition matches.
    static func missingStepDefinitionMessage(suggestion: String) -> String {
        "No CucumberSwift expression found that matches this step. Try adding the following Swift code to your step implementation file: \n\(suggestion)"
    }

    /// CucumberSwift's message for a step that more than one step definition matches.
    static func ambiguousStepMessage(step: String, definitions: [Definition]) -> String {
        let locations = definitions.map { "\(URL(fileURLWithPath: $0.file).lastPathComponent):\($0.line)" }
        let list = locations.count < 2 ? locations.joined() : locations.dropLast().joined(separator: ", ") + " and " + (locations.last ?? "")
        return "Ambiguous step '\(step)': it matches \(locations.count) step definitions, at \(list). Remove all but one of them, or make their patterns more specific." // swiftlint:disable:this line_length
    }

    static func key(of scenario: GherkinScenario) -> String {
        // The examples of a `ScenarioOutline` in the Swift DSL share a line, so its scenarios add their `dslID`.
        "\(scenario.file):\(scenario.line):\(scenario.column)" + (scenario.dslID.map { "#\($0)" } ?? "")
    }

    /// Whether the scenario runs: `CUCUMBER_TAGS` decides when it is set, and otherwise
    /// `shouldRunWith(scenario:tags:)` does, as in CucumberSwift. The tests that CucumberSwiftTestingPlugin
    /// generates for scenarios ask this in an `.enabled` trait, so that a scenario it leaves out is
    /// reported as skipped, and the scenario is not asked again when it runs. It sets up the step
    /// definitions first, because Swift Testing asks before any test has started. A scenario that is left
    /// out starts no feature and tells no observer, as CucumberSwift doesn't generate it.
    public func shouldRun(_ gherkinScenario: GherkinScenario) -> Bool {
        loadStepDefinitions()
        let runs: Bool
        if environment["CUCUMBER_TAGS"] != nil {
            runs = CucumberTags.shouldRun(gherkinScenario.tags, environment: environment)
        } else if let implementation = self as Any as? StepImplementation {
            runs = implementation.shouldRunWith(scenario: Scenario(gherkinScenario, feature: feature(of: gherkinScenario)), tags: gherkinScenario.tags)
        } else {
            runs = true
        }
        if runs { approvedScenarios.insert(Cucumber.key(of: gherkinScenario)) }
        return runs
    }

    /// The examples of a Scenario Outline that run, as ``shouldRun(_:)`` decides for each. The test that
    /// CucumberSwiftTestingPlugin generates for an outline takes them as its arguments, so one that is left out
    /// is not a test case at all, as with CucumberSwift, which doesn't generate it.
    public func examplesToRun(_ examples: [GherkinExample]) -> [GherkinExample] {
        examples.filter { shouldRun($0.scenario) }
    }

    /// The step definition to suggest for an undefined step: with a regex literal when
    /// ``Cucumber/generateRegexLiterals`` or `CUCUMBER_GENERATE_REGEX_LITERALS` asks for one, written as
    /// ``StepImplementation/regexLiteralStyle`` says, and otherwise with a Cucumber Expression. A step
    /// definition macro when the test target links the macros, or ``Cucumber/generateMacros`` or
    /// `CUCUMBER_GENERATE_MACROS` asks for one, and the generated code has it.
    func suggestion(for step: Step) -> String {
        let macro = CucumberSettings.generatesMacros(environment: environment)
        guard CucumberSettings.generatesRegexLiterals(environment: environment) else {
            return (macro ? step.macroSuggestion : nil) ?? step.suggestion
        }
        let bareSlash = (self as Any as? StepImplementation)?.regexLiteralStyle == .bareSlash
        let macroSuggestion = bareSlash ? step.bareSlashRegexLiteralMacroSuggestion : step.regexLiteralMacroSuggestion
        let functionSuggestion = bareSlash ? step.bareSlashRegexLiteralSuggestion : step.regexLiteralSuggestion
        return (macro ? macroSuggestion : nil) ?? functionSuggestion ?? step.suggestion
    }

    /// Tells the observers that a step failed without running, because a hook before it did.
    func reportFailed(_ step: Step, _ message: String) {
        let startDate = Date()
        reporters.forEach { $0.didStart(step: step, at: startDate) }
        reporters.forEach { $0.didFinish(step: step, result: .failed(message), duration: Measurement(value: 0, unit: UnitDuration.seconds)) }
    }
}
