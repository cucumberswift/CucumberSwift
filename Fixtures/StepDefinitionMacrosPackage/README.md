# Step definition macros in a Swift package

Uses the step definition macros from a Swift package, as "Checking Step Definitions When They
Compile" describes: CucumberSwift with the `Macros` package trait turned on, the
`CucumberSwiftMacros` product, and a test target in the Swift 6 language mode. Its step definitions
use each kind of macro: Cucumber expression parameters, a custom parameter, a regular expression's
capture group, the `Step` argument, an async step and a localized macro (`#ES_Dado`).

If a macro's expansion stops compiling, or stops matching its steps, this fixture fails.

Needs Swift 6.1 or later. Run it with `swift test --package-path Fixtures/StepDefinitionMacrosPackage`,
or every fixture with `mise run test-fixtures`.
