# Running Scenarios in Parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

Xcode's parallel testing, the **Execute in parallel** option on a test target in a scheme or test plan, or `xcodebuild -parallel-testing-enabled YES`, runs tests in several worker processes, on clones of the simulator for iOS. It hands each worker whole test classes. Without this experiment, CucumberSwift's scenarios don't run correctly in parallel: depending on the setup, each one runs in every worker, or not at all, and the run can still pass. So when Xcode runs a CucumberSwift test target in parallel and the experiment is off, the run fails: the first test of each worker fails with a message that names the setting. Turn the experiment on, or turn parallel testing off for the target.

With `Cucumber.parallelTesting = true` in `setupSteps()`, or `CUCUMBER_PARALLEL_TESTING` set to `YES` (the value is case-insensitive, and `TRUE` or `1` work too: see <doc:Settings>), each scenario is a test class of its own, which Xcode hands to one worker, as long as you keep a test per step, the default. The scenario's steps run in order in that worker, as they do in a serial run. With the experiment on, a serial run also runs each scenario as a class of its own, once, and XCTest orders the classes by name: by feature title, then scenario title, rather than in the order of the feature file.

It is experimental. Before you rely on it, read what works and what doesn't, and check your kind of test target and platform against the compatibility matrix.

## What works

| Feature | Status | Works? | Notes |
|---|---|---|---|
| Each scenario runs once, in a worker of its own (`.scenario`) | Experimental | Yes | Checked in CI on every platform and kind of target below. |
| Each feature runs whole in one worker (`.feature`) | Experimental | Yes | Checked in CI. See <doc:Running-Scenarios-In-Parallel#What-Xcode-hands-out>. |
| `BeforeFeature` and `AfterFeature` | Experimental | Yes, in each worker that runs the feature | When they run depends on the unit: see <doc:Running-Scenarios-In-Parallel#Feature-hooks>. |
| Scenario and step hooks | Supported | Yes | They run as they do in a serial run. |
| State your step definitions share between scenarios | Not shared | Per worker | Each worker is a process of its own, so a variable that counts scenarios counts only that worker's. |
| The JSON report | Supported | Yes, one report for every worker | The workers write one report between them, with every scenario once. On a Simulator, set `Cucumber.reportPath` or `CUCUMBER_REPORT_PATH` to a path on the Mac, which every clone can reach: see <doc:Generating-Reports#One-report-for-a-parallel-run>. A device runs one worker, and writes its own report. |
| One test per scenario (``Cucumber/oneTestPerScenario``) | Not supported | No | Every scenario is then a test of one class, which Xcode hands to one worker. Keep a test per step, the default. |
| Physical devices | Not tried | Unknown | Only simulators, macOS and Mac Catalyst have been tried. |
| A scenario that didn't run | Not reported | No | From inside a worker, CucumberSwift can't tell a scenario your test plan, `-skip-testing` or a rerun of failed tests left out on purpose from one that went missing. |
| A scenario that starts twice in one worker | Reported | Yes | It fails at its line in the feature file. |
| Classes made too late for XCTest to list them | Reported | Yes | The run fails with a test that says so. |
| A parallel run with `Cucumber.parallelTesting` off | Reported | Yes, with limits | The first test of each worker fails with a message that names the setting. It relies on Xcode's private API, which a new Xcode can change: the run then behaves as it did before, without the message. It doesn't notice a unit test target hosted in an app on Mac Catalyst either, where Xcode runs the tests in one worker. And with one test per scenario nothing fails: that mode is not affected. |

## Compatibility matrix

Tried on the iOS and tvOS Simulators, macOS and Mac Catalyst, with Xcode 16.4 and Xcode 26. The results are the same for both Xcode versions.

| Kind of test target | iOS Simulator | tvOS Simulator | macOS | Mac Catalyst |
|---|---|---|---|---|
| Unit tests without a host app | Parallel | Parallel | Parallel | Parallel |
| Unit tests hosted in an app | Correct, one worker | Correct, one worker | Parallel | Correct, one worker |
| UI tests | Parallel | Parallel | Correct, tried with one worker | Correct, tried with one worker |

- **Parallel:** the scenarios, or the features, ran in more than one worker, each exactly once.
- **Correct, one worker:** every scenario ran exactly once, but in one worker. On the Simulators and Mac Catalyst, Xcode runs the tests of a target hosted in an app in one worker, plain XCTest tests too. That is how Xcode runs them, which we measured and found no Apple documentation for, not something CucumberSwift decides.
- **Correct, tried with one worker:** UI tests on macOS and Mac Catalyst have only been tried with one worker.

Xcode hands out whole test classes, one at a time to each worker (Apple's WWDC20 session [Get your test results faster](https://developer.apple.com/videos/play/wwdc2020/10221/) says "Xcode build will distribute tests to each run destination by class"), so each class has to exist before XCTest lists the classes. CucumberSwift makes them when the test bundle loads, which was before XCTest listed any class in every kind of target tried.

## What Xcode hands out

`Cucumber.parallelTestingUnit` says what a test class holds, and so what Xcode hands to a worker:

- **`.scenario`, the default:** each scenario is a class of its own, which Xcode can hand to any worker.
- **`.feature`:** each feature is a class of its own, holding a test for each step of each of its scenarios. Xcode hands the whole feature to one worker, which runs its scenarios in the order of the feature file.

Set it in `setupSteps()`, or set `CUCUMBER_PARALLEL_TESTING_UNIT` to `scenario` or `feature`, in any case. The static variable wins over the environment variable, as for every setting (see <doc:Settings>). It applies only with parallel testing on and a test per step.

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

With `.feature`, the name of each test starts with its scenario's position in the feature and the scenario's title, then the step's position, so that the tests run in the order of the feature file and two scenarios with the same title stay apart: `2 › Pay by card › 3 › Then the cart holds 1 items`, or `Scenario02_PayByCard_Step002_ThenTheCartHolds1Items` with readable test names off. Two features with the same title get classes named `Checkout` and `Checkout 2`.

## Feature hooks

Each worker is a process of its own, so a feature's hooks run in each worker that runs one of its scenarios. In a serial run with parallel testing off, they run as they always have.

**With `.scenario`,** in each worker that runs at least one of a feature's scenarios:

- `BeforeFeature` runs once, before that worker's first scenario of the feature.
- `AfterFeature` runs once, after all of that worker's tests have finished, for each feature the worker started, in the order it started them.

A worker can start other features in between, and a feature whose scenarios run in three workers runs each hook three times. With parallel testing on and one worker, `AfterFeature` runs at the end of the run, after all of the feature's scenarios.

No test is running when `AfterFeature` runs at the end of a worker, so XCTest drops a failed assertion there, and the run still passes. An async `AfterFeature` hook that throws then has its error printed to the log, with the hook's file and line and the feature's title. If `AfterFeature` must be able to fail a test, hand out whole features.

**With `.feature`,** each feature runs whole in one worker, so its hooks run exactly once, in order: `BeforeFeature`, the feature's scenarios in the order of the feature file, then `AfterFeature`. `AfterFeature` runs as the feature's last test finishes, so its failures fail that test. If that test doesn't run, because Xcode was told to run only some tests, `AfterFeature` runs after the worker's last test instead.
