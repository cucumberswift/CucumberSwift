//
//  DSLTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Foundation
import Testing

/// How Swift Testing identifies a case, for comparing two.
private struct EncodedCase: Encodable {
    let testCase: ScenarioCase
    init(_ testCase: ScenarioCase) { self.testCase = testCase }
    func encode(to encoder: any Encoder) throws { try testCase.encodeTestArgument(to: encoder) }
}

/// Features written in the Swift DSL: the cases of the generated "Swift DSL features" test, and how they run.
/// This target has no macros, so the macro form is written as its expansion, `Given(_macroStep:…)`.
extension CucumberTests {
    private func runAll() async throws {
        for testCase in Cucumber.shared.dslCasesToRun() {
            try await Cucumber.shared.run(testCase)
        }
    }

    private func resetNames() {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = nil
    }

    @Test func aFeatureRunsItsScenariosStepsInOrderWithTheBackgroundFirst() async throws {
        resetNames()
        BeforeStep { [self] step in ran.append("before \(step.keywordName) \(step.match)") }
        Feature("Basket") {
            Background {
                Given(_macroStep: self.ran.append("empty"), stepText: "an empty basket", line: 30, column: 18, file: "/Basket.swift")
            }
            Scenario("Add a cuke") {
                When(_macroStep: self.ran.append("add"), stepText: "I: addACuke()", line: 33, column: 17, file: "/Basket.swift")
                And(_macroStep: self.ran.append("again"), stepText: "I: addACuke()", line: 34, column: 17, file: "/Basket.swift")
                Then(_macroStep: { self.ran.append("async") }, stepText: "the: total()", line: 35, column: 17, file: "/Basket.swift")
            }
        }
        try await runAll()
        #expect(ran == [
            "before Given an empty basket", "empty",
            "before When I: addACuke()", "add",
            "before And I: addACuke()", "again",
            "before Then the: total()", "async"
        ])
    }

    @Test func theFunctionFormReadsItsTextFromTheSwiftFile() {
        func printAStatement() {}
        Feature("F") {
            Scenario("S") {
                Given(I: printAStatement())
                When(a:
                    printAStatement())
            }
        }
        let steps = Cucumber.shared.dsl.scenarios.first?.steps
        #expect(steps?.map(\.text) == ["I: printAStatement()", "a:printAStatement()"])
        #expect(steps?.map(\.keyword) == [.given, .when])
        #expect(Cucumber.shared.dsl.scenarios.first?.file == #filePath)
    }

    @Test func theCasesAreNamedAfterTheFeatureTheScenarioAndTheStep() {
        resetNames()
        Feature("Basket", tags: ["basket"]) {
            Scenario("Add") {
                Given(_macroStep: (), stepText: "I: start()", line: 1, column: 1, file: "/B.swift")
                And(_macroStep: (), stepText: "I: add.()", line: 2, column: 1, file: "/B.swift")
            }
            // swiftlint:disable:next multiline_arguments
            ScenarioOutline("Count", headers: Int.self, steps: { _ in
                Then(_macroStep: (), stepText: "I: count()", line: 3, column: 1, file: "/B.swift")
            }, examples: { [1, 2] })
        }
        #expect(Cucumber.shared.dslCasesToRun().map(\.testDescription) == [
            "Basket › Add › 1 › Given I: start()",
            "Basket › Add › 2 › And I: add․()",
            "Basket › Count › 1 › Then I: count()",
            "Basket › Count 2 › 1 › Then I: count()"
        ])
        Cucumber.shared.environment = ["CUCUMBER_READABLE_TEST_NAMES": "NO"]
        #expect(Cucumber.shared.dslCasesToRun().first?.testDescription == "Basket_Add_Step000_GivenIStart")
        Cucumber.shared.environment = ["CUCUMBER_ONE_TEST_PER_SCENARIO": "YES"]
        #expect(Cucumber.shared.dslCasesToRun().map(\.testDescription) == ["Basket › Add", "Basket › Count", "Basket › Count 2"])
        resetNames()
    }

    @Test func anOutlinesExamplesAreCasesOfTheirOwn() throws {
        resetNames()
        Feature("F") {
            // swiftlint:disable:next multiline_arguments
            ScenarioOutline({ "Count \($0)" }, headers: Int.self, steps: { count in
                Then(_macroStep: self.ran.append("\(count)"), stepText: "I: count()", line: 3, column: 1, file: "/B.swift")
            }, examples: { [1, 2] })
        }
        let cases = Cucumber.shared.dslCasesToRun()
        let keys = cases.map(\.scenario).map(Cucumber.key(of:))
        #expect(Set(keys).count == 2)
        let encoded = try cases.map { String(bytes: try JSONEncoder().encode(EncodedCase($0)), encoding: .utf8) }
        #expect(Set(encoded).count == 2)
    }

    @Test func tagsDecideWhichScenariosRun() async throws {
        resetNames()
        Feature("F", tags: ["f"]) {
            Scenario("Kept", tags: ["keep"]) {
                Given(_macroStep: self.ran.append("kept"), stepText: "I: keep()", line: 1, column: 1, file: "/B.swift")
            }
            Scenario("Left out") {
                Given(_macroStep: self.ran.append("left out"), stepText: "I: leaveOut()", line: 2, column: 1, file: "/B.swift")
            }
        }
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "keep"]
        try await runAll()
        #expect(ran == ["kept"])
    }

    @Test func aStepDefinitionThatMatchesTheTextRunsInsteadAndTwoMakeItAmbiguous() async throws {
        resetNames()
        // Not `I: start()`: in a Cucumber expression, `()` is optional text.
        Given("I: start") { [self] _, _ in ran.append("definition") }
        Feature("F") {
            Scenario("S") {
                Given(_macroStep: self.ran.append("dsl"), stepText: "I: start", line: 1, column: 1, file: "/B.swift")
            }
        }
        try await runAll()
        #expect(ran == ["definition"])

        ran = []
        MatchAll("I: start") { [self] _, _ in ran.append("second") }
        try await withKnownIssue {
            try await runAll()
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("Ambiguous step 'Given I: start'") }
        }
        #expect(ran.isEmpty)
    }

    @Test func aStepThatThrowsFailsAndTheScenarioStops() async throws {
        struct Failure: Error {}
        resetNames()
        Feature("F") {
            Scenario("S") {
                Given(_macroStep: { throw Failure() }, stepText: "I: fail()", line: 7, column: 9, file: "/B.swift")
                Then(_macroStep: self.ran.append("then"), stepText: "I: goOn()", line: 8, column: 9, file: "/B.swift")
            }
        }
        try await withKnownIssue {
            try await runAll()
        } matching: { issue in
            // In the step's own file, which here isn't its feature's.
            issue.sourceLocation?.fileName == "B.swift" && issue.sourceLocation?.line == 7 && issue.sourceLocation?.column == 9
        }
        #expect(ran.isEmpty)
    }

    @Test func eachFeatureEndsAfterItsLastScenarioAndRulesAndDescriptionsAreItsOwn() async throws {
        resetNames()
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        var descriptions = [String: String]()
        AfterFeature { feature in descriptions[feature.title] = feature.desc }
        Feature("F") {
            Description("About F")
            Rule("R") {
                Scenario("S") {
                    Given(_macroStep: (), stepText: "I: start()", line: 1, column: 1, file: "/B.swift")
                }
            }
        }
        Feature("G") {
            Scenario("T") {
                Given(_macroStep: (), stepText: "I: start()", line: 2, column: 1, file: "/B.swift")
            }
        }
        Cucumber.shared.beginSuite()
        try await runAll()
        await Cucumber.shared.endSuite()
        #expect(observer.log == [
            "suite started",
            "feature started F", "scenario started S", "step started Given I: start()", "step passed", "scenario passed S", "feature passed F",
            "feature started G", "scenario started T", "step started Given I: start()", "step passed", "scenario passed T", "feature passed G",
            "suite finished"
        ])
        #expect(descriptions == ["F": "About F", "G": ""])
    }

    #if compiler(>=6.2)
    @Test(.reportedInFeatureFiles)
    func aStepMarkedNotToContinueAfterFailureIsCancelledAtItsFirstFailedExpectation() async throws {
        resetNames()
        Feature("F") {
            Scenario("S") {
                Given(_macroStep: {
                          #expect(Bool(false), "deliberately")
                          try await Task.sleep(nanoseconds: 5_000_000_000)
                          self.ran.append("went on")
                      },
                      stepText: "I: fail()",
                      line: 1,
                      column: 1,
                      file: "/B.swift")
                    .continueAfterFailure(false)
            }
        }
        try await withKnownIssue {
            try await runAll()
        } matching: { issue in
            issue.error == nil
        }
        #expect(ran.isEmpty)
    }
    #endif
}
