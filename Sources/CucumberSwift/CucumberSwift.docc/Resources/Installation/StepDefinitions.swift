import CucumberSwift
import XCTest

// CucumberSwift finds your steps through this extension. It runs setupSteps() once,
// then runs each scenario in the bundle's feature files as a test.
extension Cucumber: @retroactive StepImplementation {
    // The bundle that holds the Features folder: this test bundle.
    public var bundle: Bundle {
        class ThisBundle {}
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        var numbers = [Int]()
        var result = 0

        // setupSteps() runs once, so reset the calculator before each scenario.
        BeforeScenario { _ in
            numbers = []
            result = 0
        }

        // Each pattern is a Cucumber Expression: {int} captures a whole number, and
        // match.first(\.int) reads it back as an Int.
        Given("I have entered {int} into the calculator") { match, _ in
            numbers.append(try match.first(\.int))
        }
        When("I press add") { _, _ in
            result = numbers.reduce(0, +)
        }
        Then("the result is {int}") { match, _ in
            XCTAssertEqual(result, try match.first(\.int))
        }
    }
}
