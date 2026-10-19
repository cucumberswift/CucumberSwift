//
//  ScenarioStateCaseTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Foundation
import Testing

private final class Basket {
    var cukes = 0
}

/// `Scenario.state(_:)` lasts from a scenario's first case to its last, whether each step is a case or not.
extension CucumberTests {
    private func stateScenario() -> GherkinScenario {
        scenario([
            step(.given, "a basket", line: 3),
            step(.then, "it holds a cuke", line: 4)
        ])
    }

    @Test(arguments: [true, false])
    func scenarioStateSetInOneStepIsSeenInTheNext(oneTestPerScenario: Bool) async throws {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = oneTestPerScenario
        defer { Cucumber.oneTestPerScenario = nil }
        Cucumber.shared.environment = [:]
        Given("a basket") { [self] _, _ in
            Scenario.state(Basket.init).cukes += 1
            ran.append("basket")
        }
        Then("it holds a cuke") { [self] _, _ in
            ran.append("cukes: \(Scenario.state(Basket.init).cukes)")
        }
        for testCase in Cucumber.shared.casesToRun(stateScenario()) {
            try await Cucumber.shared.run(testCase)
        }
        #expect(ran == ["basket", "cukes: 1"])
    }

    @Test func scenarioStateIsFreshForTheNextRunOfTheScenario() async throws {
        Cucumber.oneTestPerScenario = false
        defer { Cucumber.oneTestPerScenario = nil }
        Cucumber.shared.environment = [:]
        Given("a basket") { [self] _, _ in
            Scenario.state(Basket.init).cukes += 1
            ran.append("cukes: \(Scenario.state(Basket.init).cukes)")
        }
        Then("it holds a cuke") { _, _ in }
        for _ in 0..<2 {
            for testCase in Cucumber.shared.casesToRun(stateScenario()) {
                try await Cucumber.shared.run(testCase)
            }
        }
        #expect(ran == ["cukes: 1", "cukes: 1"])
    }
}
