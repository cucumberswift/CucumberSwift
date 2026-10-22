# Running Scenarios in Parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

To run CucumberSwift's scenarios with Xcode's parallel testing, turn on the experiment. Set `Cucumber.parallelTesting = true` in `setupSteps()`, or set `CUCUMBER_PARALLEL_TESTING` to `YES`. The value is case-insensitive, and `TRUE` and `1` work too (see <doc:Settings>).

```swift
public func setupSteps() {
    Cucumber.parallelTesting = true
    // Your steps
}
```

Xcode's parallel testing runs tests in several worker processes. For iOS, each worker runs on a clone of the simulator. You turn it on with the **Execute in parallel** option on a test target in a scheme or test plan, or with `xcodebuild -parallel-testing-enabled YES`. Xcode hands each worker whole test classes.

With the experiment on, each scenario is a test class of its own, and Xcode hands it to one worker. The class has a test for each step by default, or one test for the scenario with ``Cucumber/oneTestPerScenario``. The scenario's steps run in order in that worker, as they do in a serial run. A serial run with the experiment on also runs each scenario once, as a class of its own, in the order of the feature files. Each class's name starts with its position in the feature files, as <doc:Running-Scenarios-In-Parallel#Test-names> shows.

With the experiment off, CucumberSwift's scenarios don't run correctly in parallel. Depending on the setup, each scenario runs in every worker, or not at all, and the run can still pass. So when Xcode runs a CucumberSwift test target in parallel with the experiment off, the first test of each worker fails, with a message that names the setting. Turn the experiment on, or turn parallel testing off for the target.

Each scenario also has its own state, which its steps and hooks reach with `Scenario.state(Basket.init)`. The Swift Testing runner has the same setting, and runs scenarios at the same time in one process. <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> describes both.

The feature is experimental. Before you rely on it, check your kind of test target and platform in the table below.

## What works

The table shows what works with Xcode 16.4 and Xcode 26, from the runs we have made. **Yes** means it works there, and CI checks it. **No** means it doesn't work there today. **Not checked** means we have no result, so don't read it as working or as not working.

| Feature | iOS\* | tvOS\* | mac⁠OS | Mac Catalyst |
|---|---|---|---|---|
| Unit tests without a host app run in parallel | Yes | Yes | Yes | Yes |
| Unit tests hosted in an app run in parallel | No | No | Yes | No |
| UI tests run in parallel | Yes | Yes | No | No |
| Each scenario runs once, assigned to one worker (`.scenario`) | Yes | Yes | Yes | Yes |
| Each feature runs whole in one worker (`.feature`) | Not checked | Not checked | Yes | Not checked |
| One test per scenario (``Cucumber/oneTestPerScenario``) | Yes | Yes | Yes | Yes |
| A serial run keeps the order of the feature files | Not checked | Not checked | Yes | Not checked |
| `BeforeFeature` and `AfterFeature` run in each worker that runs the feature | Yes | Yes | Yes | Yes |
| Scenario and step hooks run as they do in a serial run | Yes | Yes | Yes | Yes |
| One shared JSON report holds every scenario once (on a Simulator, set `reportPath`) | Yes | Yes | Yes | Yes |
| A scenario that starts twice in one worker fails at its line | Yes | Yes | Yes | Yes |
| Classes made too late for XCTest to list them fail the run | Yes | Yes | Yes | Yes |
| A parallel run with `Cucumber.parallelTesting` off fails with a message that names the setting | Yes | Yes | Yes | Yes |
| State your step definitions share is shared between workers | No | No | No | No |
| A scenario that didn't run is reported | No | No | No | No |

\* iOS and tvOS were run on Simulators.

The notes below explain the rows of the table:

- **No** in a row about running in parallel means that the scenarios still run correctly, in one worker. On the Simulators and on Mac Catalyst, Xcode runs every test of a target hosted in an app in one worker, plain XCTest tests too. Xcode decides this, not CucumberSwift. We measured it, and found no Apple documentation for it. UI tests on macOS and Mac Catalyst have only been tried with one worker, so we don't know whether they would run in parallel.
- A serial run is one with Xcode's parallel testing off. With it on, Xcode gives each worker its classes in an order of its own, so a worker's scenarios don't run in the order of the feature files. CucumberSwift names its classes so that XCTest's order by name is the order of the files. See <doc:Running-Scenarios-In-Parallel#Test-names>.
- If you run in parallel with `Cucumber.parallelTesting` off, the first test of each worker fails with a message that names the setting. This check relies on Xcode's private API, which a new Xcode can change. The run would then behave as if the check didn't exist, without the message. The check doesn't notice a unit test target hosted in an app on Mac Catalyst, where Xcode runs the tests in one worker. With one test per scenario nothing fails, because that mode isn't affected.
- When feature hooks run depends on what Xcode hands out. See <doc:Running-Scenarios-In-Parallel#Feature-hooks>.
- Every worker writes to the same JSON report, which holds every scenario once. On a Simulator, set `Cucumber.reportPath` or `CUCUMBER_REPORT_PATH` to a path on the Mac, which every clone can reach. See <doc:Generating-Reports#One-report-for-a-parallel-run>.
- Each worker is a separate process, so a variable that counts scenarios counts only that worker's scenarios.
- From inside a worker, CucumberSwift can't tell a missing scenario from one that your test plan, `-skip-testing` or a rerun of failed tests left out on purpose.

We haven't tried physical devices (a connected iPhone, iPad or Apple TV), because CI has none. A device is expected to run one worker and write its own report, but we make no claim about it.

Xcode hands out whole test classes, one at a time, to each worker. Apple's WWDC20 session [Get your test results faster](https://developer.apple.com/videos/play/wwdc2020/10221/) says "Xcode build will distribute tests to each run destination by class". So each class has to exist before XCTest lists the classes. CucumberSwift creates the classes when the test bundle loads. In every kind of target we tried, that was before XCTest listed any class.

## What Xcode hands out

Set `Cucumber.parallelTestingUnit` to choose what a test class holds, and so what Xcode hands to a worker:

- With `.scenario`, the default, each scenario is a class of its own. Xcode can hand it to any worker.
- With `.feature`, each feature is a class of its own, with a test for each step of each of its scenarios. Xcode hands the whole feature to one worker, which runs its scenarios in the order of the feature file.

Set it in `setupSteps()`, or set `CUCUMBER_PARALLEL_TESTING_UNIT` to `scenario` or `feature`, in any case. As for every setting, the static variable wins over the environment variable (see <doc:Settings>). The setting applies only with parallel testing on.

```swift
public func setupSteps() {
    Cucumber.parallelTesting = true
    Cucumber.parallelTestingUnit = .feature
    // Your steps
}
```

Use `.feature` in these cases:

- A feature's hooks set up and tear down something that must exist once, such as a server, an account or seeded data. With `.feature`, `BeforeFeature` and `AfterFeature` each run once for the feature.
- `AfterFeature` must be able to fail a test. With `.scenario`, it runs after the worker's last test, where a failure can't fail any test.
- The scenarios are quick. Xcode then hands out fewer classes.

Keep `.scenario` when one feature holds most of the slow scenarios. Xcode can then spread them over the workers. With `.feature`, one worker would run them all.

With `.feature`, each test's name starts with its scenario's position in the feature and the scenario's title, then the step's position. So the tests run in the order of the feature file, and two scenarios with the same title stay apart. The test for step 3 of scenario 2 is named `2 › Pay by card › 3 › Then the cart holds 1 items`, or `Scenario02_PayByCard_Step002_ThenTheCartHolds1Items` with readable test names off. With one test per scenario, the feature's class has one test for each scenario, named with the scenario's position and title, such as `2 › Pay by card` or `Scenario02_PayByCard`. The feature's class name starts with the feature's position among the features, as <doc:Running-Scenarios-In-Parallel#Test-names> shows.

## Feature hooks

A feature's hooks run in each worker that runs one of the feature's scenarios, because each worker is a separate process. In a serial run with parallel testing off, the hooks run as they always have.

With `.scenario`, the hooks run like this in each worker that runs at least one of a feature's scenarios:

- `BeforeFeature` runs once, before that worker's first scenario of the feature.
- `AfterFeature` runs once, after all of that worker's tests have finished. It runs for each feature that the worker started, in the order the worker started them.

A worker can start other features in between. If a feature's scenarios run in three workers, each hook runs three times. With parallel testing on and one worker, `AfterFeature` runs at the end of the run, after all of the feature's scenarios.

When `AfterFeature` runs at the end of a worker, no test is running. So XCTest drops a failed assertion there, and the run still passes. If an async `AfterFeature` hook throws there, CucumberSwift prints the error to the log, with the hook's file and line and the feature's title. If `AfterFeature` must be able to fail a test, use `.feature`.

With `.feature`, each feature runs whole in one worker, so each hook runs once. They run in this order: `BeforeFeature`, the feature's scenarios in the order of the feature file, then `AfterFeature`. `AfterFeature` runs as the feature's last test finishes, so its failures fail that test. That test might not run, because Xcode was told to run only some tests. `AfterFeature` then runs after the worker's last test instead.

## Test names

Each test class's name starts with its position in the feature files, so sorting the classes by name puts them in the order of the feature files. In a serial run, XCTest runs the classes in that order.

A scenario's class name starts with its feature's position among all the features, then the scenario's position in its feature. With `.feature`, a feature's class name starts with the feature's position. Positions start at 1, with zeros in front to make at least two digits. They count every feature and scenario in your feature files, including the ones that `CUCUMBER_TAGS` or `shouldRunWith` leave out. So a class keeps its name whichever tags run.

| | Readable test names (the default) | `readableTestNames = false` |
|---|---|---|
| A scenario's class | `F01 S02 › Parallel checkout › Pay by card` | `F01_S02_ParallelCheckout\|PayByCard` |
| A step of it, with a test per step | `F01 S02 › Parallel checkout › Pay by card/3 › Then the cart holds 1 items` | `F01_S02_ParallelCheckout\|PayByCard/Step002_ThenTheCartHolds1Items` |
| Its test, with one test per scenario | `F01 S02 › Parallel checkout › Pay by card/Pay by card` | `F01_S02_ParallelCheckout\|PayByCard/PayByCard` |
| A feature's class, with `.feature` | `F01 › Parallel checkout` | `F01_ParallelCheckout` |

With more than 99 features, the prefix has as many digits as the count: with 120 features, the first is `F001`. So adding the 100th feature, or the 100th scenario to a feature, renames the classes. Below 100 features, and below 100 scenarios in a feature, adding one doesn't rename anything. Each example of a Scenario Outline counts as a scenario. Without `Cucumber.parallelTesting`, names have no prefix and don't change.

With one test per scenario, a scenario's test is in a class of its own. To run it with `-only-testing:`, name it by that class and the test, as the test navigator shows them, such as `MyAppTests/F01 S02 › Parallel checkout › Pay by card/Pay by card`. Don't name it under `CucumberScenarioTest`.
