# Settings

Every setting CucumberSwift has, how to set it, and what it does by default.

## Overview

Most settings are documented next to the behaviour they change. This article lists all of them in one place, and describes the few that don't follow the usual rules.

### How a setting works

A behaviour you can turn on or off has two switches:

- an environment variable, `CUCUMBER_` plus the setting's name in upper snake case, such as `CUCUMBER_ONE_TEST_PER_SCENARIO`, and
- a static variable on `Cucumber`, with the same name in lower camel case, such as `Cucumber.oneTestPerScenario`.

The static variable wins when it is set, then the environment variable, then the default. A static variable is an optional `Bool`, so setting it back to `nil` hands the decision back to the environment variable. A setting that takes a value rather than a switch, such as `Cucumber.reportPath`, follows the same order, with an optional `String` and the environment variable's text; an empty value counts as not set.

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
| <doc:Running-Tests-In-Xcode#Test-names> | `Cucumber.readableTestNames` | `CUCUMBER_READABLE_TEST_NAMES` | On | XCTest and Swift Testing | — |
| <doc:Running-Tests-In-Xcode#Choose-a-test-per-step-or-one-test-per-scenario> | `Cucumber.oneTestPerScenario` | `CUCUMBER_ONE_TEST_PER_SCENARIO` | Off: a test per step | XCTest and Swift Testing | — |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `Cucumber.generateRegexLiterals` | `CUCUMBER_GENERATE_REGEX_LITERALS` | Off: Cucumber expressions | XCTest and Swift Testing | iOS 16, macOS 13 or tvOS 16 to run the regex literals it generates |
| <doc:Matching-Steps#Step-definition-macros> | `Cucumber.generateMacros` | `CUCUMBER_GENERATE_MACROS` | Macros when the test target links the step definition macros, functions otherwise | XCTest and Swift Testing | — |
| <doc:Running-Scenarios-In-Parallel> (experimental), and <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> | `Cucumber.parallelTesting` | `CUCUMBER_PARALLEL_TESTING`, or a compilation condition of that name with Swift Testing | Off | XCTest and Swift Testing | XCTest: per platform, see the article |
| <doc:Running-Scenarios-In-Parallel#What-Xcode-hands-out> (experimental), and <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> | `Cucumber.parallelTestingUnit` | `CUCUMBER_PARALLEL_TESTING_UNIT` | `.scenario` | XCTest and Swift Testing | Parallel testing on |
| <doc:Verbose-Output> | `Cucumber.verboseOutput`, `StepImplementation.verbose` | `CUCUMBER_VERBOSE` | Off | XCTest and Swift Testing | — |
| <doc:Generating-Reports#Choose-where-the-report-is-written> | `Cucumber.reportPath` | `CUCUMBER_REPORT_PATH` | `_cucumberReport.json` in the documents folder | XCTest and Swift Testing | — |
| <doc:Settings#Choose-scenarios-in-code> | `StepImplementation.shouldRunWith(scenario:tags:)` | — | All scenarios | XCTest and Swift Testing | — |
| <doc:Running-Tests-In-Xcode#Run-specific-scenarios-using-a-test-plan> | — | `CUCUMBER_TAGS` | All scenarios | XCTest and Swift Testing | — |
| <doc:Settings#Continue-after-a-failed-assertion> | `StepImplementation.continueTestingAfterFailure` | — | On | XCTest and Swift Testing | — |
| <doc:Hooks> | `StepImplementation.reverseOrderForAfterHooks` | — | Off | XCTest and Swift Testing | — |
| <doc:Matching-Steps#Async-steps> | `StepImplementation.asyncStepTimeout` | — | 60 seconds | XCTest and Swift Testing | — |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `StepImplementation.regexLiteralStyle` | — | `#/…/#` | XCTest and Swift Testing | — |
| <doc:Settings#Where-the-feature-files-are> | Info.plist `FeaturesPath` | — | `Features` | XCTest and Swift Testing, in an Xcode test target | — |
| <doc:Settings#Test-name-delimiter> | Info.plist `FeatureScenarioDelimiter` | — | ` › `, or `\|` with readable test names off | XCTest, in an Xcode test target | — |

"Requires" lists what a setting needs beyond the Xcode that CucumberSwift supports, which <doc:Supported-Platforms> gives. The Swift Testing runner reads the settings marked "Swift Testing" and ignores the others; <doc:Settings#Settings-that-work-differently> lists where it differs. See <doc:Running-Feature-Files-With-Swift-Testing>.

### Settings that work differently

**Verbose output has three switches, and any one of them turns it on.** The static variable doesn't beat the environment variable here, as it does for other settings.

1. `Cucumber.verboseOutput` is a `Bool`. `true` turns verbose output on. `false` only means this switch is off, so it can't turn off what the other two turn on.
2. `StepImplementation.verbose` is a `Bool` that you declare next to `setupSteps()`. `true` turns verbose output on.
3. `CUCUMBER_VERBOSE` is an environment variable. `1` or `true`, in any case, turns verbose output on. `YES` and `NO` do nothing.

See <doc:Verbose-Output>.

**`Cucumber.parallelTestingUnit` takes `.scenario` or `.feature`, not on or off.** Its environment variable, `CUCUMBER_PARALLEL_TESTING_UNIT`, takes `scenario` or `feature`, in any case, with spaces or tabs around the value ignored. Any other value is ignored, as if the variable weren't set. The static variable wins when it is set, then the environment variable, then `.scenario`. See <doc:Running-Scenarios-In-Parallel#What-Xcode-hands-out>.

**`StepImplementation` properties have no environment variable.** You set them by returning a value from your `StepImplementation`, next to `bundle` and `setupSteps()`. Each one is optional: CucumberSwift uses its default when you don't declare it.

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }
    public var asyncStepTimeout: TimeInterval { 120 }
    public func setupSteps() { /* Your steps */ }
}
```

**Info.plist keys apply only to Xcode test targets.** A Swift package generates its test bundle's `Info.plist` itself, so with Swift Package Manager the keys aren't available.

**`CUCUMBER_TAGS` is a filter, not a flag.** It takes a comma-separated list of regular expressions, matched without regard to case, and a scenario runs when any of its tags, its Rule's or its feature's, matches any of them. Don't put spaces around the commas: they are part of the expression. See <doc:Running-Tests-In-Xcode#Run-specific-scenarios-using-a-test-plan>.

**With Swift Testing, some settings work differently.** The Swift Testing runner does the same as the XCTest runner for every setting marked "Swift Testing" above, with these exceptions:

- `continueTestingAfterFailure` is the setting for fail-fast mode. By default, the value is `true`, and a step runs to its end after a failed assertion. Set to `false`, it stops a step at its first failed assertion with XCTest; a failed `#expect` doesn't stop a step with Swift Testing, so use `try #require` for the checks that must: see <doc:Running-Feature-Files-With-Swift-Testing#After-a-failed-assertion>.
- `parallelTesting`: XCTest runs parallel tests in separate processes, so their state is isolated, whereas Swift Testing runs them in one process. Use `Scenario.state(_:)` to share state between steps and to isolate it between scenarios: see <doc:Running-Feature-Files-With-Swift-Testing#Sharing-state-between-steps-in-a-scenario>.
- The plugin finds the feature files in the test target's folder, whatever the Info.plist key `FeaturesPath` says: the runner reads `FeaturesPath` only to map them to the bundled files for the report's URIs. It doesn't read `FeatureScenarioDelimiter`. Honouring both is planned ([#462](https://github.com/cucumberswift/CucumberSwift/issues/462)).

### Choose scenarios in code

Implement `shouldRunWith(scenario:tags:)` in your `StepImplementation` to decide in code which scenarios run. CucumberSwift asks it for each scenario, with the scenario's tags (its feature's, then its Rule's, then its own), and runs the scenario when it returns `true`. To skip every scenario tagged `@wip`, including those in a Rule tagged `@wip`:

```gherkin
Feature: Checkout

  @wip
  Rule: Gift cards
    Scenario: Pay with a gift card
      Given I have a gift card
```

@TabNavigator {
@Tab("Swift Package Manager") {
```swift
extension Cucumber: StepImplementation {
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("wip")
    }

    public func setupSteps() {
        #Given("I have a gift card") {
            // Doesn't run: its scenario is skipped.
        }
    }
    // bundle as usual
}
```
}
@Tab("Carthage") {
```swift
extension Cucumber: StepImplementation {
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("wip")
    }

    public func setupSteps() {
        Given("I have a gift card") { _, _ in
            // Doesn't run: its scenario is skipped.
        }
    }
    // bundle as usual
}
```
}
@Tab("Swift Testing") {
```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("wip")
    }

    public func setupSteps() {
        #Given("I have a gift card") {
            // Doesn't run: Xcode shows its scenario as skipped.
        }
    }
}
```
}
}

`CUCUMBER_TAGS` takes over when it is set: CucumberSwift then doesn't ask `shouldRunWith`. The Swift Testing runner asks it too, and shows a scenario it leaves out as skipped: see <doc:Running-Feature-Files-With-Swift-Testing#Step-and-hook-options>.

### Continue after a failed assertion

`continueTestingAfterFailure` says what XCTest does when an assertion in a step fails. When your `StepImplementation` doesn't declare it, CucumberSwift uses XCTest's own `continueAfterFailure`, which is `true`. So by default:

- a failed assertion doesn't stop its step: the rest of the step's code runs, and every failure is reported, and
- a failing async step's task isn't cancelled.

Return `false` and XCTest stops the step at its first failed assertion. With one test per scenario, it stops the scenario's test there. An async step's task is also cancelled when it fails, and CucumberSwift waits for it to finish before going on.

<!-- swift-example: members -->
```swift
public var continueTestingAfterFailure: Bool { false }
```

Either way, once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped. The Swift Testing runner reads this property too, and it differs in what it can stop: see <doc:Running-Feature-Files-With-Swift-Testing#After-a-failed-assertion>.

### Where the feature files are

`FeaturesPath` is the path of your feature files, relative to the test bundle. Without it, CucumberSwift reads the bundle's `Features` folder. Add it to the Info.plist of an Xcode test target whose folder has another name, such as `specs/features`. The Swift Testing runner reads the feature files when the tests build, and uses `FeaturesPath` only to name them in the JSON report, as CucumberSwift does.

### Test name delimiter

`FeatureScenarioDelimiter` is the text between a feature's and a scenario's name in a test's name. Without it, the delimiter is ` › ` with readable test names, and `|` with them off. It applies to a test per step and to one test per scenario.
