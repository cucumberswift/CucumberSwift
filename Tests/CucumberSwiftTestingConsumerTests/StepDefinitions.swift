//
//  StepDefinitions.swift
//  CucumberSwiftTestingConsumerTests
//
//  Runs feature files with the Swift Testing runner under Bazel, as a Bazel project would: the step
//  definitions of the XCTest runner's consumer tests for expressions, a regex literal, doc strings, data
//  tables, hooks, a localized feature file and a feature written in the Swift DSL, with the plain
//  functions, because the Bazel module builds no step definition macros. If the generated tests stop
//  compiling, the feature files stop reaching the test bundle, or a scenario stops matching its step
//  definitions, this suite fails.
//

import CucumberSwiftTesting
import Foundation
import Testing

/// State the steps of one scenario share, reset before each scenario.
@MainActor
enum World {
    static var fruit: String?
    static var cukes = 0
    static var list = [String]()
    static var prices = [String: Int]()
    /// How many times each feature's hooks have run, by the feature's title, and its scenarios.
    static var featureStarts = [String: Int]()
    static var featureEnds = [String: Int]()
    static var featureScenarios = [String: Int]()
}

// A consumer in another module writes `@retroactive`, because both Cucumber and StepImplementation
// come from CucumberSwiftTesting.
extension Cucumber: @retroactive StepImplementation {
    // Xcode shows the scenario this leaves out as skipped: its step would fail if it ran.
    public func shouldRunWith(scenario _: Scenario?, tags: [String]) -> Bool {
        !tags.contains("left-out-in-code")
    }

    public func setupSteps() {
        BeforeScenario { scenario in
            World.featureScenarios[scenario.feature?.title ?? "", default: 0] += 1
            World.fruit = nil
            World.cukes = 0
            World.list = []
            World.prices = [:]
        }
        BeforeFeature { feature in
            World.featureStarts[feature.title, default: 0] += 1
        }
        // Runs once after the feature's last scenario, so that it sees all of them.
        AfterFeature { feature in
            World.featureEnds[feature.title, default: 0] += 1
            #expect(World.featureStarts[feature.title] == 1)
            #expect(World.featureEnds[feature.title] == 1)
            if feature.title == "Feature hooks and attachments" {
                #expect(World.featureScenarios[feature.title] == 3)
            }
        }
        fruitSteps()
        cukeSteps()
        // Regex literals need iOS 16, macOS 13, tvOS 16 and watchOS 9 when the tests run.
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            regexSteps()
        }
        tableSteps()
        hookSteps()
        localizedSteps()
        swiftDSLFeatures()
    }

    private func fruitSteps() {
        Given("I have an apple tree") { _, _ in
        }
        When("I pick a {string} apple") { match, _ in
            World.fruit = "\(try match.first(\.string)) apple"
        }
        Then("I can enjoy a delicious snack") { _, _ in
            #expect(World.fruit != nil)
        }
    }

    private func cukeSteps() {
        Given("the world is reset") { _, _ in
            World.cukes = 0
        }
        Given("I have {int} cukes") { match, _ in
            World.cukes = try match.first(\.int)
        }
        When("I eat {int} cukes") { match, _ in
            World.cukes -= try match.first(\.int)
        }
        Then("I have {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
        But("I still have {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
        // An async step with a capture list.
        When("I get a bonus cuke") { [bonus = 1] _, _ in
            World.cukes += bonus
        }
        When("I eat {int} cukes later") { match, _ in
            await Task.yield()
            World.cukes -= try match.first(\.int)
        }
        Then("{int} cukes are left in this step") { match, step in
            #expect(step.keyword.contains(.then))
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
    }

    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    private func regexSteps() {
        // A regex literal: numbered and named captures, and an optional one.
        Given(#/^I have (\d+) cukes from "(?<city>\w+)"$/#) { match, _ in
            #expect(match.output.city == "Lisbon")
            World.cukes = Int(match.output.1) ?? -1
        }
        When(#/^I eat (\d+) cukes? with a regex( quickly)?$/#) { match, _ in
            #expect((match.output.2 == nil) == (World.cukes == 4))
            World.cukes -= Int(match.output.1) ?? 0
        }
        Then(#/^the regex step sees (\d+) cukes$/#) { match, _ in
            #expect(World.cukes == Int(match.output.1))
        }
        Then(#/^(\d+) cukes are left in a weak regex step$/#) { [weak self] match, _ in
            #expect(self != nil)
            #expect(World.cukes == Int(match.output.1))
        }
    }

    private func tableSteps() {
        // Doc strings and data tables.
        Given("my shopping list is") { _, step in
            World.list = step.docString?.literal.components(separatedBy: "\n") ?? []
        }
        And("these prices") { _, step in
            for row in step.dataTable?.rows.dropFirst() ?? [] {
                World.prices[row[0]] = Int(row[1])
            }
        }
        Then("the list has {int} items and the cukes cost {int}") { match, step in
            #expect(World.list.count == match[\.int, index: 0])
            #expect(World.prices["cukes"] == match[\.int, index: 1])
            #expect(step.scenario?.title == "A shopping list")
        }
        // Only runs if shouldRunWith fails to leave out its scenario.
        Given("a step that fails if the scenario runs") { _, _ in
            Issue.record("shouldRunWith should have left this scenario out")
        }
    }

    /// Feature hooks run once around a feature's scenarios.
    private func hookSteps() {
        Given("the feature's before hook has run once") { _, step in
            #expect(World.featureStarts[step.scenario?.feature?.title ?? ""] == 1)
        }
        And("the feature's after hook has not run") { _, step in
            #expect(World.featureEnds[step.scenario?.feature?.title ?? ""] == nil)
        }
        Then("I attach a note") { _, _ in
            // Attach needs Swift 6.2, the first with attachments in Swift Testing.
            #if compiler(>=6.2)
            Attach(Attachment("a note", named: "note.txt"))
            #endif
        }
    }

    /// A localized feature file: the plain `Given` and the rest match its steps by their text.
    private func localizedSteps() {
        Given("tengo {int} pepinos") { match, _ in
            World.cukes = try match.first(\.int)
        }
        When("como {int} pepinos") { match, _ in
            World.cukes -= try match.first(\.int)
        }
        Then("quedan {int} pepinos") { match, _ in
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
        And("me quedan {int} pepinos") { match, step in
            #expect(step.keyword.contains(.then))
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
    }
}
