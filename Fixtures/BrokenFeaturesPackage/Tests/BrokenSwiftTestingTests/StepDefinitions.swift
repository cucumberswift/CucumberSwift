import CucumberSwiftTesting

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("a defined step") { _, _ in }
        And("a data table with a row that is too long") { _, _ in }
        // A regular expression that doesn't compile, in a variable so that it takes the deprecated function
        // for a regular expression in a String, and another that is a Cucumber expression only by its
        // anchors. Each runner must fail at its line, here.
        let unclosedGroup = "an (unclosed group"
        Given(unclosedGroup) { _, _ in }
        When("^an (unclosed anchored group$") { _, _ in }
    }
}
