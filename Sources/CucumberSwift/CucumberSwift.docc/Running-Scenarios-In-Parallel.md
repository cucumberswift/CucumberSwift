# Running Scenarios in Parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

Xcode's parallel testing, the **Execute in parallel** option on a test target in a scheme or test plan, or `xcodebuild -parallel-testing-enabled YES`, runs tests in several worker processes, on clones of the simulator for iOS. It hands each worker whole test classes. By default CucumberSwift's scenarios don't run correctly in parallel: depending on the setup, each one runs in every worker, or not at all, and the run can still pass. Leave parallel testing off for a CucumberSwift test target unless you turn on this experiment.

With `Cucumber.parallelTesting = true` in `setupSteps()`, or `CUCUMBER_PARALLEL_TESTING` set to `YES` (the value is case-insensitive, and `TRUE` or `1` work too: see <doc:Settings>), each scenario is a test class of its own, which Xcode hands to one worker. That holds with a test per step, the default, and with one test per scenario (``Cucumber/oneTestPerScenario``). The scenario's steps run in order in that worker, as they do in a serial run. A serial run with the experiment on runs each scenario once, as a class of its own, in the order of the feature files: see <doc:Running-Scenarios-In-Parallel#Test-names-with-parallel-testing>.

It is experimental. Read the compatibility table, then the notes below it, before you rely on it.

## Compatibility

This table shows what works today and what does not, from what we have run with Xcode 16.4 and Xcode 26. **Yes** means it works there, and CI runs it. **No** means it does not work there, today. Each row is a feature of parallel testing and each column a destination.

| Feature | iOS Simulator | tvOS Simulator | macOS | Mac Catalyst |
|---|---|---|---|---|
| Unit tests without a host app run in parallel | Yes | Yes | Yes | Yes |
| Unit tests hosted in an app run in parallel | No | No | Yes | No |
| UI tests run in parallel | Yes | Yes | No | No |
| A class for each scenario, with a test per step | Yes | Yes | Yes | Yes |
| A class for each scenario, with one test per scenario | Yes | Yes | Yes | Yes |
| A serial run keeps the order of the feature files | Yes | Yes | Yes | Yes |
| A scenario that starts a second time fails at its line | Yes | Yes | Yes | Yes |
| One JSON report holds every worker's results | No | Not checked | No | Not checked |

- **No** for a row about running in parallel means the scenarios still run correctly, in one worker, so they don't run in parallel. Xcode runs a target hosted in an app in one worker on a Simulator and on Mac Catalyst, plain XCTest tests too: that is how Xcode runs them, which we measured and found no Apple documentation for, not something CucumberSwift decides. UI tests on macOS and Mac Catalyst have been tried with one worker only, so we don't know whether they would run in parallel.
- **No** for the JSON report means each worker writes a report of its own: on iOS, one for each simulator clone, and on macOS the workers share one file, which ends up holding one worker's results.
- **Not checked** means we have no result, so don't read it as working or as not working.

Physical devices (a connected iPhone, iPad or Apple TV) haven't been tried, because CI has none. Xcode may be able to run your tests there, but we make no claim about it.

## Notes

- **What CucumberSwift checks.** Xcode hands out whole test classes, one at a time to each worker (Apple's WWDC20 session [Get your test results faster](https://developer.apple.com/videos/play/wwdc2020/10221/) says "Xcode build will distribute tests to each run destination by class"), so each scenario's class has to exist before XCTest lists the classes. CucumberSwift makes them when the test bundle loads, which was before XCTest listed any class in every kind of target tried. If parallel testing is on and the classes were made too late anyway, the run fails with a test that says so. A scenario that starts a second time in the same worker fails at its line in the feature file. CucumberSwift doesn't report a scenario that didn't run: from inside a worker, it can't tell one that your test plan, `-skip-testing` or a rerun of failed tests left out on purpose from one that went missing.
- **Each worker is a process of its own.** State your step definitions share between scenarios, such as a variable that counts them, is per worker.
- **Feature hooks run per worker.** `BeforeFeature` runs in each worker that runs one of the feature's scenarios. `AfterFeature` runs in the worker that runs the feature's last scenario, which can finish before the feature's other scenarios have finished in other workers, or, in a serial run, before they start. Scenario and step hooks run as they do in a serial run.
- **Each scenario costs Xcode a little time to hand out**, so a parallel run pays off for scenarios that take a while, such as UI tests, more than for quick ones.

## Test names with parallel testing

XCTest lists test classes by name, and runs them in that order in a serial run, so each scenario's class name starts with the position of its feature among all the features, and of the scenario in its feature. Sorted by name, the classes are in the order of the feature files. The positions start at 1, are padded with zeros to at least two digits, and count every scenario in your feature files, whichever ones `CUCUMBER_TAGS` or `shouldRunWith` leave out, so a scenario keeps its name whichever tags run.

| | Readable test names (the default) | `readableTestNames = false` |
|---|---|---|
| Format | `F<feature> S<scenario> › <Feature> › <Scenario>` | `F<feature>_S<scenario>_<Feature>\|<Scenario>` |
| A test per step, the class | `F01 S02 › Parallel checkout › Pay by card` | `F01_S02_ParallelCheckout\|PayByCard` |
| A test per step, a step | `F01 S02 › Parallel checkout › Pay by card/3 › Then the cart holds 1 items` | `F01_S02_ParallelCheckout\|PayByCard/Step002_ThenTheCartHolds1Items` |
| One test per scenario | `F01 S02 › Parallel checkout › Pay by card/Pay by card` | `F01_S02_ParallelCheckout\|PayByCard/PayByCard` |

The prefix is padded to the width of the count when that is more than two digits: with 120 features, the first is `F001`. Adding the 100th feature, or the 100th scenario to a feature, renames the classes padded to that width. Below 100 features, and 100 scenarios in a feature, adding one doesn't rename anything. A Scenario Outline's examples each count as a scenario. Without `Cucumber.parallelTesting`, names have no prefix and don't change.

With one test per scenario, a scenario's test is in a class of its own, so name it for `-only-testing:` by that class and the test, as the test navigator shows them, such as `MyAppTests/F01 S02 › Parallel checkout › Pay by card/Pay by card`, not under `CucumberScenarioTest`. The test's name is the scenario's, with no feature in it, because each scenario's class is unique.
