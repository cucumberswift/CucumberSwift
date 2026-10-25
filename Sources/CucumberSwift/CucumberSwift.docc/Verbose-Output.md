# Verbose output

See every feature, scenario and step as it runs, to find out why a test did or didn't do what you expected.

## Overview

Turn on verbose output when a scenario doesn't reach the step you expected, or you aren't sure which step definition ran. XCTest shows only the failures. With verbose output, CucumberSwift also prints a line when each feature, scenario and step starts and finishes, with its result and how long it took:

```
[CucumberSwift] Feature: Greeting
[CucumberSwift]   Scenario: A failing step
[CucumberSwift]     Given a friendly user
[CucumberSwift]       -> passed (0.001s)
[CucumberSwift]     Then the greeting is "Goodbye"
[CucumberSwift]       -> failed: XCTAssertEqual failed: ("Hello") is not equal to ("Goodbye") (0.421s)
[CucumberSwift]   Scenario "A failing step" failed (0.424s)
[CucumberSwift] Feature "Greeting" failed (0.447s)
```

Verbose output is off by default. Any one of the three switches below turns it on. None of them turns it off again. `Cucumber.verboseOutput` is a `Bool`, so unlike the other settings' static variables, it can't override the environment variable. See <doc:Settings>.

### Use an environment variable

Set `CUCUMBER_VERBOSE` to `1` or `true`, in any case. Any other value, `YES` included, leaves it off. You don't change any code, so this suits a one-off run or a CI job.

- In Xcode, choose **Product → Scheme → Edit Scheme…**, select **Test**, open **Arguments**, and add `CUCUMBER_VERBOSE` with the value `1` under **Environment Variables**.
- With Swift Package Manager or `xcodebuild`, set it on the command line:

  ```bash
  CUCUMBER_VERBOSE=1 swift test
  ```

### Set it in code

Set the static `Cucumber.verboseOutput` property to `true` before the tests start, for example in `setupSteps()`:

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }

    public func setupSteps() {
        Cucumber.verboseOutput = true
        // Your steps
    }
}
```

### Return true from your StepImplementation

Add the optional `verbose` property next to `bundle` and `setupSteps()`:

```swift
extension Cucumber: StepImplementation {
    public var verbose: Bool { true }
    // bundle and setupSteps() as usual
}
```

Declare the conformance `@retroactive` if your test target builds in the Swift 6 language mode, as <doc:Matching-Steps> describes.

### Find the output

CucumberSwift prints to standard output. Each line starts with `[CucumberSwift]`.

- In Xcode, open the **Report navigator** (⌘9), choose the test run, and look at its **Test** log. Type `[CucumberSwift]` in the filter box.
- On the command line, the lines appear in the terminal among the usual `Test Case` lines.

CucumberSwift creates its scenarios while the tests run, so Xcode's Test navigator lists them only after the first run. To run one scenario on its own, see <doc:Running-Tests-In-Xcode#Run-one-scenario>.

### Swift Testing

The Swift Testing runner prints the same lines and has the same three switches. Its lines go to the test log, between Swift Testing's own lines. See <doc:Running-Feature-Files-With-Swift-Testing#Reports-verbose-output-and-custom-reporters>.

### What it doesn't change

Verbose output only adds lines to the log. It doesn't change which scenarios run, their results, or the JSON report. To choose scenarios, use tags, as <doc:Running-Tests-With-Swift-Package-Manager> describes. To receive the same events in your own code, write a custom reporter. See <doc:Generating-Reports>.
