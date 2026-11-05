# Coverage scores in a Swift package, with each runner

A library, `Grades`, tested by `GradesXCTests` with CucumberSwift and XCTest, and by `GradesSwiftTests` with
Swift Testing. Both run the same `Grading` feature, which has 3 scenarios: 2 that run the same code, so one is
redundant, and 1 that takes another path. `mise run test-fixtures` runs it with `--enable-code-coverage`
(`swift-test-arguments`), and `expected-output` lists the lines that show each runner scored the feature and the
Swift Testing runner printed its warnings.

Our nightly CI run also runs this package with `xcodebuild test -enableCodeCoverage YES` on a tvOS and a
watchOS Simulator, to show that both runners score a feature there (#526).

The test targets set `Cucumber.coverageSources`, because CucumberSwift never measures the files in its own
package folder, and this fixture is inside it. A project that depends on CucumberSwift doesn't need it.

Needs Swift 6.1 or later. Run it with `FIXTURES=CoverageDefaultsPackage mise run test-fixtures`.
