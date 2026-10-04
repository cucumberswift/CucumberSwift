import CucumberSwift
import Foundation

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle.module }

    public func setupSteps() {
        Given("a defined step") { _, _ in }
        And("a data table with a row that is too long") { _, _ in }
    }
}
