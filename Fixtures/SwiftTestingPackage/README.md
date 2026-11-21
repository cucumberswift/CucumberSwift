# Swift Testing in a Swift package

Runs feature files with Swift Testing from a Swift package, as "Running Feature Files with Swift
Testing" describes: the `CucumberSwiftTestingPlugin` build tool plugin on a unit test target, and the
`CucumberSwiftTestingMacros` product with CucumberSwift's `Macros` package trait turned on, in the
Swift 6 language mode. The features use a Background, a Scenario Outline with two Examples blocks, a
Rule with its own Background, a Scenario Outline and tags, a doc string, a data table, other tags and a feature
file in Spanish; the step definitions use the macros, with
expressions and regex literals, the plain DSL, the localized macros such as `#ES_Dado`, hooks, and the hook macros, such as `#BeforeScenario`, in each
closure form and with priorities. A feature written in the Swift DSL, with the DSL step macros such as
`#Given(I: openTheShop())`, runs as the generated "Swift DSL features" test.

A second test target, `SwiftTestingPackageXCTests`, runs its feature file with CucumberSwift's XCTest
runner in the same `swift test` run. Both targets write one Cucumber JSON report: `mise run test-fixtures`
checks that it has the features `expected-report` lists, and that a second `swift test` run of the
`checkout` tag, which only the XCTest target's feature has, replaces it, as `expected-report-rerun` lists.
The task first writes a report with a feature of an earlier run, which the run must replace, and the XCTest
target, which runs first, sets the report's age to 2 hours as it exits. So the Swift Testing process starts
when the report is stale, and still keeps what the XCTest process wrote.

This fixture fails if the generated tests stop compiling, or if a scenario stops matching its step
definitions.

Needs Swift 6.1 or later. Run it with `swift test --package-path Fixtures/SwiftTestingPackage`, or every
fixture with `mise run test-fixtures`.
