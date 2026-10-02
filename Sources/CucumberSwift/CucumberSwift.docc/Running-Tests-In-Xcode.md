# Running Tests in Xcode

Find your scenarios in Xcode's test navigator, go from a failure to its step, and choose which scenarios run.

## Overview

CucumberSwift reads your feature files when the test bundle starts and creates the tests then, so Xcode's test navigator shows them only after the first run. By default, each scenario becomes a test class named after its feature and scenario, such as `Checkout › Pay with a gift card`, and each of its steps becomes a test in that class, such as `3 › Then the order total is 99`. The steps are numbered so that they run in the order of the feature file. The test navigator lists a class's failed tests first, and then the most recently run first, so read the numbers for the order.

### Settings

These settings change how your tests appear in Xcode, and the step definitions CucumberSwift suggests for steps that have none. Set each one in code, with a static variable on `Cucumber`, or without changing code, with an environment variable in a scheme or test plan. When both are set, the static variable wins.

| Setting | Static variable | Environment variable | Default |
|---|---|---|---|
| Name tests as you wrote them | `Cucumber.readableTestNames` | `CUCUMBER_READABLE_TEST_NAMES` | On |
| One test per scenario | `Cucumber.oneTestPerScenario` | `CUCUMBER_ONE_TEST_PER_SCENARIO` | Off: a test per step |
| Suggest regex literals for undefined steps (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>) | `Cucumber.generateRegexLiterals` | `CUCUMBER_GENERATE_REGEX_LITERALS` | Off: Cucumber expressions |

Set the static variables in your `StepImplementation`'s `setupSteps()`, which CucumberSwift calls before it creates the tests:

```swift
extension Cucumber: StepImplementation {
    public func setupSteps() {
        Cucumber.oneTestPerScenario = true
        // Your steps
    }
}
```

The environment variables take `YES` or `NO` (also `TRUE` or `FALSE`, and `1` or `0`). Add them in a test plan's **Configurations** tab, under **Arguments**, or in a scheme's Test action.

### Choose a test per step or one test per scenario

CucumberSwift can lay out a scenario's tests in two ways. You choose; a test per step is the default.

| | A test per step (default) | One test per scenario |
|---|---|---|
| In the test navigator | A class per scenario, such as `Checkout › Pay with a gift card`, with a test for each step | One test per scenario, such as `Checkout › Pay with a gift card`, in the class `CucumberScenarioTest` |
| A step's result | Each step has its own result: passed, failed or skipped | The scenario has one result; its steps show as activities in the test report |
| Run one scenario from the test navigator | No (see <doc:Running-Tests-In-Xcode#Run-one-scenario>) | Yes, with the scenario's run button |
| A failing step | Opens its line in the feature file | Opens its line in the feature file |
| Steps after a failure, or after a step that throws `XCTSkip` | Skipped | Skipped activities |

To have one test per scenario, set `Cucumber.oneTestPerScenario = true` in `setupSteps()`, or set `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES`. For example, keep a test per step in your default test plan, and add a test plan that sets `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES` for when you want to run scenarios one at a time.

Your step definitions, hooks and feature files don't change between the two. The tests' names do, so test plans that select or skip tests by name, and test history in CI, see different tests when you switch.

### Go from a failure to its step

A step that fails is reported at its line in the feature file. Click the failure in the issue navigator or the test report, and Xcode opens the feature file at that step and marks it there. The failure's call stack still leads to the line in your step definition that failed.

This holds for a failed assertion in a step definition, for a step that no step definition matches, and for a step that more than one step definition matches. Steps you write with the DSL have no feature file, so their failures stay in your Swift code.

Once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped, or with one test per scenario, as skipped activities.

### Tell Scenario Outline examples apart

Each example of a Scenario Outline is a scenario of its own, named after the outline and the example's values, such as `Sign in (email: bob@x.com, role: admin)`. Columns that the outline's title already uses, as in `Scenario Outline: Sign in as <role>`, are left out. To keep test names short, the values stop at 60 characters, followed by `…`. An example whose name would repeat another's gets its number too, as in `Sign in (email: amy@x.com, example 3)`.

### Test names

By default, tests are named with the text of your features, scenarios and steps as you wrote them, such as `Checkout › Pay with a gift card` and `3 › Then the order total is 99`. Each step's name starts with its position in the scenario, so the steps sort in the order of the feature file. A `/` in your text becomes `-`, and a full stop becomes a one dot leader (`․`), because Xcode reads those as separators in a test's name.

Test names then contain spaces and punctuation. If a tool in your build parses the output of `xcodebuild` and expects test names without spaces, turn readable names off with `Cucumber.readableTestNames = false` in `setupSteps()`, or set `CUCUMBER_READABLE_TEST_NAMES` to `NO`. Tests are then named in camel case, as in earlier versions: `Checkout|PayWithAGiftCard` and `Step002_ThenTheOrderTotalIs99`.

### Keep secrets out of feature files

Your step text, scenario names and Scenario Outline example values become test names, whether or not readable names are on. Test names appear in the output of `xcodebuild`, in CI logs, in `.xcresult` bundles and in test reports, and these often reach more people, and are kept longer, than your feature files. CI services hide only the secrets you register with them, not text from a feature file.

So don't write passwords, tokens or other secrets in a feature file. Name who or what the step uses, and have the step definition read the secret, for example from an environment variable that CI sets, or that a scheme you don't share sets:

```gherkin
When I sign in as the admin user
```

```swift
When("I sign in as the admin user") { _, _ in
    let password = ProcessInfo.processInfo.environment["ADMIN_PASSWORD"] ?? ""
    // Sign in with the password
}
```

Shared schemes and test plans are usually committed, so a secret set in one ends up in your repository too. A configuration file that isn't committed, or the Keychain, works as well.

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

With a test per step, the default, Xcode's test navigator can't run one scenario on its own: the test classes exist only while the bundle runs, so Xcode can't find the one it's asked for, runs no tests, and reports success. The same happens with `xcodebuild -only-testing:` and a scenario's name. To run one scenario, give it a tag of its own and choose it with `CUCUMBER_TAGS`, as above, or switch to one test per scenario.

With one test per scenario, a scenario's run button in the test navigator runs just that scenario. From the command line, name its test with `-only-testing:`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'MyAppTests/CucumberScenarioTest/Checkout › Pay with a gift card'
```

The test's name is its feature's and its scenario's, as the test navigator shows it. A scenario whose name repeats another's in the same feature gets a number, as in `Checkout › Pay 2`.

### Skip a scenario

To skip a scenario, for example when a service it needs is unavailable, throw `XCTSkip` from a step definition:

```swift
Given("the card terminal is offline") { _, _ in
    throw XCTSkip("The card terminal is offline")
}
```

The rest of the scenario doesn't run, and Xcode shows the steps after that one as skipped, with your reason. With one test per scenario, the scenario's test is skipped.

### Highlight feature files

Xcode shows `.feature` files as plain text. CucumberSwift comes with a Gherkin grammar for Xcode that colors keywords, tags, comments, strings, doc strings, `<placeholders>`, table separators and numbers. Only English keywords are colored. It also comes with code snippets for a feature, a scenario and a scenario outline. You install both with a script you run once. They are not part of the library, and the script changes nothing in Xcode itself: it copies files into your home folder.

It relies on how Xcode loads grammars and plug-ins, which Apple doesn't document, so a future version of Xcode could stop highlighting your feature files. Your tests are not affected either way.

To install it, run the script from a copy of the CucumberSwift repository:

```bash
git clone --depth 1 https://github.com/cucumberswift/CucumberSwift.git
CucumberSwift/Tools/Xcode/gherkin-highlighting.sh install
```

Then quit and reopen Xcode. Xcode asks whether to load an unexpected code bundle, the Gherkin plug-in, which contains only data and no code; choose **Load Bundle**. Xcode asks again after each Xcode update.

Feature files then open as Gherkin: in the File inspector (View ▸ Inspectors ▸ File), their type is **Default - Gherkin Query Document**. A feature file Xcode has already opened before keeps the type it had, Default - Plain Text. Set it once: select the file, and in the File inspector choose **Gherkin Query Document** as its type, then close the file and open it again.

To add a snippet, open the Library (View ▸ Show Library, or ⇧⌘L) in a feature file and choose it, or start typing its shortcut, `gherkin-feature`, `gherkin-scenario` or `gherkin-scenario-outline`, and choose it from the completions. Press Tab to move between its placeholders.

The script installs these items:

- `~/Library/Developer/Xcode/Plug-ins/Gherkin.ideplugin`, which tells Xcode that `.feature` files are Gherkin
- `~/Library/Developer/Xcode/Specifications/Gherkin.xclangspec`, the grammar
- three snippets in `~/Library/Developer/Xcode/UserData/CodeSnippets`

To remove them, run the script with `uninstall`, then quit and reopen Xcode:

```bash
CucumberSwift/Tools/Xcode/gherkin-highlighting.sh uninstall
```
