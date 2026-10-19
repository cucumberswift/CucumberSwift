//
//  DSLScenarios.swift
//  CucumberSwiftTesting
//
// The scenarios of the features written in the Swift DSL, and the cases of the generated test that runs them.
// The plugin can't see those features when the tests build, since `setupSteps()` declares them when the tests
// run, so they are one parameterized test, "Swift DSL features", whose arguments Swift Testing asks for when it
// builds its test plan, after `setupSteps()`.

import Foundation
import Testing

extension Cucumber {
    /// Hands a feature of the Swift DSL to the runner: each scenario becomes a `GherkinScenario` of the feature,
    /// and its steps' bodies are kept for when it runs.
    func addDSLFeature(_ feature: Feature, scenarios: [Scenario]) {
        for scenario in scenarios {
            var gherkin = GherkinScenario(featureTitle: feature.title,
                                          featureTags: feature.tags,
                                          featureDescription: feature.desc,
                                          featureLine: feature.location.line,
                                          title: scenario.title,
                                          tags: feature.tags + scenario.tags,
                                          file: feature.uri,
                                          line: scenario.location.line,
                                          column: scenario.location.column,
                                          steps: DSLStep.gherkinSteps(scenario.dslSteps))
            let id = dslScenarios.count
            gherkin.dslID = id
            dslScenarios.append(gherkin)
            dslSteps[id] = scenario.dslSteps
        }
    }

    /// The cases of the generated "Swift DSL features" test: the cases of each scenario of the Swift DSL that
    /// runs, as ``shouldRun(_:)`` decides, named after its feature and itself, in the order they were declared.
    /// Each feature ends after the last of its scenarios that runs.
    public func dslCasesToRun() -> [ScenarioCase] {
        loadStepDefinitions()
        let readable = CucumberSettings.isReadableTestNames(environment: environment)
        let delimiter = readable ? TestNames.readableDelimiter : "_"
        let running = dslScenarios.filter(shouldRun)
        var lastOfFeature = [String: String]()
        var names = Set<String>()
        var cases = [ScenarioCase]()
        for scenario in running {
            lastOfFeature["\(scenario.file):\(scenario.featureLine):\(scenario.featureTitle)"] = Self.key(of: scenario)
            // As CucumberSwift names a test: a number after a name already taken, as an outline's examples are.
            let base = TestNames.name(scenario.featureTitle, readable: readable) + delimiter + TestNames.name(scenario.title, readable: readable)
            var label = base
            var count = 1
            while names.contains(label) {
                count += 1
                label = "\(base) \(count)"
            }
            names.insert(label)
            cases += self.cases(of: scenario, label: label)
        }
        lastDSLScenarios = Set(lastOfFeature.values)
        return cases
    }
}
