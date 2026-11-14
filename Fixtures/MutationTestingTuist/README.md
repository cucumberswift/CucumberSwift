# Mutation testing on an Xcode project

The `Voting` framework is a macOS framework that two test targets test with CucumberSwift. `VotingTests` runs the `Voting` feature with XCTest, and `VotingSwiftTests` runs the `Retiring` feature with Swift Testing. The features check a person of 30 and a person of 5 or 70, and nobody of exactly 18 or 65. Mutation testing finds 4 mutants in the framework. It kills 2 and keeps the 2 that change `>=` to `>`. Only `VotingSwiftTests` calls `canRetire`, so the run kills that function's `<` mutant only when it also counts the Swift Testing target's tests.

`mise run test-fixtures` runs the tests like those of any other fixture. Our GitHub Actions CI workflow then runs `.github/scripts/mutation-xcode-fixture.sh` in the Fixture tests job, in the merge queue and on nightly and manual runs, and on a pull request that changes mutation testing. The script builds a copy of this folder's project, which runs the mutation testing command from a Run Script build phase of its `Mutation` target with `xcodebuild`, a scheme and a destination. The `expected-mutants` file lists each mutant the run must find and its status. `.github/scripts/mutation_fixture.py` fails the job when a mutant is missing, has another status or isn't listed, and when the build log has no warning for a surviving mutant. The script also checks that the run's report names the scenarios of both runners.

The nightly and manual runs also give `.github/scripts/mutation-xcode-fixture.sh` a second argument, `selection`, which runs `XcodebuildRunnerFixtureTests` on the project. Those tests run one XCTest scenario and one Swift Testing scenario through `xcodebuild`.

The copy can't reach CucumberSwift by this fixture's path. The script sets `TUIST_CUCUMBERSWIFT` to a git URL of the checked-out commit, and `Project.swift` depends on that URL when the variable is set.

This fixture needs the Tuist version pinned in `.mise.toml`.
