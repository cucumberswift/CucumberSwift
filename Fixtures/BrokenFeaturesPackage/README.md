# Broken feature files

Feature files with mistakes in them on purpose, run by both runners with the plugins on, to prove that
CucumberSwift reports each problem: `BrokenXCTestTests` runs them with CucumberSwift and XCTest, and
`BrokenSwiftTestingTests` with Swift Testing, through `CucumberSwiftTestingPlugin`. Both apply
`CucumberSwiftLint`.

Each target has the same two files:

- `Broken.feature`: a misspelt keyword, a step that no step definition matches, and a data table row
  with a cell too many. `CucumberSwiftLint` warns about each, and each runner fails the undefined step.
- `Unsupported.feature`: a `# language:` that Gherkin doesn't have. Each runner fails it as a Gherkin
  error. (`CucumberSwiftLint` only checks English feature files.)

`BrokenSwiftTestingTests` also has `Assertions.feature`: a step whose `try #require` fails. The runner must
fail that step with one issue.

Its tests are meant to fail. `mise run test-fixtures` requires them to, and requires every warning in
`expected-warnings` and every failure in `expected-failures` to appear in the output, and no line of
`unexpected-output`: "An API was misused" there means the runner recorded the failed requirement twice.
Don't fix the feature files: change the expectations when CucumberSwift's messages change.

Needs Swift 6.1 or later. CI's "SwiftPM tests" job doesn't run it; the Fixtures job does, through
`mise run test-fixtures`.
