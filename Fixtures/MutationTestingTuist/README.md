# Mutation testing on an Xcode project

The `Voting` framework is a macOS framework that `VotingTests` tests with CucumberSwift and XCTest. The `Voting` and `Driving` features check a person of 30 and a person of 5 or 10, and nobody of exactly 18 or 16. Mutation testing finds 5 mutants in the framework. It kills 3 and keeps the 2 that change `>=` to `>`.

`mise run test-fixtures` runs the tests like those of any other fixture. Our GitHub Actions CI workflow then runs `.github/scripts/mutation-xcode-fixture.sh` in the Fixture tests job. The script runs mutation testing on a copy of this folder with `xcodebuild`, a scheme and a destination. The `expected-mutants` file lists each mutant the run must find and its status. `.github/scripts/mutation_fixture.py` fails the job when a mutant is missing, has another status or isn't listed.

The copy can't reach CucumberSwift by this fixture's path. The script sets `TUIST_CUCUMBERSWIFT` to a git URL of the checked-out commit, and `Project.swift` depends on that URL when the variable is set.

This fixture needs the Tuist version pinned in `.mise.toml`.
