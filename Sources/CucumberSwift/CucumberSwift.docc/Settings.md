# Settings

Every setting CucumberSwift has, how to set it, and what it does by default.

## Overview

CucumberSwift's settings turn behaviours on or off, or give them a value. The table in <doc:Settings#All-settings> lists every setting, and the sections below describe the few that don't follow the usual rules. The article for each behaviour also documents its settings.

### How a setting works

A behaviour that you can turn on or off has two switches:

- An environment variable, named `CUCUMBER_` plus the setting's name in upper snake case, such as `CUCUMBER_ONE_TEST_PER_SCENARIO`.
- A static variable on `Cucumber`, with the same name in lower camel case, such as `Cucumber.oneTestPerScenario`.

`Cucumber.parallelTesting` has a third switch with the Swift Testing runner, a compilation condition. See <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel>.

The static variable wins when it is set. If it isn't set, the environment variable decides, and if neither is set, the default applies. A static variable is an optional `Bool`, so setting it back to `nil` hands the decision back to the environment variable. A setting that takes a value instead of a switch, such as `Cucumber.reportPath`, follows the same order. Its static variable is an optional `String`, and its environment variable takes text. For these settings, an empty value counts as not set.

Set the static variables in your `StepImplementation`'s `setupSteps()`, which CucumberSwift calls before it creates the tests:

```swift
extension Cucumber: StepImplementation {
    public func setupSteps() {
        Cucumber.oneTestPerScenario = true
        // Your steps
    }
}
```

Set the environment variables in a scheme's Test action, in a test plan's **Configurations** tab under **Arguments**, or on the command line:

```bash
CUCUMBER_ONE_TEST_PER_SCENARIO=YES swift test
```

The environment variables take `YES`, `TRUE` or `1` to turn a behaviour on, and `NO`, `FALSE` or `0` to turn it off, in any case. CucumberSwift ignores spaces and tabs around the value. It ignores any other value too, as if the variable weren't set.

### All settings

The table lists every setting, with the article that describes it:

| Setting | In code | Environment variable | Default | Runs with | Requires |
|---|---|---|---|---|---|
| <doc:Running-Tests-In-Xcode#Test-names> | `Cucumber.readableTestNames` | `CUCUMBER_READABLE_TEST_NAMES` | On | XCTest and Swift Testing | None |
| <doc:Running-Tests-In-Xcode#Choose-a-test-per-step-or-one-test-per-scenario> | `Cucumber.oneTestPerScenario` | `CUCUMBER_ONE_TEST_PER_SCENARIO` | Off: a test per step | XCTest and Swift Testing | None |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `Cucumber.generateRegexLiterals` | `CUCUMBER_GENERATE_REGEX_LITERALS` | Off: Cucumber expressions | XCTest and Swift Testing | iOS 16, macOS 13 or tvOS 16 to run the regex literals it generates |
| <doc:Matching-Steps#Step-definition-macros> | `Cucumber.generateMacros` | `CUCUMBER_GENERATE_MACROS` | Macros when the test target links the step definition macros, functions otherwise | XCTest and Swift Testing | None |
| <doc:Running-Scenarios-In-Parallel> (experimental), and <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> | `Cucumber.parallelTesting` | `CUCUMBER_PARALLEL_TESTING`, or a compilation condition of that name with Swift Testing | Off | XCTest and Swift Testing | With XCTest, it depends on the platform. See the article. |
| <doc:Running-Scenarios-In-Parallel#What-Xcode-hands-out> (experimental), and <doc:Running-Feature-Files-With-Swift-Testing#Run-scenarios-in-parallel> | `Cucumber.parallelTestingUnit` | `CUCUMBER_PARALLEL_TESTING_UNIT` | `.scenario` | XCTest and Swift Testing | Parallel testing on |
| <doc:Verbose-Output> | `Cucumber.verboseOutput`, `StepImplementation.verbose` | `CUCUMBER_VERBOSE` | Off | XCTest and Swift Testing | None |
| <doc:Generating-Reports#Choose-where-the-report-is-written> | `Cucumber.reportPath` | `CUCUMBER_REPORT_PATH` | `_cucumberReport.json` in the documents folder | XCTest and Swift Testing | None |
| <doc:Settings#Choose-scenarios-in-code> | `StepImplementation.shouldRunWith(scenario:tags:)` | None | All scenarios | XCTest and Swift Testing | None |
| <doc:Running-Tests-In-Xcode#Run-specific-scenarios-using-a-test-plan> | None | `CUCUMBER_TAGS` | All scenarios | XCTest and Swift Testing | None |
| <doc:Settings#Continue-after-a-failed-assertion> | `StepImplementation.continueTestingAfterFailure` | None | On | XCTest and Swift Testing | None |
| <doc:Hooks> | `StepImplementation.reverseOrderForAfterHooks` | None | Off | XCTest and Swift Testing | None |
| <doc:Matching-Steps#Async-steps> | `StepImplementation.asyncStepTimeout` | None | 60 seconds | XCTest and Swift Testing | None |
| <doc:Matching-Steps#Generate-regex-literals-instead> | `StepImplementation.regexLiteralStyle` | None | `#/…/#` | XCTest and Swift Testing | None |
| <doc:Settings#Where-the-feature-files-are> | Info.plist `FeaturesPath` | None | `Features` | XCTest and Swift Testing, in an Xcode test target | None |
| <doc:Settings#Test-name-delimiter> | Info.plist `FeatureScenarioDelimiter` | None | ` › `, or `\|` with readable test names off | XCTest, in an Xcode test target | None |

The "Requires" column lists what a setting needs beyond the Xcode versions in <doc:Supported-Platforms>. The Swift Testing runner reads the settings marked "Swift Testing" and ignores the others. <doc:Settings#Settings-that-work-differently> lists where it differs, and <doc:Running-Feature-Files-With-Swift-Testing> describes the runner.

### Settings that work differently

A few settings don't follow the rules in <doc:Settings#How-a-setting-works>.

**Verbose output has three switches, and any one of them turns it on.** Unlike the other settings, its static variable doesn't win over the environment variable:

1. `Cucumber.verboseOutput` is a `Bool`. `true` turns verbose output on. `false` only means this switch is off, so it can't turn off what the other two turn on.
2. `StepImplementation.verbose` is a `Bool` that you declare next to `setupSteps()`. `true` turns verbose output on.
3. `CUCUMBER_VERBOSE` is an environment variable. `1` or `true`, in any case, turns verbose output on. `YES` and `NO` do nothing.

See <doc:Verbose-Output>.

**`Cucumber.parallelTestingUnit` takes `.scenario` or `.feature`, not on or off.** Its environment variable, `CUCUMBER_PARALLEL_TESTING_UNIT`, takes `scenario` or `feature`, in any case. CucumberSwift ignores spaces and tabs around the value, and ignores any other value, as if the variable weren't set. The static variable wins when it is set. If it isn't, the environment variable decides, and the default is `.scenario`. See <doc:Running-Scenarios-In-Parallel#What-Xcode-hands-out>.

**`StepImplementation` properties have no environment variable.** You set them by returning a value from your `StepImplementation`, next to `bundle` and `setupSteps()`. Each one is optional. CucumberSwift uses its default when you don't declare it.

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }
    public var asyncStepTimeout: TimeInterval { 120 }
    public func setupSteps() { /* Your steps */ }
}
```

**Info.plist keys apply only to Xcode test targets.** Swift Package Manager generates the test bundle's `Info.plist` itself, so the keys aren't available there.

**`CUCUMBER_TAGS` is a filter, not a flag.** It takes a comma-separated list of regular expressions that match regardless of case. A scenario runs when any of its tags, its Rule's tags or its feature's tags matches any of the expressions. Don't put spaces around the commas, because the spaces become part of the expression. Both runners use `CUCUMBER_TAGS` whenever it's set, even to an empty value, and then don't call `shouldRunWith`. See <doc:Running-Tests-In-Xcode#Run-specific-scenarios-using-a-test-plan>.

**With Swift Testing, some settings work differently.** The Swift Testing runner does the same as the XCTest runner for every setting marked "Swift Testing" above, with these exceptions:

- `continueTestingAfterFailure` sets fail-fast mode. By default it's `true`, and a step runs to its end after a failed assertion. With `false`, XCTest stops a step at its first failed assertion. With Swift Testing, a failed `#expect` doesn't stop a step, so use `try #require` for the checks that must stop it. See <doc:Running-Feature-Files-With-Swift-Testing#After-a-failed-assertion>.
- With `parallelTesting`, XCTest runs tests in separate processes, so their state is isolated. Swift Testing runs them in one process. Use `Scenario.state(_:)` to share state between the steps of a scenario and to keep it apart between scenarios. See <doc:Running-Feature-Files-With-Swift-Testing#Sharing-state-between-steps-in-a-scenario>.
- The plugin finds the feature files in the test target's folder, whatever the Info.plist key `FeaturesPath` says. The runner reads `FeaturesPath` only to map the files to the bundled files for the report's URIs. It doesn't read `FeatureScenarioDelimiter`. Support for both is planned ([#462](https://github.com/cucumberswift/CucumberSwift/issues/462)).

### Choose scenarios in code

Implement `shouldRunWith(scenario:tags:)` in your `StepImplementation` to decide in code which scenarios run. CucumberSwift calls it for each scenario, with the scenario's tags: its feature's tags, then its Rule's, then its own. The scenario runs when the function returns `true`. This example skips every scenario tagged `@wip`, including the scenarios in a Rule tagged `@wip`:

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

When `CUCUMBER_TAGS` is set, it takes over, and CucumberSwift doesn't call `shouldRunWith`. The Swift Testing runner calls it too, and shows a scenario that it leaves out as skipped. See <doc:Running-Feature-Files-With-Swift-Testing#Step-and-hook-options>.

### Continue after a failed assertion

`continueTestingAfterFailure` sets what XCTest does when an assertion in a step fails. If your `StepImplementation` doesn't declare it, CucumberSwift uses XCTest's own `continueAfterFailure`, which is `true`. So by default, a failed assertion doesn't stop its step. The rest of the step's code runs, and XCTest reports every failure. A failing async step's task isn't cancelled either.

If you return `false`, XCTest stops the step at its first failed assertion. With one test per scenario, it stops the scenario's test there. An async step's task is also cancelled when it fails, and CucumberSwift waits for it to finish before going on.

<!-- swift-example: members -->
```swift
public var continueTestingAfterFailure: Bool { false }
```

Either way, once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped. The Swift Testing runner reads this property too, but it can't stop everything that XCTest stops. See <doc:Running-Feature-Files-With-Swift-Testing#After-a-failed-assertion>.

### Where the feature files are

`FeaturesPath` is the path of your feature files, relative to the test bundle. Add it to the Info.plist of an Xcode test target whose feature folder has another name, such as `specs/features`. If you don't set it, CucumberSwift reads the bundle's `Features` folder. The Swift Testing runner reads the feature files when the tests build, and uses `FeaturesPath` only to name them in the JSON report, as CucumberSwift does.

### Test name delimiter

`FeatureScenarioDelimiter` is the text between the feature's name and the scenario's name in a test's name. If you don't set it, the delimiter is ` › ` with readable test names, and `|` with them off. It applies both to a test per step and to one test per scenario.
