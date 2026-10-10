# Running Scenarios in Parallel

Spread your scenarios across Xcode's parallel test workers. Experimental, and off by default.

## Overview

Xcode's parallel testing, the **Execute in parallel** option on a test target in a scheme or test plan, or `xcodebuild -parallel-testing-enabled YES`, runs tests in several worker processes, on clones of the simulator for iOS. It hands each worker whole test classes. By default CucumberSwift's scenarios don't run correctly in parallel: depending on the setup, each one runs in every worker, or not at all, and the run can still pass. Leave parallel testing off for a CucumberSwift test target unless you turn on this experiment.

With `Cucumber.parallelTesting = true` in `setupSteps()`, or `CUCUMBER_PARALLEL_TESTING` set to `YES` (the value is case-insensitive, and `TRUE` or `1` work too: see <doc:Settings>), each scenario is a test class of its own, which Xcode hands to one worker, as long as you keep a test per step, the default. The scenario's steps run in order in that worker, as they do in a serial run. With the experiment on, a serial run also runs each scenario as a class of its own, once, and XCTest orders the classes by name: by feature title, then scenario title, rather than in the order of the feature file.

It is experimental. Before you rely on it:

- **What has been tried.** On the iOS and tvOS Simulators, macOS and Mac Catalyst, with Xcode 16.4 and Xcode 26:
  - **Unit tests without a host app** run in parallel on all of them.
  - **Unit tests hosted in an app** run correctly on all of them, but in parallel only on macOS. On the Simulators and Mac Catalyst, Xcode runs the tests of a target hosted in an app in one worker, plain XCTest tests too.
  - **UI tests** run in parallel on the iOS and tvOS Simulators. On macOS and Mac Catalyst they have been tried with one worker only.

  Devices haven't been tried.
- **Check the number of tests that ran** against a serial run. It depends on when XCTest lists the classes it hands out, which a new Xcode can change.
- **Each worker is a process of its own.** State your step definitions share between scenarios, such as a variable that counts them, is per worker.
- **Feature hooks run per worker.** `BeforeFeature` runs in each worker that runs one of the feature's scenarios. `AfterFeature` runs in the worker that runs the feature's last scenario, which can finish before the feature's other scenarios have finished in other workers, or, in a serial run, before they start. Scenario and step hooks run as they do in a serial run.
- **The workers write one JSON report between them**, with every scenario once. On a Simulator, set `Cucumber.reportPath` or `CUCUMBER_REPORT_PATH` to a path on the Mac, which every clone can reach: see <doc:Generating-Reports#One-report-for-a-parallel-run>. A device runs one worker, and writes its own report.
- **It needs a test per step**, the default. With one test per scenario, every scenario is a test of one class, which Xcode hands to one worker.
- **Each scenario costs Xcode a little time to hand out**, so a parallel run pays off for scenarios that take a while, such as UI tests, more than for quick ones.
