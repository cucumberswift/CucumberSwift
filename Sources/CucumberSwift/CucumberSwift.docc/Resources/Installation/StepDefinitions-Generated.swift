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
        Given(#/^I have entered (\d+) into the calculator$/#) { matches, _ in
            let integer = matches.1
            XCTFail("Step not implemented: replace this line with your test code")
        }
        When(#/^I press add$/#) { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^the result is (\d+)$/#) { matches, _ in
            let integer = matches.1
            XCTFail("Step not implemented: replace this line with your test code")
        }
    }
}
