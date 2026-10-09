//
//  StepDefinitions.swift
//  StepDefinitionMacrosPackageTests
//
//  Step definitions written with the step definition macros, in the Swift 6 language mode. If a
//  macro's expansion stops compiling or matching, this package stops building or its scenarios fail.
//

import CucumberSwiftMacros
import XCTest

/// Main-actor state, as a test's app driver or view model would be.
@MainActor final class Basket {
    static let shared = Basket()
    var cukes = 0
    var colors = [Color]()
    var note: String?
}

enum Color: String, Sendable {
    case green, red
}

/// A custom parameter, which the macros read as `\.color` on `Match`.
struct ColorParameter: Parameter {
    struct Unknown: Error { }

    static let name = "color"
    let regexMatch = "green|red"

    func convert(input: String) throws -> Color {
        guard let color = Color(rawValue: input) else { throw Unknown() }
        return color
    }
}

extension Match {
    var color: ColorParameter { ColorParameter() }
}

extension CucumberExpression: @retroactive CustomParameters {
    public static var additionalParameters: [AnyParameter] {
        [ColorParameter().eraseToAnyParameter()]
    }
}

extension Cucumber {
    /// What the [weak self] example in "Checking Step Definitions When They Compile" calls.
    @MainActor var basket: Basket { Basket.shared }
}

extension Basket {
    func waitForCount(_ count: Int?) async throws {
        await Task.yield()
        XCTAssertEqual(cukes, count)
    }
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle.module }

    public func setupSteps() {
        BeforeScenario { _ in
            Basket.shared.cukes = 0
            Basket.shared.colors = []
            Basket.shared.note = nil
        }

        #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
            XCTAssertEqual(container, "basket")
            Basket.shared.cukes = count
        }

        #And("a {color} cuke") { (color: Color) in
            Basket.shared.colors.append(color)
        }

        #When("I eat {int} cukes") { (count: Int) in
            Basket.shared.cukes -= count
        }

        #When("I wait for {int} more cukes") { (count: Int) async in
            await Task.yield()
            Basket.shared.cukes += count
        }

        #Then("^the basket holds (\\d+) cukes?$") { (count: String) in
            XCTAssertEqual(Basket.shared.cukes, Int(count))
        }

        #Then("the step says {string}") { (text: String, step: Step) in
            XCTAssert(step.keyword.contains(.and))
            XCTAssertEqual(text, "the basket is called basket")
            XCTAssertEqual(Basket.shared.colors, [.green])
        }

        // Closures with capture lists, which expand differently from the closures above.
        let container = "basket"
        #Given("I have {int} cukes in a captured container") { @MainActor [container] (count: Int) in
            XCTAssertEqual(container, "basket")
            Basket.shared.cukes = count
        }

        // [unowned self] is one of the capture lists this step checks the macro with.
        // swiftlint:disable:next unowned_variable_capture
        #When("I eat {int} cukes without keeping the runner") { [unowned self] (count: Int) throws in
            XCTAssertIdentical(self, Cucumber.shared)
            Basket.shared.cukes -= count
        }

        // The closure of the [weak self] example in "Checking Step Definitions When They Compile", as
        // written there. The pattern differs from the example's, which a step definition above has.
        #Then("^in the end the basket holds (\\d+) cukes?$") { [weak self] (count: String) async throws in
            try await self?.basket.waitForCount(Int(count))
        }

        #When("I wait for {int} more cukes in a captured container") { [container] (count: Int) async in
            XCTAssertEqual(container, "basket")
            await Task.yield()
            Basket.shared.cukes += count
        }

        #When("I wait for {int} more cukes without saying async") { [container] (count: Int) in
            XCTAssertEqual(container, "basket")
            await Task.yield()
            Basket.shared.cukes += count
        }

        #Then("the step after a capture list says {string}") { [weak self] (text: String, step: Step) in
            XCTAssertNotNil(self)
            XCTAssert(step.keyword.contains(.and))
            XCTAssertEqual(text, "the basket is called basket")
        }

        #Then("the basket holds {int} cukes, checked in a nested closure") { (count: Int) in
            let check = { [count] in XCTAssertEqual(Basket.shared.cukes, count) }
            check()
        }

        #ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
            Basket.shared.cukes = cantidad
        }

        #ES_Entonces("la cesta tiene {int} pepinos") { (cantidad: Int) in
            XCTAssertEqual(Basket.shared.cukes, cantidad)
        }

        #ES_Entonces("la nota dice {string}") { (texto: String) in
            XCTAssertEqual(Basket.shared.note, texto)
        }

        // Plain step definitions, next to the macros as a project that is moving to them has them.
        Given("the basket holds these cukes:") { _, step async in
            Basket.shared.cukes += Self.count(in: step)
        }

        Given("a note on the basket:") { _, step async in
            Basket.shared.note = step.docString?.literal
        }

        Then("the note says {string}" as CucumberExpression) { match, _ async in
            XCTAssertEqual(Basket.shared.note, try match.first(\.string))
        }

        ES_Dado("la cesta tiene estos pepinos:") { _, step async in
            Basket.shared.cukes += Self.count(in: step)
        }

        ES_Dado("una nota en la cesta:") { _, step async in
            Basket.shared.note = step.docString?.literal
        }

        // A step definition that is commented out. CucumberSwiftLint ignores it, so it doesn't warn
        // that its regular expression, which has an unclosed group, does not compile.
        // Then(#/^a broken (step$/#) { _, _ in }

        regexLiteralSteps()
    }

    /// The sum of the second column of the step's table, under its header row.
    private static func count(in step: Step) -> Int {
        let rows = step.dataTable?.rows.dropFirst() ?? []
        return rows.reduce(0) { $0 + (Int($1[1]) ?? 0) }
    }

    /// Step definitions with regex literals.
    @MainActor private func regexLiteralSteps() {
        let container = "basket"

        // Regex literals: a numbered and a named capture, an optional one, none, a bare /…/ literal, which the
        // Swift 6 language mode allows, and the Step.
        #Given(#/^the shelf holds (\d+) cukes from "(?<city>[^"]*)"$/#) { (count: Substring, city: Substring) in
            XCTAssertEqual(city, "Lisbon")
            Basket.shared.cukes = Int(count) ?? -1
        }

        #When(#/^I take (\d+) cukes?( slowly)?$/#) { (count: Substring, slowly: Substring?) in
            XCTAssertEqual(slowly == nil, count == "3")
            Basket.shared.cukes -= Int(count) ?? 0
        }

        #When(#/^nothing happens$/#) {
            XCTAssertEqual(Basket.shared.cukes, 0)
        }

        #Then(/^the shelf has (\d+) cukes? left$/) { (count: Substring) in
            XCTAssertEqual(Basket.shared.cukes, Int(count))
        }

        #And(#/^the regex step says "(\w+)"$/#) { (word: Substring, step: Step) in
            XCTAssert(step.keyword.contains(.and))
            XCTAssertEqual(word, "shelf")
        }

        // Regex literals with effects and capture lists.
        #Given(#/^the shelf holds (\d+) cukes from "(?<city>\w+)", counted by a captured clerk$/#) { [container] (count: Substring, city: Substring) throws in
            XCTAssertEqual(container, "basket")
            XCTAssertEqual(city, "Porto")
            Basket.shared.cukes = try XCTUnwrap(Int(count))
        }

        #When(#/^I restock (\d+) cukes asynchronously$/#) { (count: Substring) async throws in
            try await Task.sleep(nanoseconds: 1_000)
            Basket.shared.cukes += Int(count) ?? 0
        }

        #Then(#/^the shelf has (\d+) cukes left, checked by a weak runner$/#) { [weak self] (count: Substring) async throws in
            try await self?.basket.waitForCount(Int(count))
        }

        #ES_Dado(#/^tengo (?<cantidad>\d+) pepinos en la cesta$/#) { (cantidad: Substring) in
            Basket.shared.cukes = Int(cantidad) ?? -1
        }

        // Plain step definitions with regex literals, which `mise run test-fixtures` converts with Convert to
        // Gherkin Macros, a named and an optional capture and a capture list among them, before it runs the
        // tests again.
        Given(#/^the till holds (\d+) coins from (?<city>\w+)( today)?$/#) { match, _ in
            let count = match.1
            let city = match.city
            let today: Substring? = match.output.3
            XCTAssertEqual(city, "Faro")
            XCTAssertNotNil(today)
            Basket.shared.cukes = Int(count) ?? -1
        }

        Then(/^the till has (\d+) coins? left$/) { [container] match, step in
            let count = match.1
            XCTAssertEqual(container, "basket")
            XCTAssertEqual(step.match, "the till has 7 coins left")
            XCTAssertEqual(Basket.shared.cukes, Int(count))
        }
    }
}
