# Mutation testing on a Swift package

The `Voting` library is tested by two test targets with CucumberSwift. `VotingTests` runs the `Voting` and `Driving` features with XCTest, and `VotingSwiftTests` runs the `Retiring` feature with Swift Testing. The features check a person of 30 and a person of 5, 10 or 70, and nobody of exactly 18, 16 or 65. Mutation testing finds 7 mutants in the library. It kills 4 and keeps the 3 that change `>=` to `>`. Only `VotingSwiftTests` calls `canRetire`, so the run kills that function's `<` mutant only when it counts the scenarios of both test targets.

`mise run test-fixtures` runs the tests like those of any other fixture. Our GitHub Actions CI workflow then runs `.github/scripts/mutation-package-fixture.sh` in the Fixture tests job. The script runs `swift run cucumberswift-mutation-test --format xcode` in this folder, as a package's own script would. The `expected-mutants` file lists each mutant the run must find and its status. `.github/scripts/mutation_fixture.py` fails the job when a mutant is missing, has another status or isn't listed, and when the output has no warning for a surviving mutant.

The tool copies the package to a temporary folder, where `../..` doesn't reach CucumberSwift. The script sets `CUCUMBER_SWIFT_PATH` to the checkout's absolute path, and `Package.swift` depends on that path when the variable is set.
