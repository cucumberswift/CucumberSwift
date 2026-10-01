# Running Tests in Xcode

Find your scenarios in Xcode's test navigator, go from a failure to its step, and choose which scenarios run.

## Overview

CucumberSwift reads your feature files when the test bundle starts and creates the tests then, so Xcode's test navigator shows them only after the first run. Each scenario becomes a test class named after its feature and scenario, such as `Checkout|PayWithAGiftCard`, and each of its steps becomes a test in that class, such as `Step002_ThenTheOrderTotalIs99`. The steps are numbered so that they run in the order of the feature file. The test navigator lists a class's failed tests first, and then the most recently run first, so read the numbers for the order.

### Go from a failure to its step

A step that fails is reported at its line in the feature file. Click the failure in the issue navigator or the test report, and Xcode opens the feature file at that step and marks it there. The failure's call stack still leads to the line in your step definition that failed.

This holds for a failed assertion in a step definition, for a step that no step definition matches, and for a step that more than one step definition matches. Steps you write with the DSL have no feature file, so their failures stay in your Swift code.

Once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped.

### Tell Scenario Outline examples apart

Each example of a Scenario Outline is a scenario of its own, named after the outline and the example's values, such as `Sign in (email: bob@x.com, role: admin)`. Columns that the outline's title already uses, as in `Scenario Outline: Sign in as <role>`, are left out. To keep test names short, the values stop at 60 characters, followed by `…`. An example whose name would repeat another's gets its number too, as in `Sign in (email: amy@x.com, example 3)`.

### Name tests as you wrote them

By default, test names are in camel case. To have Xcode show the text of your features, scenarios and steps as you wrote them, such as `Checkout › Pay with a gift card` and `3 › Then the order total is 99`, return `true` from your `StepImplementation`'s `readableTestNames`:

```swift
extension Cucumber: StepImplementation {
    public var readableTestNames: Bool { true }
    // …
}
```

Each step's name starts with its position in the scenario, so the steps sort in the order of the feature file. A `/` in your text becomes `-`, and a full stop becomes a one dot leader (`․`), because Xcode reads those as separators in a test's name. Test names then contain spaces and punctuation. If a tool in your build parses the output of `xcodebuild`, check that it still reads test names correctly.

### Choose scenarios with a test plan

To run some scenarios rather than all of them, tag them in your feature files:

```gherkin
Feature: Checkout

  @Smoke @Checkout
  Scenario: Pay with a saved card
    …

  @Checkout
  Scenario: Pay with a gift card
    …
```

Then give each set of tags a test plan of its own:

1. Create a test plan named after its tags, such as **Smoke**, with your test target in it.
2. In the test plan's **Configurations** tab, under **Arguments**, add the environment variable `CUCUMBER_TAGS` with the tags as its value, such as `Smoke`. Separate several tags with commas, such as `Smoke,Checkout`, to run the scenarios that have any of them.
3. Add the test plan to your scheme, and keep a test plan without `CUCUMBER_TAGS` as the scheme's default, so that ⌘U runs every scenario.

To run a set of tags, choose its test plan in the menu at the top of the test navigator, and run the tests. From the command line, name it with `-testPlan`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan Smoke
```

Use a test plan for each set of tags rather than a configuration for each in one test plan. A test plan runs all of its configurations, and Xcode's test navigator shows a scenario as not run unless it ran in every one of them.

A tag in `CUCUMBER_TAGS` matches a feature's or scenario's tags as a regular expression, so `Smoke` also matches `@SmokeTest`. A feature tag applies to every scenario in the feature.

### Run one scenario

By default, each step is a test, and Xcode's test navigator can't run one scenario on its own: the test classes exist only while the bundle runs, so Xcode can't find the one it's asked for, runs no tests, and reports success. The same happens with `xcodebuild -only-testing:` and a scenario's name. To run one scenario, give it a tag of its own and choose it with `CUCUMBER_TAGS`, as above.

If you'd rather run scenarios from the test navigator, make each scenario one test, by returning `true` from your `StepImplementation`'s `oneTestPerScenario`:

```swift
extension Cucumber: StepImplementation {
    public var readableTestNames: Bool { true }
    public var oneTestPerScenario: Bool { true }
    // …
}
```

To switch it per scheme or test plan without changing code, set the environment variable `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES` or `NO`, which overrides `oneTestPerScenario`.

Each scenario is then a test of `CucumberScenarioTest`, such as `Checkout › Pay with a gift card`, and its run button runs just that scenario. From the command line, name it with `-only-testing:`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'MyAppTests/CucumberScenarioTest/Checkout › Pay with a gift card'
```

The scenario's steps run in order within its test, and the test report shows each one as an activity. A step that fails is still reported at its line in the feature file, and the steps after it show as skipped. The test navigator shows a result for each scenario rather than for each step.

### Skip a scenario

To skip a scenario, for example when a service it needs is unavailable, throw `XCTSkip` from a step definition:

```swift
Given("the card terminal is offline") { _, _ in
    throw XCTSkip("The card terminal is offline")
}
```

The rest of the scenario doesn't run, and Xcode shows the steps after that one as skipped, with your reason. With `oneTestPerScenario`, the scenario's test is skipped.
