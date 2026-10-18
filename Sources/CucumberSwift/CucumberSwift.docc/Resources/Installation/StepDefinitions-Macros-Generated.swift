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
        #Given("I have entered {int} into the calculator") { (int: Int) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When("I press add") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("the result is {int}") { (int: Int) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
    }
}
