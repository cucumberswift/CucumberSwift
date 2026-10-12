# Running Scenarios in Parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

Xcode's parallel testing, the **Execute in parallel** option on a test target in a scheme or test plan, or `xcodebuild -parallel-testing-enabled YES`, runs tests in several worker processes, on clones of the simulator for iOS. It hands each worker whole test classes. By default CucumberSwift's scenarios don't run correctly in parallel: depending on the setup, each one runs in every worker, or not at all, and the run can still pass. Leave parallel testing off for a CucumberSwift test target unless you turn on this experiment.

With `Cucumber.parallelTesting = true` in `setupSteps()`, or `CUCUMBER_PARALLEL_TESTING` set to `YES` (the value is case-insensitive, and `TRUE` or `1` work too: see <doc:Settings>), each scenario is a test class of its own, which Xcode hands to one worker, with a test per step, the default, and with one test per scenario (``Cucumber/oneTestPerScenario``). The scenario's steps run in order in that worker, as they do in a serial run. A serial run with the experiment on also runs each scenario as a class of its own, once, in the order of the feature files: each class's name starts with its position in them, as <doc:Running-Scenarios-In-Parallel#Test-names> shows.

It is experimental. Before you rely on it, read what works and what doesn't in the table below, and check your kind of test target and platform against it.

## What works

What works today and what doesn't, from what we have run with Xcode 16.4 and Xcode 26. **Yes** means it works there, and CI checks it. **No** means it doesn't work there, today. **Not checked** means we have no result, so don't read it as working or as not working.

| Feature | iOS Simulator | tvOS Simulator | macOS | Mac Catalyst |
|---|---|---|---|---|
| Unit tests without a host app run in parallel | Yes | Yes | Yes | Yes |
| Unit tests hosted in an app run in parallel | No | No | Yes | No |
| UI tests run in parallel | Yes | Yes | No | No |
| Each scenario runs once, in a worker of its own (`.scenario`) | Yes | Yes | Yes | Yes |
| Each feature runs whole in one worker (`.feature`) | Not checked | Not checked | Yes | Not checked |
| One test per scenario (``Cucumber/oneTestPerScenario``) | Yes | Yes | Yes | Yes |
| A serial run keeps the order of the feature files | Not checked | Not checked | Yes | Not checked |
| `BeforeFeature` and `AfterFeature` run in each worker that runs the feature | Yes | Yes | Yes | Yes |
| Scenario and step hooks run as they do in a serial run | Yes | Yes | Yes | Yes |
| One JSON report holds every worker's results | Yes, with `reportPath` | Yes, with `reportPath` | Yes | Yes |
| A scenario that starts twice in one worker fails at its line | Yes | Yes | Yes | Yes |
| Classes made too late for XCTest to list them fail the run | Yes | Yes | Yes | Yes |
| State your step definitions share is shared between workers | No | No | No | No |
| A scenario that didn't run is reported | No | No | No | No |

- **No** for a row about running in parallel means the scenarios still run correctly, in one worker. On the Simulators and Mac Catalyst, Xcode runs the tests of a target hosted in an app in one worker, plain XCTest tests too. That is how Xcode runs them, which we measured and found no Apple documentation for, not something CucumberSwift decides. UI tests on macOS and Mac Catalyst have only been tried with one worker, so we don't know whether they would run in parallel.
- **Order:** a serial run is one with Xcode's parallel testing off. With it on, Xcode gives each worker its classes in an order of its own, so the scenarios of a worker don't run in the order of the feature files. CucumberSwift's classes are named so that XCTest's order by name is the order of the files: see <doc:Running-Scenarios-In-Parallel#Test-names>.
- **Feature hooks:** when they run depends on what Xcode hands out: see <doc:Running-Scenarios-In-Parallel#Feature-hooks>.
- **The JSON report:** the workers write one report between them, with every scenario once. On a Simulator, set `Cucumber.reportPath` or `CUCUMBER_REPORT_PATH` to a path on the Mac, which every clone can reach: see <doc:Generating-Reports#One-report-for-a-parallel-run>. A device runs one worker, and writes its own report.
- **State:** each worker is a process of its own, so a variable that counts scenarios counts only that worker's.
- **A scenario that didn't run:** from inside a worker, CucumberSwift can't tell a scenario your test plan, `-skip-testing` or a rerun of failed tests left out on purpose from one that went missing.

Physical devices (a connected iPhone, iPad or Apple TV) haven't been tried, because CI has none. Xcode may be able to run your tests there, but we make no claim about it.

Xcode hands out whole test classes, one at a time to each worker (Apple's WWDC20 session [Get your test results faster](https://developer.apple.com/videos/play/wwdc2020/10221/) says "Xcode build will distribute tests to each run destination by class"), so each class has to exist before XCTest lists the classes. CucumberSwift makes them when the test bundle loads, which was before XCTest listed any class in every kind of target tried.

## What Xcode hands out

`Cucumber.parallelTestingUnit` says what a test class holds, and so what Xcode hands to a worker:

- **`.scenario`, the default:** each scenario is a class of its own, which Xcode can hand to any worker.
- **`.feature`:** each feature is a class of its own, holding a test for each step of each of its scenarios. Xcode hands the whole feature to one worker, which runs its scenarios in the order of the feature file.

Set it in `setupSteps()`, or set `CUCUMBER_PARALLEL_TESTING_UNIT` to `scenario` or `feature`, in any case. The static variable wins over the environment variable, as for every setting (see <doc:Settings>). It applies only with parallel testing on.

```swift
public func setupSteps() {
    Cucumber.parallelTesting = true
    Cucumber.parallelTestingUnit = .feature
    // Your steps
}
```

Hand out whole features when:

- **A feature's hooks set up and tear down something that must exist once**, such as a server, an account or seeded data. With `.feature`, `BeforeFeature` and `AfterFeature` each run once for the feature.
- **`AfterFeature` must be able to fail a test.** With `.scenario`, it runs after the worker's last test, where a failure can't fail one.
- **The scenarios are quick.** Xcode hands out fewer classes.

Keep `.scenario` when one feature holds most of the slow scenarios: Xcode can then spread them over the workers, and with `.feature` one worker would run them all.

With `.feature`, the name of each test starts with its scenario's position in the feature and the scenario's title, then the step's position, so that the tests run in the order of the feature file and two scenarios with the same title stay apart: `2 › Pay by card › 3 › Then the cart holds 1 items`, or `Scenario02_PayByCard_Step002_ThenTheCartHolds1Items` with readable test names off. With one test per scenario, the feature's class has a test for each scenario, named with the scenario's position and title: `2 › Pay by card`, or `Scenario02_PayByCard`. The feature's class is named with the feature's position among the features, as <doc:Running-Scenarios-In-Parallel#Test-names> shows.

## Feature hooks

Each worker is a process of its own, so a feature's hooks run in each worker that runs one of its scenarios. In a serial run with parallel testing off, they run as they always have.

**With `.scenario`,** in each worker that runs at least one of a feature's scenarios:

- `BeforeFeature` runs once, before that worker's first scenario of the feature.
- `AfterFeature` runs once, after all of that worker's tests have finished, for each feature the worker started, in the order it started them.

A worker can start other features in between, and a feature whose scenarios run in three workers runs each hook three times. With parallel testing on and one worker, `AfterFeature` runs at the end of the run, after all of the feature's scenarios.

No test is running when `AfterFeature` runs at the end of a worker, so XCTest drops a failed assertion there, and the run still passes. An async `AfterFeature` hook that throws then has its error printed to the log, with the hook's file and line and the feature's title. If `AfterFeature` must be able to fail a test, hand out whole features.

**With `.feature`,** each feature runs whole in one worker, so its hooks run exactly once, in order: `BeforeFeature`, the feature's scenarios in the order of the feature file, then `AfterFeature`. `AfterFeature` runs as the feature's last test finishes, so its failures fail that test. If that test doesn't run, because Xcode was told to run only some tests, `AfterFeature` runs after the worker's last test instead.

## Test names

XCTest lists test classes by name, and runs them in that order in a serial run, so each class's name starts with its position in the feature files. Sorted by name, the classes are in the order of the feature files. A scenario's class starts with the position of its feature among all the features and of the scenario in its feature, and a feature's class, with `.feature`, with the feature's position. The positions start at 1, are padded with zeros to at least two digits, and count every feature and scenario in your feature files, whichever ones `CUCUMBER_TAGS` or `shouldRunWith` leave out, so a class keeps its name whichever tags run.

| | Readable test names (the default) | `readableTestNames = false` |
|---|---|---|
| A scenario's class | `F01 S02 › Parallel checkout › Pay by card` | `F01_S02_ParallelCheckout\|PayByCard` |
| A step of it, with a test per step | `F01 S02 › Parallel checkout › Pay by card/3 › Then the cart holds 1 items` | `F01_S02_ParallelCheckout\|PayByCard/Step002_ThenTheCartHolds1Items` |
| Its test, with one test per scenario | `F01 S02 › Parallel checkout › Pay by card/Pay by card` | `F01_S02_ParallelCheckout\|PayByCard/PayByCard` |
| A feature's class, with `.feature` | `F01 › Parallel checkout` | `F01_ParallelCheckout` |

The prefix is padded to the width of the count when that is more than two digits: with 120 features, the first is `F001`. Adding the 100th feature, or the 100th scenario to a feature, renames the classes padded to that width. Below 100 features, and 100 scenarios in a feature, adding one doesn't rename anything. A Scenario Outline's examples each count as a scenario. Without `Cucumber.parallelTesting`, names have no prefix and don't change.

With one test per scenario, a scenario's test is in a class of its own, so name it for `-only-testing:` by that class and the test, as the test navigator shows them, such as `MyAppTests/F01 S02 › Parallel checkout › Pay by card/Pay by card`, not under `CucumberScenarioTest`.
