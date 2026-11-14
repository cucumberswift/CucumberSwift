# Coverage scores with the default levels

A macOS framework, `Grades`, tested by `GradesXCTests` with CucumberSwift and XCTest, and by `GradesSwiftTests` with Swift Testing. The scheme turns
**Code Coverage** on for the framework, as a project does in its scheme or test plan, and leaves
CucumberSwift's coverage levels at their defaults.

The `Grading` feature covers less than half of the code it enters. CucumberSwift scores it, and the
`Grading › Coverage scores` suite's `Coverage` test passes, because by default coverage only warns.
`expected-output` lists the lines that show both. If coverage stops scoring, or a low score fails the
test again, this fixture fails. It also lists the feature's coverage warning as each runner prints it,
with the feature file and line (cucumberswift/CucumberSwift#531).

`GradesSwiftTests` runs the same feature with Swift Testing, through `CucumberSwiftTesting`. In Xcode, the
Swift Testing runner used to crash the test process at the first coverage warning, and Xcode still reported
success (cucumberswift/CucumberSwift#509). `expected-output` lists the lines that show the tests ran and
printed the feature's scores, and that the run's total is 2 tests, because the crash made Xcode run the bundle again with 0.

The scheme sets `CUCUMBER_COVERAGE_SOURCES` to the framework's folder. CucumberSwift never measures the
files in its own package folder, and this fixture is inside it. A project that depends on CucumberSwift
doesn't need it.

Needs the Tuist version pinned in `.mise.toml`, and Xcode 26, whose coverage format CucumberSwift reads.
Run every fixture with `mise run test-fixtures`.
