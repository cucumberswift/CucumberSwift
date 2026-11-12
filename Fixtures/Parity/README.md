# The parity suite

`Fixtures/Parity` runs one set of feature files and their step definitions with each runner, build tool and run mode, and compares every run with one golden result (#561).

The feature files are in `Shared/Features`. The core's step definitions are in `Shared/ParitySteps.swift`, and each feature family puts its own in a Swift file of its own in `Shared`. Each leg compiles every Swift file in `Shared` into an XCTest test target (`ParityXCTests`) and a Swift Testing test target (`ParitySwiftTests`). The Swift Testing targets define the compilation condition `PARITY_SWIFT_TESTING`, which only chooses the import. The code under test is in `Shop`.

The legs are consumer-shaped projects that use CucumberSwift from this checkout by path:

- `SwiftPM` is a Swift package. Its test targets are symbolic links to `Shared`.
- `Xcode` is a Tuist project that uses CucumberSwift as a Swift package. Its test targets compile the files in `Shared`.

Run every combination, or some of them:

```bash
mise run test-parity
PARITY_COMBINATIONS="swiftpm/xctest/serial xcode/swift-testing/parallel" mise run test-parity
```

Each combination is `tool/runner/mode`: `swiftpm` or `xcode`, `xctest` or `swift-testing`, and `serial` or `parallel`. It runs on macOS unless you add a fourth part, `Catalyst`, `iOS`, `tvOS` or `watchOS`. The Xcode project has no watchOS. `.github/scripts/parity-fixture.sh` runs one of them. It writes the test output, the Cucumber JSON report, a trace of the steps and hooks that ran, and the normalized result into a folder, and `.github/scripts/parity.py` compares that result with `golden.json`. The normalized result has no durations, absolute paths or run IDs. See the script's description for what it keeps.

`golden.json` is the result that every combination should give: the intended behaviour. `known-differences.json` lists the combinations that differ, each with its issue and a maintainer's approval. `api.json` lists the scenario that covers each public declaration and setting, and `.github/scripts/parity_coverage.py` fails a change that adds one without a scenario. CONTRIBUTING.md describes how to add a scenario and how a difference is approved.

## Add a feature family

A suite for another feature family adds its cells to this suite and does not build a harness of its own. It adds a feature file to `Shared/Features` and its step definitions as a new Swift file in `Shared`. Both legs compile every Swift file in `Shared` into the XCTest and the Swift Testing target, so neither leg's project changes. It then writes the golden result for the new scenarios with `PARITY_GOLDEN`, and lists each public declaration the scenarios cover in `api.json`.
