import CucumberSwiftMacros
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
        #BeforeScenario {
            numbers = []
            result = 0
        }

        // Each pattern is a Cucumber Expression: {int} captures a whole number, and the
        // closure receives it as an Int argument.
        #Given("I have entered {int} into the calculator") { (number: Int) in
            numbers.append(number)
        }
        #When("I press add") {
            result = numbers.reduce(0, +)
        }
        #Then("the result is {int}") { (expected: Int) in
            XCTAssertEqual(result, expected)
        }
    }
}
