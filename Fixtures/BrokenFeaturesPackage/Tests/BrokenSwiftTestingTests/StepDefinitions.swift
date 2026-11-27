import CucumberSwiftTesting
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a defined step") { _, _ in }
        And("a data table with a row that is too long") { _, _ in }
        When("a requirement fails") { _, _ in try #require(1 == 2, "require failed on purpose") }
        Then("the step after a failed assertion never runs") { _, _ in }
    }
}
