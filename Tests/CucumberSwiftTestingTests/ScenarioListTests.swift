//
//  ScenarioListTests.swift
//  CucumberSwiftTestingTests
//
// `CUCUMBER_SCENARIOS`, which the mutation-test tool sets so that a run tests only the scenarios that cover a mutant.

@testable import CucumberSwiftTesting
import Foundation
import Testing

extension CucumberTests {
    @Test func cucumberScenariosRunsOnlyTheScenariosItNames() {
        Cucumber.shared.environment = ["CUCUMBER_SCENARIOS": "/Features/F.feature:5, /Features/G.feature:9"]
        #expect(Cucumber.shared.shouldRun(scenario("Named", line: 5, steps: [])))
        #expect(Cucumber.shared.shouldRun(scenario("In another feature", feature: "G", line: 9, steps: [])))
        #expect(!Cucumber.shared.shouldRun(scenario("Other line", line: 6, steps: [])))
        #expect(!Cucumber.shared.shouldRun(scenario("Other feature", feature: "G", line: 5, steps: [])))
    }

    @Test func everyScenarioRunsWithoutCucumberScenarios() {
        Cucumber.shared.environment = [:]
        #expect(Cucumber.shared.shouldRun(scenario("Any", line: 6, steps: [])))
    }

    @Test func cucumberScenariosNarrowsCucumberTagsAndShouldRunWith() {
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "f", "CUCUMBER_SCENARIOS": "/Features/F.feature:5"]
        #expect(Cucumber.shared.shouldRun(scenario("Named", line: 5, steps: [])))
        #expect(!Cucumber.shared.shouldRun(scenario("Tagged, not named", line: 6, steps: [])))
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "other", "CUCUMBER_SCENARIOS": "/Features/F.feature:5"]
        #expect(!Cucumber.shared.shouldRun(scenario("Named, not tagged", line: 5, steps: [])))
        ImplementationSettings.shouldRunWith = { _, _ in false }
        Cucumber.shared.environment = ["CUCUMBER_SCENARIOS": "/Features/F.feature:5"]
        #expect(!Cucumber.shared.shouldRun(scenario("Named, refused in code", line: 5, steps: [])))
    }

    @Test func aScenarioThatCucumberScenariosLeavesOutRunsNoStepAndTellsNoObserver() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Cucumber.shared.environment = ["CUCUMBER_SCENARIOS": "/Features/F.feature:5"]
        Given("a step") { [self] _, _ in ran.append("given") }

        await Cucumber.shared.run(scenario("Left out", line: 6, steps: [step(.given, "a step", line: 7)]))
        #expect(ran.isEmpty)
        #expect(observer.log.isEmpty)
    }
}
