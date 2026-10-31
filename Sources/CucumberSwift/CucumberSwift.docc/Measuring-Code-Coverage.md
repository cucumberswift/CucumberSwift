# Measuring code coverage

Score each feature's scenarios on how much of your code they test, and how much of it they test more than once.

## Overview

CucumberSwift measures the code that each scenario runs, and scores each feature when its last scenario finishes. Turn it on with the `CUCUMBER_COVERAGE` environment variable:

```bash
CUCUMBER_COVERAGE=YES swift test --enable-code-coverage
```

Coverage is off by default. It needs the test target built with code coverage: the **Code Coverage** option of the scheme or test plan in Xcode, or `swift test --enable-code-coverage`. Without it, CucumberSwift prints the cause at the end of the run and scores nothing.

CucumberSwift prints each feature's scores when the feature finishes:

```
CucumberSwift coverage: Arithmetic: 71% of the code its scenarios ran (15 of 21 regions in 6 functions), 58% of all measured code
    Share  Own regions      Time  Scenario
      12%            2     0.10s  Adding two numbers (line 4)
      12%            2     0.02s  Subtracting a larger number (line 9)
      29%            6     0.01s  Dividing by zero (line 14)
      19%            4     0.02s  Classifying a small number (line 19)
```

A feature whose coverage is at or below 80% gets a warning on its `Feature:` line, and one at or below 50% gets an error. Xcode shows them in the feature file, with the functions whose code no scenario ran:

```
Feature coverage 71%: its scenarios ran 15 of the 21 regions in the 6 functions they entered (error at or below 50%, warning at or below 80%). Not run: Calculator.classify(Int), 5 regions, entered by the scenario at line 19; Calculator.divide(_: Int, by: Int), 1 region, entered by the scenario at line 14.
```

Xcode's and `swift test`'s own coverage report for the whole run is unchanged.

### Find the issues in your tests

The XCTest runner records a feature's issues in tests of its own, which run after the feature's scenarios. Their suite is named after the feature, such as `Checkout › Coverage scores`, and has 3 tests:

- `Coverage`, for the coverage warning or error.
- `Redundancy`, for the redundancy warning or error.
- `Redundant scenarios`, for the warnings on the scenarios that add no coverage of their own.

An error fails its test, and the scenarios pass or fail on their own steps. With parallel testing, a feature's scenarios can run in different workers, so its issues are recorded in the test that is running when the feature ends. The Swift Testing runner records them on the feature's suite.

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

## Read a feature's scores

A feature's coverage is measured by how much of the code under test that its scenarios executed, as a percentage of the code in the covered functions. A scenario that calls `classify(_:)` with one number runs one of its cases, so the feature's coverage drops until another scenario runs the other cases, or this one does. Code in a function that no scenario entered doesn't lower the feature's coverage. The summary's second percentage counts all the code instead.

CucumberSwift counts code in regions, as Xcode's coverage report does. A region is a stretch of code that always runs as a whole, such as the body of an `if`.

Each scenario's share is its part of the feature's coverage, and the shares add up to it. A region that one scenario ran counts in full for that scenario. A region that several scenarios ran is split evenly between them. **Own regions** is the number of regions that no other scenario ran, and **Time** is how long the scenario took. A scenario with a large share and a short time tests a lot for its cost. A scenario with no own regions runs only code that other scenarios run too.

The coverage message names up to 3 functions with code that no scenario ran, the most first, and the lines of the scenarios that entered each one. To raise the coverage, extend one of those scenarios or add a scenario that takes the other path.

### Score each Rule on its own

CucumberSwift scores the scenarios in each `Rule:` apart from the rest of the feature, and reports the Rule's scores on its `Rule:` line:

```gherkin
Feature: Arithmetic
  Scenario: Adding two numbers
    Given a calculator
    When I add 2 and 3
    Then the display shows "5"

  Rule: Numbers have names
    Scenario: Naming seven
      Given a calculator
      When I classify 7
      Then the display shows "small"
```

The feature's scores here count only "Adding two numbers", and the Rule's only "Naming seven". A feature with Rules can then have a coverage warning on one Rule and a coverage error on another. The summary names the Rule after its feature, such as `Arithmetic › Numbers have names`.

## Set the levels

Set each level to a percentage, or to `.off` for no warning or no error. A feature gets a coverage warning or error when its coverage, rounded to a whole percentage, is at or below the level, and a redundancy warning or error when its redundancy is at or above the level. Each setting has an environment variable too, which takes a number from 0 to 100, or `NO`. The comments in these examples give each setting's environment variable and default.

### Use the defaults

The defaults balance feedback and failures. A warning at 80% coverage points to the features that leave code untested, and an error at 50% fails only the features whose scenarios miss most of the code they enter. The redundancy score warns at 30% and doesn't fail, because a feature can repeat code on purpose, such as to test boundary values. These lines set every level to its default, so `Cucumber.coverage = true` alone does the same:

```swift
public func setupSteps() {
    Cucumber.coverage = true                // CUCUMBER_COVERAGE, default off
    Cucumber.coverageWarningLevel = 80      // CUCUMBER_COVERAGE_WARNING_LEVEL, default 80
    Cucumber.coverageErrorLevel = 50        // CUCUMBER_COVERAGE_ERROR_LEVEL, default 50
    Cucumber.redundancy = true              // CUCUMBER_REDUNDANCY, default on
    Cucumber.redundancyWarningLevel = 30    // CUCUMBER_REDUNDANCY_WARNING_LEVEL, default 30
    Cucumber.redundancyErrorLevel = .off    // CUCUMBER_REDUNDANCY_ERROR_LEVEL, default off
    // Your steps
}
```

### Warn without failing

Turn the error levels off to see both scores as warnings without failing a test, such as while you add scenarios to an existing suite:

```swift
public func setupSteps() {
    Cucumber.coverage = true                // CUCUMBER_COVERAGE, default off
    Cucumber.coverageWarningLevel = 80      // CUCUMBER_COVERAGE_WARNING_LEVEL, default 80
    Cucumber.coverageErrorLevel = .off      // CUCUMBER_COVERAGE_ERROR_LEVEL, default 50
    Cucumber.redundancy = true              // CUCUMBER_REDUNDANCY, default on
    Cucumber.redundancyWarningLevel = 30    // CUCUMBER_REDUNDANCY_WARNING_LEVEL, default 30
    Cucumber.redundancyErrorLevel = .off    // CUCUMBER_REDUNDANCY_ERROR_LEVEL, default off
    // Your steps
}
```

### Allow no redundancy

Set the redundancy's error level to 1% to fail every feature with a scenario that runs code another scenario runs, and raise the coverage levels with it. This strict mode suits a suite whose scenarios are slow, where each one must test code that no other one tests:

```swift
public func setupSteps() {
    Cucumber.coverage = true                // CUCUMBER_COVERAGE, default off
    Cucumber.coverageWarningLevel = 90      // CUCUMBER_COVERAGE_WARNING_LEVEL, default 80
    Cucumber.coverageErrorLevel = 80        // CUCUMBER_COVERAGE_ERROR_LEVEL, default 50
    Cucumber.redundancy = true              // CUCUMBER_REDUNDANCY, default on
    Cucumber.redundancyWarningLevel = 30    // CUCUMBER_REDUNDANCY_WARNING_LEVEL, default 30
    Cucumber.redundancyErrorLevel = 1       // CUCUMBER_REDUNDANCY_ERROR_LEVEL, default off
    // Your steps
}
```

The warning level stays on in strict mode, because it also puts a warning on each scenario that adds no coverage of its own, which shows what to merge or remove. A Scenario Outline's examples and a scenario tagged `@redundant` still don't count as redundant, as <doc:#Find-redundant-scenarios> describes.

## Find redundant scenarios

Each feature's redundancy score shows which scenarios test nothing that another scenario doesn't already test. Such a scenario costs time on every run and adds no coverage, so you can merge it into another scenario or remove it.

The summary adds the redundancy after the coverage, and marks each scenario that runs no code of its own:

```
CucumberSwift coverage: Subtracting: 100% of the code its scenarios ran (4 of 4 regions in 2 functions), 15% of all measured code, redundancy 33%
    Share  Own regions      Time  Scenario
      29%            0     0.01s  Subtracting a larger number (line 6, adds no coverage of its own)
      42%            1     0.02s  Subtracting a smaller number (line 11)
      29%            0     0.01s  Subtracting another larger number (line 16, adds no coverage of its own)
```

A feature's redundancy is the share of the code its scenarios ran that another scenario ran again. A feature at or above 30% gets a warning on its `Feature:` line. Each scenario that adds no coverage of its own gets a warning on its line, with its time:

```
Scenario adds no coverage of its own: other scenarios ran all of its code. It took 0.40s.
```

Some repetition is deliberate, so the score leaves out 3 kinds:

- A Scenario Outline's examples count as one scenario, so rows that run the same code with other values aren't redundant.
- In a feature with 3 or more scenarios, code that every scenario runs, such as the setup its `Background` runs, doesn't count.
- A scenario tagged `@redundant` doesn't count. Use the tag for a scenario you keep on purpose, such as a test for a bug that came back.

Set the redundancy's levels as <doc:#Set-the-levels> shows. Setting its warning level to `.off` also turns off the warnings on scenarios. The score is on whenever coverage is, and `Cucumber.redundancy = false` or `CUCUMBER_REDUNDANCY=NO` turns it off.

## Choose the code to measure

CucumberSwift measures every source file built with code coverage, except your dependencies' files, CucumberSwift's own, and your tests'. Your tests' files are the test bundle's when your app or framework has a binary of its own, as in an Xcode project. With `swift test`, the test bundle contains all the code, and the files in a `Tests` folder are left out instead.

Set `Cucumber.coverageSources` to measure only the files whose path contains one of its strings:

```swift
public func setupSteps() {
    Cucumber.coverage = true
    Cucumber.coverageSources = ["Sources/Checkout", "Sources/Payments"]
    // Your steps
}
```

The environment variable `CUCUMBER_COVERAGE_SOURCES` takes the strings separated by commas.

## Choose where the files go

CucumberSwift also writes each scenario's coverage to a file, for a coverage report of your own. It writes the files to `_cucumberCoverage` in the documents folder. On a Simulator, that folder is inside the Simulator. Set `CUCUMBER_COVERAGE_PATH`, or `Cucumber.coveragePath`, to a folder you can collect, such as one under your home folder:

```bash
CUCUMBER_COVERAGE=YES CUCUMBER_COVERAGE_PATH="$HOME/coverage" swift test --enable-code-coverage
```

Each run writes a folder of its own, `run-<id>`, in that folder. The runs of a suite split across several machines can then be collected in one folder without overwriting each other.

## What a run writes

The run's folder has a `.profraw` file for each scenario and each binary built with code coverage, and a `manifest.json`. A file's name starts with the scenario's position in the run and its line, such as `S0003-L12-MyAppTests.profraw`.

The manifest lists the binaries, each scenario that ran with its feature, name, line, tags, time and files, and each feature's scores:

```json
{
  "binaries" : [ { "path" : "/path/to/MyAppTests.xctest/Contents/MacOS/MyAppTests", "uuid" : "…" } ],
  "features" : [ { "featureName" : "Checkout", "line" : 1, "scores" : { "coveredRegions" : 15, "regionsInFunctionsRun" : 21, … } } ],
  "scenarios" : [
    {
      "duration" : 0.42,
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

Merge files with `llvm-profdata`, then report on the binary with `llvm-cov`. Both come with Xcode:

```bash
xcrun llvm-profdata merge S0001-L12-MyAppTests.profraw -o scenario.profdata
xcrun llvm-cov report /path/to/MyAppTests.xctest/Contents/MacOS/MyAppTests -instr-profile=scenario.profdata
```

## Limits

The Swift Testing runner runs scenarios one at a time while coverage is on, even with parallel testing turned on, as <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> describes. Scenarios that run at the same time add to the same coverage counters, so coverage and parallel testing are mutually exclusive. The XCTest runner is not affected.

The warnings need Xcode 26 with XCTest, and Swift 6.3 with Swift Testing. With an earlier version, CucumberSwift prints each warning instead, and still records the errors.

CucumberSwift reads version 7 of LLVM's coverage format, the one Xcode 26 writes, and prints the cause when a binary has another. It measures only the binaries built with code coverage, so it doesn't measure a prebuilt framework, such as a closed-source SDK.

CucumberSwift measures the code in the test process only. A UI test runs your app in another process, so the scores and files don't include the app's code. To get the app's coverage, build the app with code coverage, set `LLVM_PROFILE_FILE` in its launch environment, and merge its files with `llvm-profdata`.
