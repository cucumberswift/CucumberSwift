# Merging coverage runs

A Swift package whose `Calculator` is tested with the same 3 feature files by `CalculatorXCTests` (CucumberSwift
and XCTest) and `CalculatorSwiftTests` (Swift Testing). Each scenario is tagged `@shard1` or `@shard2`.

`.github/scripts/coverage-merge-fixture.sh` (`mise run test-coverage-merge`) runs it with code coverage:

- XCTest one scenario at a time, with Xcode's parallel testing in 3 workers, and in 2 shards, one for each tag.
- Swift Testing one scenario at a time, and in the 2 shards at the same time.

It fails unless `cucumberswift coverage merge` gives every way the same scores, both runners give the same
scores, and the merge prints what each runner printed during its serial run.
