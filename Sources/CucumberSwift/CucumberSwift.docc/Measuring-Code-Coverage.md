# Measuring code coverage

Write each scenario's code coverage to a file, to see how much of your code each scenario tests.

## Overview

CucumberSwift writes one coverage file per scenario, with a manifest of the scenarios that ran. Turn it on with the `CUCUMBER_COVERAGE` environment variable:

```bash
CUCUMBER_COVERAGE=YES swift test --enable-code-coverage
```

Coverage is off by default. It needs the test target built with code coverage: the **Code Coverage** option of the scheme or test plan in Xcode, or `swift test --enable-code-coverage`. Without it, CucumberSwift writes no coverage files, and the manifest contains a problem that names the cause.

Each file contains the coverage of one scenario only. Xcode's and `swift test`'s own coverage report for the whole run is unchanged.

### Turn it on in code

Set `Cucumber.coverage` to `true` in `setupSteps()`. It wins over the environment variable:

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }

    public func setupSteps() {
        Cucumber.coverage = true
        // Your steps
    }
}
```

### Choose where the files go

CucumberSwift writes the files to `_cucumberCoverage` in the documents folder. On a Simulator, that folder is inside the Simulator. Set `CUCUMBER_COVERAGE_PATH`, or `Cucumber.coveragePath`, to a folder you can collect, such as one under your home folder:

```bash
CUCUMBER_COVERAGE=YES CUCUMBER_COVERAGE_PATH="$HOME/coverage" swift test --enable-code-coverage
```

Each run writes a folder of its own, `run-<id>`, in that folder. The runs of a suite split across several machines can then be collected in one folder without overwriting each other.

## What a run writes

The run's folder has a `.profraw` file for each scenario and each binary built with code coverage, and a `manifest.json`. A file's name starts with the scenario's position in the run and its line, such as `S0003-L12-MyAppTests.profraw`.

The manifest lists the binaries, and each scenario that ran with its feature, name, line, tags and files:

```json
{
  "binaries" : [ { "path" : "/path/to/MyAppTests.xctest/Contents/MacOS/MyAppTests", "uuid" : "…" } ],
  "scenarios" : [
    {
      "feature" : "file:///path/to/MyAppTests.xctest/Contents/Resources/Features/Checkout.feature",
      "featureName" : "Checkout",
      "line" : 12,
      "name" : "Pay with a gift card",
      "profiles" : [ "S0001-L12-MyAppTests.profraw" ],
      "tags" : [ "@payments" ]
    }
  ],
  "version" : 1
}
```

## Read a scenario's coverage

Merge a scenario's file with `llvm-profdata`, then report on the binary with `llvm-cov`. Both come with Xcode:

```bash
xcrun llvm-profdata merge S0001-L12-MyAppTests.profraw -o scenario.profdata
xcrun llvm-cov report /path/to/MyAppTests.xctest/Contents/MacOS/MyAppTests -instr-profile=scenario.profdata
```

Pass several files to `llvm-profdata merge` to see what a feature or a whole run covered.

## Limits

The Swift Testing runner runs scenarios one at a time while coverage is on, even with parallel testing turned on, as <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> describes. Scenarios that run at the same time add to the same coverage counters, because the counters belong to the whole test process. Coverage and parallel testing are mutually exclusive. The XCTest runner is not affected: each of Xcode's parallel workers is a process of its own.

CucumberSwift measures only the binaries built with code coverage. A prebuilt framework, such as a closed-source SDK, isn't measured.

Xcode runs a UI test's code in a test runner process, and the app that the test drives in a separate process. CucumberSwift runs in the test runner process, so its scenario files cover only the code in that process, not the app's. Xcode's coverage report for the whole run includes the app's code only when the app is built with code coverage.

CucumberSwift writes no scenario files while the `LLVM_PROFILE_FILE` environment variable contains `%c`, which turns on the profile runtime's continuous mode. Neither Xcode nor `swift test` adds `%c`. Remove it if you set it yourself.
