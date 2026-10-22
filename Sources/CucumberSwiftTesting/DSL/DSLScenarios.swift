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

/// The scenarios of the features written in the Swift DSL, and what their steps run.
struct DSLFeatures {
    static let misplacedStepDefinitionMessage = "A step definition belongs in setupSteps(), outside a feature written in the Swift DSL. "
        + "Inside a scenario, write a DSL step, such as Given(I: doSomething())."

    /// The scenarios, in the order they were declared.
    var scenarios = [GherkinScenario]()
    /// What each step of a scenario runs, by the scenario's `dslID`.
    var steps = [Int: [DSLStep]]()
    /// How many of each feature's scenarios that run have not finished, by ``featureKey(of:)``. The feature ends
    /// when its last one does, whichever that is when scenarios run at the same time.
    var unfinished = [String: Int]()
    /// With parallel testing by feature, the scenario of each feature that runs or ran last, which the next waits
    /// for, so that a feature's scenarios run one at a time while features run at the same time.
    var lastInFeature = [String: Task<Void, Never>]()
    /// Whether the cases run at the same time, as parallel testing has them.
    var runsInParallel = false
    /// Whether the generated "Swift DSL features" test asked for its cases.
    var casesRequested = false
    /// Where each step definition written among a scenario's steps is, which the suite's end reports.
    var misplacedStepDefinitions = [(file: String, line: Int)]()

    static func featureKey(of scenario: GherkinScenario) -> String {
        "\(scenario.file):\(scenario.featureLine):\(scenario.featureTitle)"
    }
}

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
                                          file: feature.sourcePath,
                                          line: scenario.location.line,
                                          column: scenario.location.column,
                                          steps: DSLStep.gherkinSteps(scenario.dslSteps))
            let id = dsl.scenarios.count
            gherkin.dslID = id
            // The file's whole path, so that two files with the same name in different folders are told apart.
            let position = "\(gherkin.file):\(gherkin.line):\(gherkin.column)"
            let examplesBefore = dsl.scenarios.filter { $0.dslIdentity?.hasPrefix(position + "#") ?? false }.count
            gherkin.dslIdentity = "\(position)#\(examplesBefore)"
            dsl.scenarios.append(gherkin)
            dsl.steps[id] = scenario.dslSteps
        }
    }

    /// The cases of the generated "Swift DSL features" test: the cases of each scenario of the Swift DSL that
    /// runs, as ``shouldRun(_:)`` decides, named after its feature and itself, in the order they were declared.
    /// With parallel testing, which `parallelCompiled` says the compilation condition turns on, as for the
    /// generated suite, each scenario is one case, so that scenarios run at the same time, as XCTest runs them,
    /// and a scenario's steps still run in order. `testBundle` is the test bundle the generated test is in, whose
    /// report copy names it, as for the scenarios of feature files.
    public func dslCasesToRun(parallelCompiled: Bool = false, testBundle: URL? = nil) -> [ScenarioCase] {
        loadStepDefinitions()
        if let testBundle {
            dsl.scenarios = dsl.scenarios.map { $0.inTestBundle(testBundle) }
        }
        let readable = CucumberSettings.isReadableTestNames(environment: environment)
        let delimiter = readable ? TestNames.readableDelimiter : "_"
        dsl.casesRequested = true
        dsl.runsInParallel = CucumberSettings.runsInParallel(compiled: parallelCompiled, environment: environment)
        dsl.unfinished = [:]
        var names = Set<String>()
        var cases = [ScenarioCase]()
        for scenario in dsl.scenarios.filter(shouldRun) {
            dsl.unfinished[DSLFeatures.featureKey(of: scenario), default: 0] += 1
            // As CucumberSwift names a test: a number after a name already taken, as an outline's examples are.
            let base = TestNames.name(scenario.featureTitle, readable: readable) + delimiter + TestNames.name(scenario.title, readable: readable)
            var label = base
            var count = 1
            while names.contains(label) {
                count += 1
                label = "\(base) \(count)"
            }
            names.insert(label)
            cases += dsl.runsInParallel ? [ScenarioCase(scenario: scenario, stepIndex: nil, name: label)] : self.cases(of: scenario, label: label)
        }
        return cases
    }

    /// Fails the suite when `setupSteps()` wrote features in the Swift DSL but the generated tests have no "Swift DSL
    /// features" test to run them: CucumberSwiftTestingPlugin adds it when one of the target's Swift files calls
    /// `Feature(…)`, and these were written somewhere else, such as in another module.
    func reportDSLFeaturesNotRun() {
        for site in dsl.misplacedStepDefinitions {
            let name = URL(fileURLWithPath: site.file).lastPathComponent
            Issue.record(Comment(rawValue: DSLFeatures.misplacedStepDefinitionMessage),
                         sourceLocation: SourceLocation(fileID: "DSL/\(name)", filePath: site.file, line: max(site.line, 1), column: 1))
        }
        guard !dsl.scenarios.isEmpty, !dsl.casesRequested else { return }
        Issue.record("""
            setupSteps() wrote features in the Swift DSL, but none of them ran: CucumberSwiftTestingPlugin adds the test \
            that runs them when one of the test target's own Swift files calls Feature(…). Write the features in the \
            test target.
            """)
    }

    /// Runs `body`, a scenario of the Swift DSL, after the scenario of its feature that started before it, with
    /// parallel testing by feature, as CucumberSwift hands a whole feature to one worker. Otherwise it runs it.
    func inFeatureOrder<Result: Sendable>(_ scenario: GherkinScenario, _ body: @escaping @MainActor () async -> Result) async -> Result {
        guard dsl.runsInParallel, CucumberSettings.parallelTestingUnit(environment: environment) == .feature else {
            return await body()
        }
        let key = DSLFeatures.featureKey(of: scenario)
        let previous = dsl.lastInFeature[key]
        let task = Task { @MainActor in
            await previous?.value
            return await body()
        }
        dsl.lastInFeature[key] = Task { _ = await task.value }
        return await task.value
    }
}

extension GherkinScenario {
    /// The scenario, in the test bundle that the generated "Swift DSL features" test is in.
    func inTestBundle(_ testBundle: URL) -> GherkinScenario {
        var scenario = GherkinScenario(featureTitle: featureTitle,
                                       featureTags: featureTags,
                                       featureDescription: featureDescription,
                                       featureLine: featureLine,
                                       title: title,
                                       tags: tags,
                                       file: file,
                                       testBundle: testBundle,
                                       line: line,
                                       column: column,
                                       steps: steps)
        scenario.dslID = dslID
        scenario.dslIdentity = dslIdentity
        return scenario
    }
}
