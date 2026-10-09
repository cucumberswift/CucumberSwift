# Step definition macros in a Swift package

Uses the step definition macros from a Swift package, as "Checking Step Definitions When They
Compile" describes: CucumberSwift with the `Macros` package trait turned on, the
`CucumberSwiftMacros` product, and a test target in the Swift 6 language mode. Its step definitions
use each kind of macro: Cucumber expression parameters, a custom parameter, a regular expression's
capture group, the `Step` argument, an async step, closures with capture lists, a localized
macro (`#ES_Dado`), and regex literals (`#/…/#` and `/…/`) with numbered, named and optional captures.

If a macro's expansion stops compiling, or stops matching its steps, this fixture fails.

It also uses CucumberSwift's other features together, as a project does: the `CucumberSwiftLint`
plugin, plain step definitions next to the macros (`ES_Dado` and regex literals too), a commented-out
step definition, and feature files in English and Spanish with tables, doc strings and Scenario
Outlines. It must build with no warnings from CucumberSwift, and Fix Feature Files must change nothing
in it. Convert to Gherkin Macros must convert its plain step definitions as `expected-conversion`
lists, and its tests must pass on what it converted, with no warnings from CucumberSwift either; its
Swift files are then put back. `mise run test-fixtures` checks all of it. A pull request that adds a
user-facing feature also uses it here.

Needs Swift 6.1 or later. Run it with `swift test --package-path Fixtures/StepDefinitionMacrosPackage`,
or every fixture with `mise run test-fixtures`.
