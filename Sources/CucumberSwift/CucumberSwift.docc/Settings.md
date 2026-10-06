# Settings

Every setting CucumberSwift has, how to set it, and what it does by default.

## Overview

Most settings are documented next to the behaviour they change. This article lists all of them in one place, and describes the few that don't follow the usual rules.

### How a setting works

A behaviour you can turn on or off has two switches:

- an environment variable, `CUCUMBER_` plus the setting's name in upper snake case, such as `CUCUMBER_ONE_TEST_PER_SCENARIO`, and
- a static variable on `Cucumber`, with the same name in lower camel case, such as `Cucumber.oneTestPerScenario`.

The static variable wins when it is set, then the environment variable, then the default. A static variable is an optional `Bool`, so setting it back to `nil` hands the decision back to the environment variable.

**Static variables.** Set them in your `StepImplementation`'s `setupSteps()`, which CucumberSwift calls before it creates the tests:

```swift
extension Cucumber: StepImplementation {
    public func setupSteps() {
        Cucumber.oneTestPerScenario = true
        // Your steps
    }
}
```

**Environment variables.** They take `YES`, `TRUE` or `1` to turn a behaviour on, and `NO`, `FALSE` or `0` to turn it off, in any case, with any spaces or tabs around the value ignored. Any other value is ignored, as if the variable weren't set. Set them in a scheme's Test action, in a test plan's **Configurations** tab under **Arguments**, or on the command line:

```bash
CUCUMBER_ONE_TEST_PER_SCENARIO=YES swift test
```

### All settings

| Setting | In code | Environment variable | Default | Runs with | Requires |
|---|---|---|---|---|---|
| <doc:Running-Tests-In-Xcode#Test-names> | `Cucumber.readableTestNames` | `CUCUMBER_READABLE_TEST_NAMES` | On | XCTest | — |
| <doc:Running-Tests-In-Xcode#Choose-a-test-per-step-or-one-test-per-scenario> | `Cucumber.oneTestPerScenario` | `CUCUMBER_ONE_TEST_PER_SCENARIO` | Off: a test per step | XCTest | — |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `Cucumber.generateRegexLiterals` | `CUCUMBER_GENERATE_REGEX_LITERALS` | Off: Cucumber expressions | XCTest | iOS 16, macOS 13 or tvOS 16 to run the regex literals it generates |
| <doc:Running-Tests-In-Xcode#Parallel-testing> (experimental) | `Cucumber.parallelTesting` | `CUCUMBER_PARALLEL_TESTING` | Off | XCTest | Per platform: see the article |
| <doc:Verbose-Output> | `Cucumber.verboseOutput`, `StepImplementation.verbose` | `CUCUMBER_VERBOSE` | Off | XCTest | — |
| <doc:Running-Tests-In-Xcode#Choose-scenarios-with-a-test-plan> | `StepImplementation.shouldRunWith(scenario:tags:)` | `CUCUMBER_TAGS` | All scenarios | XCTest and Swift Testing | — |
| <doc:Settings#Continue-after-a-failed-assertion> | `StepImplementation.continueTestingAfterFailure` | — | On | XCTest | — |
| <doc:Hooks> | `StepImplementation.reverseOrderForAfterHooks` | — | Off | XCTest | — |
| <doc:Matching-Steps#Async-steps> | `StepImplementation.asyncStepTimeout` | — | 60 seconds | XCTest | — |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `StepImplementation.regexLiteralStyle` | — | `#/…/#` | XCTest | — |
| <doc:Settings#Where-the-feature-files-are> | Info.plist `FeaturesPath` | — | `Features` | XCTest, in an Xcode test target | — |
| <doc:Settings#Test-name-delimiter> | Info.plist `FeatureScenarioDelimiter` | — | ` › `, or `\|` with readable test names off | XCTest, in an Xcode test target | — |

"Requires" lists what a setting needs beyond the Xcode that CucumberSwift supports, which <doc:Supported-Platforms> gives. The Swift Testing runner reads only `CUCUMBER_TAGS`: none of the other settings apply to it. See <doc:Running-Feature-Files-With-Swift-Testing>.

### Settings that work differently

**Verbose output has three switches, and any one of them turns it on.** `Cucumber.verboseOutput` is a `Bool`, not an optional, so it has no way to say "off" that could win over the others: the static variable doesn't beat the environment variable here, and `false` means only that this switch is off. `StepImplementation.verbose` is the second switch. `CUCUMBER_VERBOSE` is the third, and it takes only `1` or `true`, in any case: `YES` and `NO` do nothing. See <doc:Verbose-Output>.

**`StepImplementation` properties have no environment variable.** You set them by returning a value from your `StepImplementation`, next to `bundle` and `setupSteps()`. Each one is optional: CucumberSwift uses its default when you don't declare it.

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }
    public var asyncStepTimeout: TimeInterval { 120 }
    public func setupSteps() { /* Your steps */ }
}
```

**Info.plist keys apply only to Xcode test targets.** A Swift package generates its test bundle's `Info.plist` itself, so with Swift Package Manager the keys aren't available.

**`CUCUMBER_TAGS` is a filter, not a flag.** It takes a comma-separated list of regular expressions, matched without regard to case, and a scenario runs when any of its tags, or its feature's, matches any of them. Don't put spaces around the commas: they are part of the expression. See <doc:Running-Tests-In-Xcode#Choose-scenarios-with-a-test-plan>.

### Choose scenarios in code

Implement `shouldRunWith(scenario:tags:)` in your `StepImplementation` to decide in code which scenarios run. CucumberSwift asks it for each scenario, with the scenario's tags, and runs the scenario when it returns `true`:

```swift
extension Cucumber: StepImplementation {
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("wip")
    }
    // bundle and setupSteps() as usual
}
```

`CUCUMBER_TAGS` takes over when it is set: CucumberSwift then doesn't ask `shouldRunWith`. The Swift Testing runner has no `shouldRunWith`: use `CUCUMBER_TAGS` there.

### Continue after a failed assertion

`continueTestingAfterFailure` says what XCTest does when an assertion in a step fails. When your `StepImplementation` doesn't declare it, CucumberSwift uses XCTest's own `continueAfterFailure`, which is `true`. So by default:

- a failed assertion doesn't stop its step: the rest of the step's code runs, and every failure is reported, and
- a failing async step's task isn't cancelled.

Return `false` and XCTest stops the step at its first failed assertion. With one test per scenario, it stops the scenario's test there. An async step's task is also cancelled when it fails, and CucumberSwift waits for it to finish before going on.

```swift
public var continueTestingAfterFailure: Bool { false }
```

Either way, once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped.

### Where the feature files are

`FeaturesPath` is the path of your feature files, relative to the test bundle. Without it, CucumberSwift reads the bundle's `Features` folder. Add it to the Info.plist of an Xcode test target whose folder has another name, such as `specs/features`.

### Test name delimiter

`FeatureScenarioDelimiter` is the text between a feature's and a scenario's name in a test's name. Without it, the delimiter is ` › ` with readable test names, and `|` with them off. It applies to a test per step and to one test per scenario.
