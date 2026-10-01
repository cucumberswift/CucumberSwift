# Verbose Output

See every feature, scenario and step as it runs, to find out why a test did or didn't do what you expected.

## Overview

XCTest shows only the failures. When a scenario never reaches the step you expected, or you aren't sure which step definition ran, turn on verbose output. CucumberSwift then prints a line when each feature, scenario and step starts and finishes, with its result and how long it took:

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

Verbose output is off by default. Any one of the three switches below turns it on.

### Use an environment variable

Set `CUCUMBER_VERBOSE` to `1` or `true`. Any other value leaves it off. This needs no code change, so it suits a one-off run or a CI job.

- **Xcode:** choose **Product → Scheme → Edit Scheme…**, select **Test**, open **Arguments**, and add `CUCUMBER_VERBOSE` with the value `1` under **Environment Variables**.
- **Swift Package Manager or `xcodebuild`:** set it on the command line.

```bash
CUCUMBER_VERBOSE=1 swift test
```

### Set it in code

Set the static `Cucumber.verboseOutput` property to `true`. Do it before the tests start, for example in `setupSteps()`:

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

`StepImplementation` has an optional `verbose` property. Add it next to `bundle` and `setupSteps()`:

```swift
extension Cucumber: StepImplementation {
    public var verbose: Bool { true }
    // bundle and setupSteps() as usual
}
```

If your test target builds in the Swift 6 language mode, declare the conformance `@retroactive`, as <doc:Matching-Steps> describes.

### Find the output

CucumberSwift prints to standard output, with each line starting with `[CucumberSwift]`.

- **Xcode:** open the **Report navigator** (⌘9), choose the test run, and look at its **Test** log. Use the filter box to search for `[CucumberSwift]`.
- **Command line:** the lines appear in the terminal among the usual `Test Case` lines.

Xcode doesn't list CucumberSwift's scenarios in the Test navigator, because they're created while the tests run. To run them from there, add `class TestExplorer: CucumberTest { }` to your test target and run its `testGherkin`.

### What it doesn't change

Verbose output only adds lines to the log. It doesn't change which scenarios run, their results, or the JSON report. To choose scenarios, use tags, as <doc:Running-Tests-With-Swift-Package-Manager> describes. To receive the same events in your own code, write a custom reporter: see <doc:Generating-Reports>.
