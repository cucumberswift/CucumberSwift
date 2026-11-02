# Coverage scores with the default levels

A macOS framework, `Grades`, tested by `GradesXCTests` with CucumberSwift and XCTest. The scheme turns
**Code Coverage** on for the framework, as a project does in its scheme or test plan, and leaves
CucumberSwift's coverage levels at their defaults.

The `Grading` feature covers less than half of the code it enters. CucumberSwift scores it, and the
`Grading › Coverage scores` suite's `Coverage` test passes, because by default coverage only warns.
`expected-output` lists the lines that show both. If coverage stops scoring, or a low score fails the
test again, this fixture fails.

This fixture has no Swift Testing target. In an Xcode project with Code Coverage on, the Swift Testing
runner crashes the test process when it reports a coverage warning (cucumberswift/CucumberSwift#509).

The scheme sets `CUCUMBER_COVERAGE_SOURCES` to the framework's folder. CucumberSwift never measures the
files in its own package folder, and this fixture is inside it. A project that depends on CucumberSwift
doesn't need it.

Needs the Tuist version pinned in `.mise.toml`, and Xcode 26, whose coverage format CucumberSwift reads.
Run every fixture with `mise run test-fixtures`.
