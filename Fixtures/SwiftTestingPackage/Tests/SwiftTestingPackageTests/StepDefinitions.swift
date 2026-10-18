//
//  StepDefinitions.swift
//  SwiftTestingPackageTests
//
//  Step definitions for the Swift Testing runner, in the Swift 6 language mode: macros and the plain
//  DSL, doc strings, data tables, hooks and a localized feature file. If the generated tests stop
//  compiling, or a scenario stops matching its step definitions, this package fails.
//

import CucumberSwiftTestingMacros
import Foundation
import Testing

/// State the steps of one scenario share, reset before each scenario.
@MainActor
enum World {
    static var fruit: String?
    static var cukes = 0
    static var list = [String]()
    static var prices = [String: Int]()
    static var scenarios = [String]()
    /// How many times each feature's hooks have run, by the feature's title, and its scenarios.
    static var featureStarts = [String: Int]()
    static var featureEnds = [String: Int]()
    static var featureScenarios = [String: Int]()
    /// What the hook macros did in the "Hook macros" feature, in the order they ran.
    static var hooks = [String]()

    static func record(_ hook: String, in feature: Feature?) {
        if feature?.title == "Hook macros" { hooks.append(hook) }
    }
}

/// Shared by the `BeforeScenario` hook and the "the world is reset" step definition, as a helper function.
@MainActor
func resetWorld() {
    World.fruit = nil
    World.cukes = 0
    World.list = []
    World.prices = [:]
}

// A consumer in another package writes `@retroactive`, because both Cucumber and StepImplementation
// come from CucumberSwiftTesting.
extension Cucumber: @retroactive StepImplementation {
    // The StepImplementation options, which have defaults: a consumer sets the ones it wants.
    public var asyncStepTimeout: TimeInterval { 30 }
    public var reverseOrderForAfterHooks: Bool { true }
    // Xcode shows the scenario this leaves out as skipped: its step would fail if it ran.
    public func shouldRunWith(scenario _: Scenario?, tags: [String]) -> Bool {
        !tags.contains("left-out-in-code")
    }

    public func setupSteps() {
        BeforeScenario { scenario in
            World.scenarios.append(scenario.title)
            World.featureScenarios[scenario.feature?.title ?? "", default: 0] += 1
            // The helper function the step definition below calls too.
            resetWorld()
        }
        #Given("the world is reset") {
            resetWorld()
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
        macroSteps()
        dslSteps()
        localizedSteps()
        hookSteps()
        hookMacros()
    }

    /// The step definition macros: typed closure parameters, checked against the expression when the
    /// tests compile.
    private func macroSteps() {
        #Given("I have an apple tree") {
        }
        #When("I pick a {string} apple") { (color: String) in
            World.fruit = "\(color) apple"
        }
        #Then("I can enjoy a delicious snack") {
            #expect(World.fruit != nil)
        }
        #Given("I have {int} cukes") { (count: Int) in
            World.cukes = count
        }
        #When("I eat {int} cukes") { (count: Int) in
            World.cukes -= count
        }
        #Then("I have {int} cukes") { (count: Int) in
            #expect(World.cukes == count)
        }
        // Closures with capture lists, which expand differently.
        let bonus = 1
        #When("I get a bonus cuke") { [bonus] in
            World.cukes += bonus
        }
        #When("I eat {int} cukes later") { [weak self] (count: Int) async throws in
            #expect(self != nil)
            await Task.yield()
            World.cukes -= count
        }
        // [unowned self] is one of the capture lists this step checks the macro with.
        // swiftlint:disable:next unowned_variable_capture
        #Then("{int} cukes are left in this step") { [unowned self] (count: Int, step: Step) in
            #expect(self === Cucumber.shared)
            #expect(step.keyword.contains(.then))
            #expect(World.cukes == count)
        }
        // Regex literals: numbered, named and optional captures, the Step, async and a capture list.
        #Given(#/^I have (\d+) cukes from "(?<city>\w+)"$/#) { (count: Substring, city: Substring) in
            #expect(city == "Lisbon")
            World.cukes = Int(count) ?? -1
        }
        #When(#/^I eat (\d+) cukes? with a regex( quickly)?$/#) { (count: Substring, quickly: Substring?) async in
            await Task.yield()
            #expect((quickly == nil) == (World.cukes == 4))
            World.cukes -= Int(count) ?? 0
        }
        #Then(#/^the regex step sees (\d+) cukes$/#) { (count: Substring, step: Step) in
            #expect(step.keyword.contains(.then))
            #expect(World.cukes == Int(count))
        }
        #Then(#/^(\d+) cukes are left in a weak regex step$/#) { [weak self] (count: Substring) async throws in
            #expect(self != nil)
            #expect(World.cukes == Int(count))
        }
    }

    /// CucumberSwift's plain DSL, which the macros expand to.
    private func dslSteps() {
        // Only runs if shouldRunWith fails to leave out its scenario.
        Given("a step that fails if the scenario runs") { _, _ in
            Issue.record("shouldRunWith should have left this scenario out")
        }
        But("I still have {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(World.cukes == count)
        }
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
    }

    /// A localized feature file, and the localized step definition macros, such as `#ES_Dado`: a macro
    /// for each of its keywords, checked as the English ones are. The plain `Given` and the rest match
    /// these steps too, by their text.
    private func localizedSteps() {
        #ES_Dado("tengo {int} pepinos") { (count: Int) in
            World.cukes = count
        }
        #ES_Cuando("como {int} pepinos") { (count: Int) in
            World.cukes -= count
        }
        #ES_Entonces("quedan {int} pepinos") { (count: Int) in
            #expect(World.cukes == count)
        }
        #ES_Y("me quedan {int} pepinos") { (count: Int, step: Step) in
            #expect(step.keyword.contains(.then))
            #expect(World.cukes == count)
        }
    }

    /// Feature hooks run once around a feature's scenarios, and `Attach` records an attachment.
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

    /// The hook macros, each closure form of them, and the steps that check they ran as the hooks do.
    private func hookMacros() {
        #BeforeFeature { feature in
            World.record("before feature", in: feature)
        }
        // Added out of order, they run in order of priority.
        #BeforeScenario(priority: 2) { (scenario: Scenario) in
            World.record("before scenario 2", in: scenario.feature)
        }
        #BeforeScenario(priority: 1) { @MainActor scenario async throws in
            await Task.yield()
            World.record("before scenario 1", in: scenario.feature)
        }
        #BeforeStep { step async in
            await Task.yield()
            World.record("before step", in: step.scenario?.feature)
        }
        #AfterStep {
            World.record("after step", in: $0.scenario?.feature)
        }
        #AfterScenario(priority: 1) { scenario in
            World.record("after scenario", in: scenario.feature)
        }
        // reverseOrderForAfterHooks runs these two in reverse order of priority: this one first.
        #AfterFeature(priority: 2) { feature in
            guard feature.title == "Hook macros" else { return }
            #expect(World.hooks.suffix(2) == ["after step", "after scenario"])
        }
        // A hook without an argument.
        #AfterFeature(priority: 1) {
            World.hooks.removeAll()
        }

        #Given("the before hook macros have run in order of priority") {
            #expect(World.hooks == ["before feature", "before scenario 1", "before scenario 2", "before step"])
        }
        #Then("the step hook macros run before and after each step") {
            #expect(World.hooks.suffix(3) == ["before step", "after step", "before step"])
        }
        #Then("the after hook macros of the first scenario have run") {
            #expect(World.hooks.dropFirst(4) == [
                "after step", "before step", "after step", "after scenario",
                "before scenario 1", "before scenario 2", "before step"
            ])
        }
    }
}
