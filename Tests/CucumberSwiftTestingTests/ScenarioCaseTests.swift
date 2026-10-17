//
//  ScenarioCaseTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Foundation
import Testing

/// `Cucumber.readableTestNames` and `Cucumber.oneTestPerScenario`: the cases of a scenario's test.
extension CucumberTests {
    private var threeSteps: GherkinScenario {
        scenario([
            gherkinStep(.given, "Given", "Given", "a basket", line: 3),
            gherkinStep([.and, .given], "And", "Given", "a cuke.", line: 4),
            gherkinStep(.then, "Then", "Then", "the total is 99", line: 5)
        ])
    }

    private func gherkinStep(_ keyword: Step.Keyword, _ written: String, _ canonical: String, _ text: String, line: Int) -> GherkinStep {
        GherkinStep(keyword: keyword, keywordName: written, keywordText: canonical, text: text, line: line, column: 5, suggestion: "")
    }

    private func names(environment: [String: String] = [:]) -> [String] {
        Cucumber.shared.environment = environment
        return Cucumber.shared.casesToRun(threeSteps).map(\.testDescription)
    }

    private func resetSettings() {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = nil
    }

    @Test func eachStepIsACaseNamedAsCucumberSwiftNamesItsTest() {
        resetSettings()
        #expect(names() == ["1 › Given a basket", "2 › And a cuke․", "3 › Then the total is 99"])
    }

    @Test func readableTestNamesOffGivesTheCamelCaseNames() {
        resetSettings()
        #expect(names(environment: ["CUCUMBER_READABLE_TEST_NAMES": "NO"]) == ["Step000_GivenABasket", "Step001_GivenACuke", "Step002_ThenTheTotalIs99"])
        Cucumber.readableTestNames = false
        #expect(names() == ["Step000_GivenABasket", "Step001_GivenACuke", "Step002_ThenTheTotalIs99"])
        Cucumber.readableTestNames = true
        #expect(names(environment: ["CUCUMBER_READABLE_TEST_NAMES": "NO"]).first == "1 › Given a basket")
        resetSettings()
    }

    @Test func oneTestPerScenarioIsOneCase() {
        resetSettings()
        #expect(names(environment: ["CUCUMBER_ONE_TEST_PER_SCENARIO": "YES"]) == ["Scenario (line 2)"])
        Cucumber.oneTestPerScenario = true
        #expect(names() == ["Scenario (line 2)"])
        Cucumber.oneTestPerScenario = false
        #expect(names(environment: ["CUCUMBER_ONE_TEST_PER_SCENARIO": "YES"]).count == 3)
        resetSettings()
    }

    @Test func anExampleNamesItsStepCasesAfterItsRow() {
        resetSettings()
        Cucumber.shared.environment = [:]
        let cases = Cucumber.shared.casesToRun([GherkinExample(threeSteps)])
        #expect(cases.map(\.testDescription).first == "Example (line 2) › 1 › Given a basket")
        Cucumber.shared.environment = ["CUCUMBER_ONE_TEST_PER_SCENARIO": "1"]
        #expect(Cucumber.shared.casesToRun([GherkinExample(threeSteps)]).map(\.testDescription) == ["Example (line 2)"])
        resetSettings()
    }

    @Test func theFirstCaseRunsTheBeforeHooksAndTheLastTheAfterHooks() async throws {
        resetSettings()
        BeforeScenario { [self] _ in ran.append("before") }
        AfterScenario { [self] _ in ran.append("after") }
        Given("a basket") { [self] _, _ in ran.append("basket") }
        And("a cuke.") { [self] _, _ in ran.append("cuke") }
        Then("the total is 99") { [self] _, _ in ran.append("total") }
        let cases = Cucumber.shared.casesToRun(threeSteps)
        try await Cucumber.shared.run(cases[0])
        #expect(ran == ["before", "basket"])
        try await Cucumber.shared.run(cases[1])
        try await Cucumber.shared.run(cases[2])
        #expect(ran == ["before", "basket", "cuke", "total", "after"])
    }

    @Test func aCaseRunAloneRunsTheStepsBeforeIt() async throws {
        resetSettings()
        Given("a basket") { [self] _, _ in ran.append("basket") }
        And("a cuke.") { [self] _, _ in ran.append("cuke") }
        Then("the total is 99") { [self] _, _ in ran.append("total") }
        try await Cucumber.shared.run(Cucumber.shared.casesToRun(threeSteps)[2])
        #expect(ran == ["basket", "cuke", "total"])
    }

    @Test func aFailedStepStopsTheLaterCasesAndTheAfterHooksStillRun() async throws {
        resetSettings()
        struct Failure: Error {}
        AfterScenario { [self] _ in ran.append("after") }
        Given("a basket") { _, _ in throw Failure() }
        And("a cuke.") { [self] _, _ in ran.append("cuke") }
        Then("the total is 99") { [self] _, _ in ran.append("total") }
        let cases = Cucumber.shared.casesToRun(threeSteps)
        try await withKnownIssue {
            try await Cucumber.shared.run(cases[0])
        } matching: { $0.sourceLocation?.line == 3 }
        #if compiler(>=6.3)
        // Swift 6.3 reports a skipped step as cancelled, which throws.
        _ = try? await Cucumber.shared.run(cases[1])
        _ = try? await Cucumber.shared.run(cases[2])
        #else
        // Before it a case can't skip itself, so it passes without running its step.
        try await Cucumber.shared.run(cases[1])
        try await Cucumber.shared.run(cases[2])
        #endif
        #expect(ran == ["after"])
    }

    @Test func oneCaseRunsTheWholeScenario() async throws {
        resetSettings()
        Cucumber.shared.environment = ["CUCUMBER_ONE_TEST_PER_SCENARIO": "YES"]
        Given("a basket") { [self] _, _ in ran.append("basket") }
        And("a cuke.") { [self] _, _ in ran.append("cuke") }
        Then("the total is 99") { [self] _, _ in ran.append("total") }
        try await Cucumber.shared.run(Cucumber.shared.casesToRun(threeSteps)[0])
        #expect(ran == ["basket", "cuke", "total"])
    }
}
