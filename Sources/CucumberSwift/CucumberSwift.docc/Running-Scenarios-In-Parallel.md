# Running scenarios in parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

Turn on `Cucumber.parallelTesting` to run your scenarios in Xcode's parallel test workers:

```swift
public func setupSteps() {
    Cucumber.parallelTesting = true
    // Your steps
}
```

You can set the `CUCUMBER_PARALLEL_TESTING` environment variable to `YES` instead: see <doc:Settings>.

Xcode's parallel testing runs your tests in several worker processes. It hands each worker whole test classes. On iOS and tvOS, each worker runs in its own copy of the simulator. Turn it on with the **Execute in parallel** option on a test target, or with `xcodebuild -parallel-testing-enabled YES`.

CucumberSwift makes each scenario a test class of its own, so Xcode hands each scenario to 1 worker. The scenario's steps run in order in that worker.

Parallel testing needs this setting. Without it, a scenario can run in every worker or in none, and the run can still pass. CucumberSwift fails the run instead. The first test in each worker fails with a message that names the setting.

Each scenario has its own state. Its steps and hooks reach it with `Scenario.state(Basket.init)`: see <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel>. The Swift Testing runner has the same setting. There, scenarios run at the same time in 1 process.

Parallel testing is experimental. Check the table below for your kind of test target and platform.

## What works and what doesn't

Xcode decides how many worker processes run your tests. It splits a test target by class, so a target's tests can run in several processes. Each scenario runs once and correctly in 1 process or in several. Its hooks run, and it appears once in the JSON report. Step definitions can't share state between workers.

A unit test target has a host app or it doesn't. Xcode starts a host app and loads the tests into it. You choose it in the target's **Host Application** setting. A target with no host app runs its tests in a plain test process. UI tests are the third kind. They drive your app from a separate runner.

Xcode 26 spreads these targets over several processes. In our testing, iOS and tvOS ran on Simulators.

| Test target | iOS | tvOS | mac&#x2060;OS | Mac&nbsp;Catalyst |
|---|:-:|:-:|:-:|:-:|
| Unit tests without a host app | ✅ | ✅ | ✅ | ✅ |
| Unit tests with a host app |  | ✅ | ✅ | ❌ |
| UI tests |  | ✅ | ❌ | ❌ |

Our GitHub Actions CI workflow couldn't show the empty cells on iOS Simulators: the second Simulator clone often failed to launch its app.

CucumberSwift works the same way on every platform:

- Xcode runs every test of a ❌ target in 1 worker, plain XCTest tests included, and neither unit changes that. We found no Apple documentation for this. Xcode 16.4 gave tvOS hosted tests 1 worker in a short run, and we haven't repeated it with a long one. Our CI checks the ✅ targets with `.scenario`, and with `.feature` on macOS. We haven't tried physical devices, because our CI has none.
- Each scenario runs once, in 1 worker. That holds with a test per step and with a test per scenario (``Cucumber/oneTestPerScenario``). `.feature` runs each feature whole in 1 worker. Feature hooks run in each worker that runs the feature: see <doc:Running-Scenarios-In-Parallel#Feature-hooks>. Scenario and step hooks run as they do in a serial run.
- All workers write to 1 JSON report, and every scenario appears once in it. Set `Cucumber.reportPath` or `CUCUMBER_REPORT_PATH` to a path on the Mac when you test on a Simulator, so every clone can reach it: see <doc:Generating-Reports#The-report-of-a-parallel-run>.
- Mistakes fail the run. A scenario that starts twice in 1 worker fails at its line. Xcode hands out whole test classes ([Get your test results faster](https://developer.apple.com/videos/play/wwdc2020/10221/), WWDC20), so a class made too late for XCTest to list fails the run. A parallel run with `Cucumber.parallelTesting` off fails too. That check uses Xcode's private API, so a new Xcode can break it. It misses targets with a host app on Mac Catalyst. It also misses runs with a test per scenario, because they work without the setting.
- A serial run keeps the order of the feature files. A serial run is a run with Xcode's parallel testing off. Our CI checks this on macOS only. Xcode orders each worker's classes its own way when parallel testing is on: see <doc:Running-Scenarios-In-Parallel#Test-names>.
- Each worker is a separate process. Step definitions don't share state between workers, so a counter counts only its own worker's scenarios.

## What Xcode hands out

`Cucumber.parallelTestingUnit` says what a test class holds, and so what Xcode hands to a worker:

- **`.scenario`, the default:** each scenario is a class of its own, which Xcode can hand to any worker.
- **`.feature`:** each feature is a class of its own, holding a test for each step of each of its scenarios. Xcode hands the whole feature to 1 worker, which runs its scenarios in the order of the feature file.

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

Keep `.scenario` when 1 feature holds most of the slow scenarios: Xcode can then spread them over the workers, and with `.feature` 1 worker would run them all.

With `.feature`, the name of each test starts with its scenario's position in the feature and the scenario's title, then the step's position, so that the tests run in the order of the feature file and 2 scenarios with the same title stay apart: `2 › Pay by card › 3 › Then the cart holds 1 items`, or `Scenario02_PayByCard_Step002_ThenTheCartHolds1Items` with readable test names off. With a test per scenario, the feature's class has a test for each scenario, named with the scenario's position and title: `2 › Pay by card`, or `Scenario02_PayByCard`. The feature's class is named with the feature's position among the features, as <doc:Running-Scenarios-In-Parallel#Test-names> shows.

## How many workers run

Use `.scenario` for the most parallelism. `.scenario` lets Xcode give scenarios to every worker. `.feature` runs each feature in 1 worker, so 2 features use at most 2 workers, however many you ask for. Our test project has 10 scenarios in 2 features. On 3 macOS workers it took about 8 seconds with `.scenario` and 14 seconds with `.feature`. The unit changes nothing in a target that Xcode runs in 1 worker. A worker gets no scenarios until its Simulator clone is ready, so a short run can finish before the second clone starts.

Xcode picks the number of workers. Pass one of these options to `xcodebuild` to set it yourself:

```bash
xcodebuild test -scheme MyAppTests -destination 'platform=macOS' \
  -parallel-testing-enabled YES -parallel-testing-worker-count 3
```

- `-parallel-testing-enabled YES` turns parallel testing on for every test target, whatever the scheme or test plan says.
- `-parallel-testing-worker-count 3` starts exactly 3 workers.
- `-maximum-parallel-testing-workers 3` lets Xcode start up to 3 workers.

In our testing, `.scenario` ran in exactly the number of workers we passed to `-parallel-testing-worker-count`, in every target marked ✅ above.

Xcode boots a copy of the simulator for each worker on iOS and tvOS.

### Example: a large feature

Suppose your suite has 10 features: 9 with 3 scenarios each, and 1 with 12. Each scenario takes 20 seconds. A serial run takes 13 minutes (39 scenarios x 20 seconds each = 780 seconds). With `.scenario`, Xcode hands out 39 classes of 20 seconds each. With `.feature`, it hands out 9 classes of 60 seconds each (3 scenarios x 20 seconds) and 1 class of 240 seconds (12 scenarios x 20 seconds). This table shows the fastest parallel run with each unit, in a target marked ✅ above. It assumes that every scenario takes the same time, and it ignores start-up:

| Workers | `.scenario` | `.feature` |
|---|:-:|:-:|
| 2 | 6 min 40 s | 7 min |
| 3 | 4 min 20 s | 5 min |
| 4 | 3 min 20 s | 4 min |
| 8 | 1 min 40 s | 4 min |

`.feature` can't get below 4 minutes, because the large feature runs in 1 worker. `.scenario` keeps getting faster with every worker, because Xcode gives each free worker its next scenario. If all your features have the same size, the 2 units differ by less than 1 feature. The table is arithmetic, not a measurement.

Every worker adds start-up time, and a Simulator worker has to boot first. Add workers until the saving per worker gets small, and expect little gain from a run of a few seconds.

## Feature hooks

Each worker is a process of its own, so a feature's hooks run in each worker that runs one of its scenarios. In a serial run with parallel testing off, they run as they always have.

**With `.scenario`,** in each worker that runs at least one of a feature's scenarios:

- `BeforeFeature` runs once, before that worker's first scenario of the feature.
- `AfterFeature` runs once, after all of that worker's tests have finished, for each feature the worker started, in the order it started them.

A worker can start other features in between, and a feature whose scenarios run in 3 workers runs each hook 3 times. With parallel testing on and 1 worker, `AfterFeature` runs at the end of the run, after all of the feature's scenarios.

No test is running when `AfterFeature` runs at the end of a worker, so XCTest drops a failed assertion there, and the run still passes. An async `AfterFeature` hook that throws then has its error printed to the log, with the hook's file and line and the feature's title. If `AfterFeature` must be able to fail a test, hand out whole features.

**With `.feature`,** each feature runs whole in 1 worker, so its hooks run exactly once, in order: `BeforeFeature`, the feature's scenarios in the order of the feature file, then `AfterFeature`. `AfterFeature` runs as the feature's last test finishes, so its failures fail that test. If that test doesn't run, because Xcode was told to run only some tests, `AfterFeature` runs after the worker's last test instead.

## Test names

XCTest lists test classes by name, and runs them in that order in a serial run, so each class's name starts with its position in the feature files. Sorted by name, the classes are in the order of the feature files. A scenario's class starts with the position of its feature among all the features and of the scenario in its feature, and a feature's class, with `.feature`, with the feature's position. The positions start at 1, are padded with zeros to at least 2 digits, and count every feature and scenario in your feature files, whichever ones `CUCUMBER_TAGS` or `shouldRunWith` leave out, so a class keeps its name whichever tags run.

| | Readable test names (the default) | `readableTestNames = false` |
|---|---|---|
| A scenario's class | `F01 S02 › Parallel checkout › Pay by card` | `F01_S02_ParallelCheckout\|PayByCard` |
| A step of it, with a test per step | `F01 S02 › Parallel checkout › Pay by card/3 › Then the cart holds 1 items` | `F01_S02_ParallelCheckout\|PayByCard/Step002_ThenTheCartHolds1Items` |
| Its test, with a test per scenario | `F01 S02 › Parallel checkout › Pay by card/Pay by card` | `F01_S02_ParallelCheckout\|PayByCard/PayByCard` |
| A feature's class, with `.feature` | `F01 › Parallel checkout` | `F01_ParallelCheckout` |

The prefix is padded to the width of the count when that is more than 2 digits: with 120 features, the first is `F001`. Adding the 100th feature, or the 100th scenario to a feature, renames the classes padded to that width. Below 100 features, and 100 scenarios in a feature, adding a feature or scenario doesn't rename anything. A Scenario Outline's examples each count as a scenario. Without `Cucumber.parallelTesting`, names have no prefix and don't change.

With a test per scenario, a scenario's test is in a class of its own, so name it for `-only-testing:` by that class and the test, as the test navigator shows them, such as `MyAppTests/F01 S02 › Parallel checkout › Pay by card/Pay by card`, not under `CucumberScenarioTest`.
