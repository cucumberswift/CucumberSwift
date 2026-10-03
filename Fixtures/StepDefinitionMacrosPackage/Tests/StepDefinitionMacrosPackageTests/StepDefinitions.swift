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

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle.module }

    public func setupSteps() {
        BeforeScenario { _ in
            Basket.shared.cukes = 0
            Basket.shared.colors = []
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

        #ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
            Basket.shared.cukes = cantidad
        }

        #ES_Entonces("la cesta tiene {int} pepinos") { (cantidad: Int) in
            XCTAssertEqual(Basket.shared.cukes, cantidad)
        }
    }
}
