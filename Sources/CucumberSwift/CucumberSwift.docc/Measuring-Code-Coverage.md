# Measuring code coverage

Score each feature's scenarios on how much of your code they test, and how much of it they test more than once.

## Overview

CucumberSwift measures the code that each scenario runs, and scores each feature when its last scenario finishes. Build the test target with code coverage, and CucumberSwift measures it:

```bash
swift test --enable-code-coverage
```

In Xcode, turn on the **Code Coverage** option of the scheme or test plan.

The `CUCUMBER_COVERAGE` environment variable and `Cucumber.coverage` default to `auto`, which is `nil` for `Cucumber.coverage`. With `auto`, CucumberSwift measures coverage when the test binary is built with code coverage, and does nothing, with no message, when it isn't. Set the variable to `YES` or `true` to always measure, and print the cause at the end of the run if the target has no code coverage. Set it to `NO` or `false` to never measure.

CucumberSwift prints each feature's scores when the feature finishes:

```
CucumberSwift coverage: Arithmetic: 71% of the code its scenarios ran (15 of 21 regions in 6 functions), 58% of all measured code
    Share  Own regions      Time  Scenario
      12%            2     0.10s  Adding two numbers (line 4)
      12%            2     0.02s  Subtracting a larger number (line 9)
      29%            6     0.01s  Dividing by zero (line 14)
      19%            4     0.02s  Classifying a small number (line 19)
```

A feature whose coverage is at or below 80% gets a warning on its `Feature:` line, with the functions whose code no scenario ran. Xcode shows the warning in the feature file, and `swift test` and `xcodebuild test` print it with the feature file and line:

```
/path/to/Features/Arithmetic.feature:1: warning: Feature coverage 71%: its scenarios ran 15 of the 21 regions in the 6 functions they entered (warning at or below 80%). Not run: Calculator.classify(Int), 5 regions, entered by the scenario at line 19; Calculator.divide(_: Int, by: Int), 1 region, entered by the scenario at line 14.
```

A warning doesn't fail a test. To fail the features with low coverage, set an error level, as <doc:#Fail-a-test-on-low-coverage> shows. Xcode's and `swift test`'s own coverage report for the whole run is unchanged.

### Find the issues in your tests

The XCTest runner records a feature's issues in tests of its own, which run after the feature's scenarios. Their suite is named after the feature, such as `Checkout › Coverage scores`, and has 2 tests:

- `Coverage`, for the coverage warning or error.
- `Redundancy`, for the redundancy warning or error, and the warnings on the scenarios that add no coverage of their own.

With the XCTest runner, an error fails its test, and the scenarios pass or fail on their own steps. The XCTest runner also prints each warning, because `swift test` and `xcodebuild test` print the errors that a test records but not its warnings. With parallel testing, a feature can end after its worker's last test, where an error couldn't fail a test, so the runner scores nothing while it runs. <doc:#Merge-parallel-and-sharded-runs> scores the workers' runs together after the tests. The Swift Testing runner prints each issue with its feature file and line instead, because Xcode stops the test process when a suite records an issue. Its errors don't fail a test, unless you set `Cucumber.coverageRecordsIssuesInSuites`, as <doc:#Fail-a-test-on-low-coverage> shows.

### Set it in code

Set `Cucumber.coverage` to `true` or `false` in `setupSteps()`. It wins over the environment variable:

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

The feature's scores here count only "Adding two numbers", and the Rule's only "Naming seven". A feature with Rules can then have a coverage warning on one Rule and none on another. The summary names the Rule after its feature, such as `Arithmetic › Numbers have names`.

## Set the levels

Set each level to a percentage, or to `.off` for no warning or no error. A feature gets a coverage warning or error when its coverage, rounded to a whole percentage, is at or below the level, and a redundancy warning or error when its redundancy is at or above the level. Each setting has an environment variable too, which takes a number from 0 to 100, or `NO`. The first example's comments give each setting's environment variable and default, and a line that sets a default is commented out.

### Use the defaults

The defaults warn and never fail a test. A warning at 80% coverage points to the features that leave code untested, and a warning at 30% redundancy points to the scenarios that repeat code. Neither score fails by default, because a feature can repeat code on purpose, such as to test boundary values, and an existing suite can take time to reach a coverage level. A build with code coverage uses every default below without any setting, so each line here is commented out:

```swift
public func setupSteps() {
    // Cucumber.coverage = nil                 // CUCUMBER_COVERAGE, default auto
    // Cucumber.coverageWarningLevel = 80      // CUCUMBER_COVERAGE_WARNING_LEVEL, default 80
    // Cucumber.coverageErrorLevel = .off      // CUCUMBER_COVERAGE_ERROR_LEVEL, default off
    // Cucumber.redundancy = true              // CUCUMBER_REDUNDANCY, default on
    // Cucumber.redundancyWarningLevel = 30    // CUCUMBER_REDUNDANCY_WARNING_LEVEL, default 30
    // Cucumber.redundancyErrorLevel = .off    // CUCUMBER_REDUNDANCY_ERROR_LEVEL, default off
    // Cucumber.redundantStepWarningLevel = 50 // CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL, default 50
    // Your steps
}
```

### Fail a test on low coverage

Coverage only warns by default. Setting the coverage error level makes the XCTest runner fail a feature's `Coverage` test when the feature's coverage is at or below the level. With 50, a feature fails when its scenarios miss most of the code they enter, as CucumberSwift 6.8.0 did by default:

```swift
public func setupSteps() {
    Cucumber.coverageErrorLevel = 50
    // Your steps
}
```

> Note: Swift Testing and Xcode
>
> The Swift Testing runner prints the error and fails no test. To make an error fail the feature's suite, set `Cucumber.coverageRecordsIssuesInSuites` to `true` in `setupSteps()`, or the environment variable `CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES` to `YES`. Xcode stops the test process when a suite records an issue, so use this setting with `swift test`, and leave it off in an Xcode project with Code Coverage on.

### Eliminate redundant steps

Set the redundancy's error level to 1% to make the XCTest runner fail every feature that has a redundant scenario, and raise the coverage levels with it. This strict mode suits a suite whose scenarios are slow, where each one must test code that no other one tests:

```swift
public func setupSteps() {
    Cucumber.coverageWarningLevel = 90
    Cucumber.coverageErrorLevel = 80
    Cucumber.redundancyErrorLevel = 1
    // Your steps
}
```

The warning level stays on in strict mode, because it also puts a warning on each scenario that adds no coverage of its own, which shows what to merge or remove. A Scenario Outline's examples and a scenario tagged `@redundant` still don't count as redundant, as <doc:#Find-redundant-scenarios> describes.

## Find redundant scenarios

CucumberSwift marks a scenario as redundant when the other scenarios run all the code it runs. Such a scenario costs time on every run and adds no coverage, so you can merge it into a Scenario Outline or remove it.

A scenario is redundant when the scenarios that are kept run all the code it runs after its `Background`. CucumberSwift first keeps every scenario that the others don't cover. Only scenarios that cover each other, such as two duplicates, are settled by their order in the feature file, and the later one is redundant.

CucumberSwift compares the code that runs, not the values you pass in. The Coverage sample's `Adding.feature` has 3 scenarios that add positive numbers through `add`, a function without branches, so they run the same code:

```gherkin
Feature: Adding
  The calculator adds whole numbers.

  Background:
    Given a calculator

  Scenario: Adding two numbers
    When I add 2 and 3
    Then the display shows "5"

  Scenario: Adding two other numbers
    When I add 4 and 4
    Then the display shows "8"

  Scenario: Adding ones
    When I add 1 and 1
    Then the display shows "2"

  Scenario: Adding two negative numbers
    When I add -2 and -3
    Then the display shows "minus 5"
```

The summary adds the redundancy and the wasted time after the coverage, and marks each redundant scenario:

```
CucumberSwift coverage: Adding: 100% of the code its scenarios ran (4 of 4 regions in 2 functions), 12% of all measured code, redundancy 50%, about 0.03 s of 0.16 s in redundant scenarios
    Share  Own regions      Time  Scenario
      21%            0     0.12s  Adding two numbers (line 7)
      21%            0     0.01s  Adding two other numbers (line 11, adds no coverage of its own)
      21%            0     0.01s  Adding ones (line 15, adds no coverage of its own)
      38%            1     0.01s  Adding two negative numbers (line 19)
```

The first scenario is kept, and the next two are redundant. The negative-numbers scenario runs code of its own, so it is kept too. A feature's redundancy is the share of its scenarios that are redundant, here 2 of 4. A feature at or above 30% gets a warning on its `Feature:` line. The wasted time is the total time of the redundant scenarios, such as "about 4.2 s of 12.6 s". The manifest records the time of each scenario and each feature.

Each redundant scenario gets a warning on its line, with its time. Both warnings are in the feature's `Redundancy` test:

```
Scenario adds no coverage of its own: other scenarios run all the code it runs after the Background. It took 0.01 s. Consider a Scenario Outline for other values, or remove it.
```

The warnings suggest a Scenario Outline because the scenarios differ only in their values. Write one Scenario Outline for the positive numbers, and its examples count as one scenario:

```gherkin
Scenario Outline: Adding positive numbers
  When I add <first> and <second>
  Then the display shows "<sum>"

  Examples:
    | first | second | sum |
    | 2     | 3      | 5   |
    | 4     | 4      | 8   |
    | 1     | 1      | 2   |
```

Xcode shows the warnings on the feature and on each scenario. The sample sets the redundancy's error level to 40%, so the feature line is an error here. By default it is a warning, and it never fails a test. The screenshot also shows a warning on each `When` step, which <doc:#Find-redundant-steps> explains:

![The Adding feature file in Xcode with a redundancy error on the Feature line, warnings on 2 scenarios, and warnings on 3 When steps. Each When step says 100% of its code is repeated by another step, and suggests a Scenario Outline for different values.](RedundantSteps-ScenarioOutline.png)

### Put shared code in a Background

Put the steps that every scenario needs in a `Background`. CucumberSwift leaves out of the redundancy the code that a scenario runs during its Background steps, including the code that those steps call. That code still counts toward the coverage. The `Given a calculator` step in the feature above is an example.

### Find redundant steps

CucumberSwift also marks redundant steps, because two steps with different text can run the same code. A step is redundant when other scenarios run its code in exactly the same way. Each redundant step gets a warning on its line that gives the share of its code that another step repeats.

Take the Coverage sample's `Memory.feature`, where both `When` steps open the memory before they read or clear it:

```gherkin
Feature: Memory
  The calculator keeps numbers in memory.

  Background:
    Given a calculator

  Scenario: Reading the memory
    When I read the memory
    Then the display shows "0"

  Scenario: Clearing the memory
    When I clear the memory
    Then the display shows "3"
```

The warnings suggest moving the code that opens the memory into the `Background`:

```
Redundant step. 75% of the code in this step is repeated by the step at line 12. Consider moving it to the Background.
Redundant step. 60% of the code in this step is repeated by the step at line 8. Consider moving it to the Background.
```

Xcode shows the warning on each step, and lists both under the feature's `Redundancy` test:

![The Memory feature file in Xcode with a warning on each of its 2 When steps, "I read the memory" and "I clear the memory". They say that 75% and 60% of the code in the step is repeated by the other step, and suggest moving it to the Background.](RedundantSteps-Background.png)

A step that opens the memory in the `Background` removes both warnings, and each `When` step then only reads or clears it.

The steps of scenarios that run exactly the same code after the Background, as in `Adding.feature`, get a warning too, and it suggests a Scenario Outline in place of the Background:

```
Redundant step. 100% of the code in this step is repeated by the step at line 12. Consider a Scenario Outline for different values.
```

CucumberSwift compares function by function. A function that two scenarios run with exactly the same regions counts as redundant. A function that they run with different inputs does not, because each input runs different regions: `sum` with positive numbers and with negative numbers runs different branches.

A step gets a warning at 50% or more. Set `Cucumber.redundantStepWarningLevel` to another percentage, or to `.off`. The environment variable `CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL` takes a number from 0 to 100, or `NO`. These warnings are in the feature's `Redundancy` test, and they don't change the feature's redundancy.

Some repetition is deliberate, so the score leaves out 3 more kinds:

- A Scenario Outline's examples count as one scenario, so rows that run the same code with other values aren't redundant.
- A scenario tagged `@redundant` doesn't count. Use the tag for a scenario you keep on purpose, such as a test for a bug that came back.
- A scenario with no steps of its own after the Background has nothing to compare.

Set the redundancy's levels as <doc:#Set-the-levels> shows. Setting its warning level to `.off` also turns off the warnings on scenarios. The score is on whenever coverage is, and `Cucumber.redundancy = false` or `CUCUMBER_REDUNDANCY=NO` turns it off.

## Choose the code to measure

CucumberSwift measures your app's own code by default, so you don't need to set anything. It measures every source file built with code coverage, except 3 kinds of files:

- Your dependencies' files, such as the packages that SwiftPM and Xcode check out, and the files in `Pods` and `Carthage`.
- CucumberSwift's own files.
- Your tests' files.

Your tests' files are the test bundle's when your app or framework has a binary of its own, as in an Xcode project. With `swift test`, the test bundle contains all the code, so CucumberSwift leaves out the files in a `Tests` folder instead.

Set `Cucumber.coverageSources` only to measure fewer files, such as one module of a large app. It measures only the files whose path contains one of its strings:

```swift
public func setupSteps() {
    Cucumber.coverage = true
    Cucumber.coverageSources = ["Sources/Checkout", "Sources/Payments"]
    // Your steps
}
```

The environment variable `CUCUMBER_COVERAGE_SOURCES` takes the strings separated by commas.

## Choose where the files go

CucumberSwift also writes each scenario's coverage to a file, for a coverage report of your own, whenever it measures coverage. It writes the files to `_cucumberCoverage` in the documents folder. On a Simulator, that folder is inside the Simulator. Each run first deletes the run folders in that default folder that started more than an hour earlier. Set `CUCUMBER_COVERAGE_PATH`, or `Cucumber.coveragePath`, to a folder you can collect, such as one under your home folder:

```bash
CUCUMBER_COVERAGE=YES CUCUMBER_COVERAGE_PATH="$HOME/coverage" swift test --enable-code-coverage
```

Each run writes a folder of its own, `run-<id>`, in that folder. The runs of a suite split across several machines can then be collected in one folder without overwriting each other. A folder that you set is never cleared.

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
      "tags" : [ "payments" ]
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

## Merge parallel and sharded runs

Run `cucumberswift coverage merge` after the tests to score the scenarios of several runs as one run. It reads each run's folder, such as the workers of a parallel run or the shards of a suite split across machines, and scores every feature and every Rule. It prints the same summaries and warnings as a run of all the scenarios one at a time:

```bash
CUCUMBER_COVERAGE=YES CUCUMBER_COVERAGE_PATH="$HOME/coverage" swift test --enable-code-coverage
swift run cucumberswift coverage merge "$HOME/coverage"
```

The tool takes coverage folders, which hold the `run-<id>` folders, or run folders. It exits with status 1 when a score reaches an error level, so a script or our GitHub Actions CI workflow can fail on it. It exits with status 2 when it can't merge the runs, such as runs of two different builds or with different levels. Set the same levels for every run.

Collect the folders of all the shards on one machine before you merge them. A scenario that appears in two runs counts once. The same feature file in two test bundles, such as one in each Simulator, counts as one feature. Shards of a Swift Testing feature that you write in Swift, as <doc:Running-Feature-Files-With-Swift-Testing#Write-features-in-Swift> shows, merge only when they run from the same checkout folder.

Run the tool with your build tool:

| Build tool | Command |
|:--|:--|
| Swift Package Manager | `swift run cucumberswift coverage merge <folder>` |
| Xcode and Carthage | `swift run --package-path <CucumberSwift checkout> cucumberswift coverage merge <folder>` |
| Bazel | `bazel run @cucumberswift//cli:cucumberswift -- coverage merge <folder>` |

The Swift Testing runner can't score scenarios that run at the same time in one process, because coverage counters are per process. To score a Swift Testing suite, run it one scenario at a time with `CUCUMBER_COVERAGE=YES`, or split it into shards, run them as separate processes, and merge them.

## Limits

The Swift Testing runner runs scenarios one at a time while coverage is on, as <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> describes. With `auto`, coverage stays off when you turn on parallel testing, and CucumberSwift prints one line that says why. An explicit `true` runs the scenarios one at a time. The XCTest runner is not affected.

A feature whose scenarios run no measured code, such as a UI test whose app runs in another process, gets no coverage or redundancy issue.

The XCTest runner records the warnings in tests only with Xcode 26. With an earlier version, it prints each warning and records only the errors.

CucumberSwift reads version 7 of LLVM's coverage format, the one Xcode 26 writes, and prints the cause when a binary has another. It measures only the binaries built with code coverage, so it doesn't measure a prebuilt framework, such as a closed-source SDK.

CucumberSwift measures the code in the test process only. A UI test runs your app in another process, so the scores and files don't include the app's code. To get the app's coverage, build the app with code coverage, set `LLVM_PROFILE_FILE` in its launch environment, and merge its files with `llvm-profdata`.
