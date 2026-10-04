import CucumberSwiftTesting

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a defined step") { _, _ in }
        And("a data table with a row that is too long") { _, _ in }
    }
}
