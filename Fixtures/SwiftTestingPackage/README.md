# Swift Testing in a Swift package

Runs feature files with Swift Testing from a Swift package, as "Running Feature Files with Swift
Testing" describes: the `CucumberSwiftTestingPlugin` build tool plugin on a unit test target, and the
`CucumberSwiftTestingMacros` product with CucumberSwift's `Macros` package trait turned on, in the
Swift 6 language mode. The features use a Background, a Scenario Outline with two Examples blocks, a
doc string, a data table, tags and a feature file in Spanish; the step definitions use the macros, the
plain DSL and a hook.

If the generated tests stop compiling, or a scenario stops matching its step definitions, this fixture
fails.

Needs Swift 6.1 or later. Run it with `swift test --package-path Fixtures/SwiftTestingPackage`, or every
fixture with `mise run test-fixtures`.
