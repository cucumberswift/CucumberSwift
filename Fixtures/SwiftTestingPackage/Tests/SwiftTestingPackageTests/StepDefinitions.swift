//
//  StepDefinitions.swift
//  SwiftTestingPackageTests
//
//  Step definitions for the Swift Testing runner, in the Swift 6 language mode: macros and the plain
//  DSL, doc strings, data tables, hooks and a localized feature file. If the generated tests stop
//  compiling, or a scenario stops matching its step definitions, this package fails.
//

import CucumberSwiftTestingMacros
import Testing

/// State the steps of one scenario share, reset before each scenario.
@MainActor
enum World {
    static var fruit: String?
    static var cukes = 0
    static var list = [String]()
    static var prices = [String: Int]()
    static var scenarios = [String]()
}

// A consumer in another package writes `@retroactive`, because both Cucumber and StepImplementation
// come from CucumberSwiftTesting.
extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        BeforeScenario { scenario in
            World.fruit = nil
            World.cukes = 0
            World.list = []
            World.prices = [:]
            World.scenarios.append(scenario.title)
        }
        macroSteps()
        dslSteps()
        localizedSteps()
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
        #Then("{int} cukes are left in this step") { [unowned self] (count: Int, step: Step) in
            #expect(self === Cucumber.shared)
            #expect(step.keyword.contains(.then))
            #expect(World.cukes == count)
        }
    }

    /// CucumberSwift's plain DSL, which the macros expand to.
    private func dslSteps() {
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

    /// A localized feature file: its steps match by their text, whatever the keyword's language.
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
            let count = try match.first(\.int)
            #expect(step.keyword.contains(.then))
            #expect(World.cukes == count)
        }
    }
}
