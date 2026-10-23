# Running feature files with Swift Testing

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

Run your feature files with Swift Testing in a unit test target, with the step definitions you already have.

## Overview

In a unit test target, you can run your feature files with Swift Testing instead of XCTest. A build tool plugin reads the target's feature files when it builds, and generates Swift Testing tests from them:

- A suite for each feature.
- A test for each Scenario.
- A parameterized test for each Scenario Outline, with one test case for each row of its Examples tables.

Xcode's test navigator shows every feature and scenario before anything runs. You can run a single scenario from Xcode, with `swift test --filter`, or with `xcodebuild -only-testing`.

You write step definitions as for CucumberSwift: `extension Cucumber: StepImplementation`, `setupSteps()`, `Given`, `When`, `Then`, `And`, `But` and `MatchAll`, and the step definition macros. Backgrounds, Rules, Scenario Outlines, tags and `CUCUMBER_TAGS`, doc strings, data tables, scenario and step hooks, and feature files in other languages work as they do with CucumberSwift.

## Requirements

The Swift Testing runner has these requirements:

- **Swift 6.1 (Xcode 16.3) or later, and Swift Package Manager.** The runner is the `CucumberSwiftTesting` product, and the plugin is `CucumberSwiftTestingPlugin`. Carthage can't deliver a build tool plugin. <doc:Running-Tests-In-Xcode#CucumberSwiftTestingPlugin> covers this plugin together with CucumberSwift's other plugins.
- **Unit test targets only.** Xcode doesn't allow Swift Testing in UI test targets. UI tests keep running their feature files with CucumberSwift and XCTest.
- **`#expect` and `#require`, not `XCTAssert`.** Step definitions that this runner runs must use Swift Testing's expectations. Before Swift 6.4, Swift Testing ignores an XCTest assertion that fails inside one of its tests, so the scenario would pass.
- **Swift 6.2 or later for two features.** `Attach` needs it, and so does reporting a failed `#expect` on its step. With Swift 6.1, `Attach` is a compile error, and a failed `#expect` is reported where you wrote it, not on the step. See <doc:#Attachments> and <doc:#After-a-failed-assertion>.
- **Swift 6.3 or later for Xcode to show a skipped scenario as skipped.** Before Swift 6.3, a step that throws `XCTSkip` still stops its scenario, the hooks still run, and the report is the same. But Xcode shows the scenario's tests as passed. `Test.cancel` needs Swift 6.3. See <doc:#Skip-a-scenario>.
- **One runner per test target.** Link either `CucumberSwift` or `CucumberSwiftTesting` to a test target, not both. Each has its own `Cucumber`, `Given` and the rest, with the same names, so a file can't import both. In a target that links both, each runner runs every scenario with its own step definitions, and CucumberSwift fails the test run if it isn't set up too. A project can use both runners in different targets. See <doc:#Move-unit-tests-to-Swift-Testing>.

## Set up a Swift package

To set up a Swift package, turn on CucumberSwift's `Macros` trait and add `CucumberSwiftTestingMacros` to the test target. Then apply two plugins to the target. `CucumberSwiftTestingPlugin` generates the tests, and `CucumberSwiftLint` checks the feature files and step definitions, as it does with the XCTest runner:

```swift
// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MyAppTests",
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.4.0", traits: ["Macros"]),
        // Before Swift 6.4, SwiftPM needs this to resolve the Macros trait. No target uses it.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
    ],
    targets: [
        .testTarget(
            name: "MyAppTests",
            dependencies: [.product(name: "CucumberSwiftTestingMacros", package: "CucumberSwift")],
            // The plugin reads the feature files when the tests build; the tests don't need them.
            exclude: ["Features"],
            plugins: [
                .plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift"),
                .plugin(name: "CucumberSwiftLint", package: "CucumberSwift")
            ])
    ]
)
```

The plugin finds every `.feature` file in the target's folder. `CucumberSwiftTestingMacros` has the step definition macros, and also imports `CucumberSwiftTesting`, the runner.

The macros need the trait, and the trait downloads swift-syntax. Before Swift 6.4, SwiftPM also needs swift-syntax declared next to CucumberSwift to resolve the trait, as above (see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>). To write step definitions without the macros, leave the trait off and depend on `CucumberSwiftTesting` instead. See <doc:#Without-the-macros>.

## Set up an Xcode project

To use the runner in an Xcode project, follow these steps:

1. Add the CucumberSwift package to the project, and turn on its `Macros` trait in the package dependency's settings. Add the swift-syntax package to the project, as <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64> describes. Then add `CucumberSwiftTestingMacros` to your unit test target.

   Setting a package dependency's traits in an Xcode project needs Xcode 26.4 or later. With an earlier Xcode, add a local package that only turns the trait on, as <doc:Using-Step-Definition-Macros#Before-Xcode-264> describes, and add `CucumberSwiftTestingMacros` from CucumberSwift as above. Or add `CucumberSwiftTesting`, and write step definitions without the macros.
2. In the test target's **Build Phases**, add `CucumberSwiftTestingPlugin` and `CucumberSwiftLint` under **Run Build Tool Plug-ins**. Xcode asks you to trust the plugins the first time they run. On a CI machine, pass `-skipPackagePluginValidation` to `xcodebuild` instead.
3. Add your `Features` folder to the test target, for example as a folder reference in **Copy Bundle Resources**. The plugin sees only files that belong to the target.

## Write step definitions

Register step definitions in `setupSteps()`, as with CucumberSwift, and write them with the step definition macros: `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`. The compiler checks each expression against its closure. The closure takes one argument for each parameter, of the parameter's type, and optionally the `Step` last. `Cucumber` and `StepImplementation` both come from `CucumberSwiftTesting`, so Swift 6 asks you to mark the conformance `@retroactive`:

```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #BeforeScenario {
            Basket.shared.empty()
        }
        #Given("I have {int} cukes") { (count: Int) in
            Basket.shared.add(count)
        }
        #Then("the basket has {int} cukes") { (count: Int) in
            #expect(Basket.shared.count == count)
        }
    }
}
```

<doc:Using-Step-Definition-Macros> describes the macros in full, with the argument that each parameter gives. <doc:Checking-Step-Definitions> describes the mistakes the compiler reports and the fixes Xcode offers. Both work the same with this runner, including localized macros such as `#ES_Dado`. `CucumberSwiftTestingMacros` has every macro that `CucumberSwiftMacros` has, and the step types they expand to, such as ``ES_Dado``, are in `CucumberSwiftTesting`.

A step definition can be synchronous or `async`, and it runs on the main actor. Its pattern can be a Cucumber expression, or a regular expression in a string that starts with `^`, ends with `$`, or is written between slashes. It can also be a regex literal, such as `#/…/#`, with the step functions and with the macros (see <doc:Using-Step-Definition-Macros#Regex-literals>). Regex literals need iOS 16, macOS 13 or tvOS 16 at run time. The `Step` has the step's `match`, `keyword`, `docString`, `dataTable`, `tags` and `scenario`, as with CucumberSwift.

A deprecated form takes a regular expression in a `String` variable, and a closure that takes the matches as a `[String]`, as in CucumberSwift: `Given(pattern) { matches, step in … }`. As in CucumberSwift, a string literal binds to the Cucumber expression form instead, so use a variable or a regex literal.

`BeforeFeature`, `AfterFeature`, `BeforeScenario`, `AfterScenario`, `BeforeStep` and `AfterStep` take an optional `priority`, as with CucumberSwift. Hooks with a priority run first, lowest first. Each hook also has a macro, such as `#BeforeScenario`, that expands to it with the same arguments. See <doc:Using-Step-Definition-Macros#Hooks>.

### Feature hooks

`BeforeFeature` runs once, before the first scenario of a feature, and `AfterFeature` runs once, after its last scenario. Each takes the `Feature`:

```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #BeforeFeature { feature in
            // Once for "\(feature.title)", before its first scenario.
            Basket.shared.add(10)
        }
        #AfterFeature { _ in
            Basket.shared.empty()
        }
    }
}
```

Each hook runs once for each feature, around all of its scenarios, even when Swift Testing runs the feature's scenarios at the same time. The scenarios wait for `BeforeFeature` to finish. The tests that `CucumberSwiftTestingPlugin` generates mark where each feature ends. They need Swift 6.1, the runner's minimum.

As with CucumberSwift, `BeforeFeature` hooks run before the observers hear that the feature started, and `AfterFeature` hooks run before the observers hear that it finished. If `CUCUMBER_TAGS` filters out all of a feature's scenarios, neither hook runs for it. A feature hook that throws fails at the line where you wrote it, and the feature's scenarios still run.

### Attachments

`Attach` adds an attachment, such as a log or a file, to the test that is running. Call it from any hook or step, as with CucumberSwift. It takes a Swift Testing `Attachment`, where CucumberSwift takes an `XCTAttachment`:

```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Then("I save the basket") {
            #if compiler(>=6.2)
            Attach(Attachment("\(Basket.shared.count) cukes", named: "basket.txt"))
            #endif
        }
    }
}
```

Xcode's test report shows the attachment under the scenario, and `swift test --attachments-path` writes it to a folder. An attachment added in `AfterFeature` is under the feature. The JSON report doesn't include attachments, as with CucumberSwift. `Attach` needs Swift 6.2, the first version with attachments in Swift Testing. With Swift 6.1, calling `Attach` is a compile error, so you can't lose an attachment without noticing. To keep supporting Swift 6.1, put the call between `#if compiler(>=6.2)` and `#endif`, as the example does.

### Without the macros

Each macro expands to a step definition that you can also write yourself, with `Given`, `When`, `Then`, `And`, `But` or `MatchAll` and a closure that takes the `Match` and the `Step`. The macros are the recommended style. Use this form when you can't use them:

```swift
import CucumberSwiftTesting
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Given("I have {int} cukes") { match, _ in
            Basket.shared.add(try match.first(\.int))
        }
        Then("the basket has {int} cukes") { match, _ in
            let count = try match.first(\.int)
            #expect(Basket.shared.count == count)
        }
    }
}
```

This form needs no package trait, so it works in an Xcode project with any supported Xcode. You can mix both styles in one target.

## Run scenarios

Each scenario is a test, named after its title in camel case. For example, the scenario "Pay with a gift card" in the feature "Checkout" is `CucumberFeatures/Checkout/PayWithAGiftCard(_:)`. Xcode's test navigator and test reports show the titles as you wrote them, such as "Pay with a gift card". A repeated name gets `_2`, `_3` and so on.

As with CucumberSwift, each step is a test of its own. The scenario's test has a test case for each step, named as CucumberSwift names the step's test, such as `3 › Then the total is 99`, or `Step002_ThenTheTotalIs99` with `Cucumber.readableTestNames` off. An example of a Scenario Outline adds `Example (line 7)` before the step's name. The test navigator and the test report give a result for each step.

A scenario's `BeforeScenario` hooks run with its first step, and its `AfterScenario` hooks with its last. Running one step alone runs the steps before it. Once a step fails, the later steps don't run. With Swift 6.3, they're reported as cancelled. Before Swift 6.3, Swift Testing can't skip a test case from inside it, so they pass without running.

For one test case for the whole scenario, set `Cucumber.oneTestPerScenario` to `true`, or the environment variable `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES`.

Swift Testing needs the names of suites and tests as literals when the tests build. So unlike the step's name, the feature's and the scenario's names don't follow `Cucumber.readableTestNames`.

To run one scenario from the command line, select it by its name:

```bash
swift test --filter PayWithAGiftCard
xcodebuild test -scheme MyApp -only-testing:'MyAppTests/CucumberFeatures/Checkout/PayWithAGiftCard(_:)'
```

A Scenario Outline is one test, and each example is one of its test cases. Each example is named after the line of its row, such as `Example (line 17)`, so its results stay on its row when you change a value. Xcode can run a single example from the test navigator. `xcodebuild -only-testing` can select only the whole outline. Given a test case, it runs nothing, and still succeeds.

`CUCUMBER_TAGS` works as it does with CucumberSwift. It takes a comma-separated list of regular expressions, and a scenario runs when any of its tags matches any of them. The other scenarios are reported as skipped. An outline whose examples are all left out runs no test cases, and Swift Testing reports that as a pass.

Scenarios run one at a time, in the order of the feature files, as with CucumberSwift, because step definitions usually share state. This applies only to the scenarios. Your target's other Swift Testing tests can run at the same time as them. To run scenarios at the same time, see <doc:#Run-scenarios-in-parallel>.

### Run scenarios in parallel

To run scenarios at the same time, set the environment variable `CUCUMBER_PARALLEL_TESTING` to `YES`. A test target with many slow scenarios then finishes sooner. Parallel testing is off by default, as with CucumberSwift. The variable takes `YES`, `TRUE` or `1`, in any case, to turn it on, and `NO`, `FALSE` or `0` to turn it off. You can set it in two places:

- In Xcode, choose **Product → Scheme → Edit Scheme…**, select **Test**, open **Arguments**, and add `CUCUMBER_PARALLEL_TESTING` with the value `YES` under **Environment Variables**.
- With Swift Package Manager or `xcodebuild`, set it on the command line:

  ```bash
  CUCUMBER_PARALLEL_TESTING=YES swift test
  ```

You can also set `Cucumber.parallelTesting = true` in `setupSteps()`, as with CucumberSwift. It wins over the environment variable, as it does there. Swift Testing decides when it discovers the tests, so the runner runs `setupSteps()` at that point. If the runner can't run `setupSteps()` in time, only the static variable is affected. Scenarios then run one at a time unless the environment variable or the compilation condition turns parallel testing on, and a note says so once, without failing the run.

A third way is a compilation condition of the same name in the test target that has the feature files, not in your app target. In `Package.swift`, add `swiftSettings: [.define("CUCUMBER_PARALLEL_TESTING")]` to the test target. In an Xcode project, add `CUCUMBER_PARALLEL_TESTING` to the test target's **Active Compilation Conditions** build setting. The condition applies when neither the static variable nor the environment variable is set, so `CUCUMBER_PARALLEL_TESTING=NO` still turns parallel testing off.

### Choose what runs together

By default, any scenario may run at the same time as any other, because the unit is the scenario. To run each feature's scenarios one at a time, in the order of the feature file, while features run at the same time, set `Cucumber.parallelTestingUnit = .feature` in `setupSteps()`. Or set the environment variable `CUCUMBER_PARALLEL_TESTING_UNIT` to `feature`. The variable takes `scenario` or `feature`, in any case, and ignores spaces and tabs around the value. It ignores any other value. The static variable wins over the environment variable, as with CucumberSwift. The unit matters only when parallel testing is on.

The setting means something else here than in <doc:Running-Scenarios-In-Parallel>. There, Xcode spreads scenarios across worker processes, and each process has its own copy of your step definitions' state. Swift Testing runs them in one process, so every scenario sees what the others change, and the scenarios may run in any order. The runner starts each scenario's steps in order. Different scenarios can interleave at suspension points. While a step definition or a hook awaits, the main actor can run another scenario's step or hook. So main-actor isolation doesn't make shared state exclusive for the whole of an async step or hook. A step definition that never awaits runs from start to finish, and one that awaits doesn't. Swift Testing's own `--no-parallel` option, as in `swift test --no-parallel`, still runs one test at a time.

### Sharing state between steps in a scenario

Scenarios that run at the same time share one process, so anything one scenario writes, another can read. That includes the following:

- Global and static variables, singletons, and properties of an object that your step definitions capture, such as a shared `World` holding "the basket" that each step fills in.
- Files, `UserDefaults`, the keychain, a database, a port, or any other outside state that scenarios change.
- The app, the server or the fake that the scenarios drive, when they need it in different states.

Keep what the steps of one scenario share in that scenario's own state instead, with `Scenario.state(_:)`. Call it from any step or scenario hook, and it gives the running scenario a value of the type you ask for. It makes the value the first time a step or hook of that scenario asks, and gives every later step and hook of that scenario the same object. Another scenario gets its own value, so scenarios that overlap never see each other's. The runner releases the value when the scenario is over, and you don't need a lock for the lookup. Put it behind your `World`, and the steps keep reading `World.basket`:

```swift
import CucumberSwiftTestingMacros
import Testing

final class Basket {
    var cukes = 0
}

enum World {
    static var basket: Basket { Scenario.state(Basket.init) }
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Given("the basket has {int} cukes") { (count: Int) in
            World.basket.cukes = count
        }
        #Then("the basket has {int} cukes left") { (count: Int) in
            #expect(World.basket.cukes == count)
        }
    }
}
```

The value is a class, so the next step sees what one step changes. Different types are different values, so a scenario can have a `Basket` and a `Beach`. A step that runs another with `ExecuteFirstStep` shares its caller's values. `Scenario.state(_:)` works the same in CucumberSwift's XCTest runner, so step definitions that use it move between the runners unchanged. It needs a running scenario. If you call it from a feature hook, or from a task that a step left running with `Task.detached`, it fails the test with a message that says so. For what lives outside the process, use files, databases and fakes named after the scenario. All this matters only when parallel testing is on. A suite that runs one scenario at a time needs no change. If a step definition can't avoid shared state, leave parallel testing off.

### What behaves differently with parallel on

With scenarios running at the same time, these things behave differently:

- **Failures stay with their step.** A failed `#expect` or a thrown error is reported on the line of the step that was running in the failed scenario, even though other scenarios' steps are running. This holds in the test results and in the Cucumber JSON report.
- **Hooks run around their own scenario and step.** `BeforeScenario`, `AfterScenario`, `BeforeStep` and `AfterStep` hooks run for each scenario, in priority order, around the same scenario. The hooks of different scenarios can run at the same time. So a hook that sets up shared state, such as a database, runs once per scenario, while other scenarios are using that state.
- **Verbose output interleaves.** It prints each line as it happens, so the lines of different scenarios mix, as they do in a parallel XCTest run. See <doc:Verbose-Output>.
- **The JSON report is the same.** It has each scenario once, in the order of the feature files.
- **Observers get events from several scenarios in turn.** A custom `CucumberTestObserver` sees one scenario's events in order, with other scenarios' events between them. See <doc:#Reports-verbose-output-and-custom-reporters>.
- **Durations include waiting.** A scenario's duration includes the time it waited for other scenarios to give back the main actor.

### Check the feature files

The runner adds one test besides the scenarios, `CucumberFeatures/gherkin()`, shown as "Feature files are valid Gherkin". For each problem that the Gherkin parser finds in the target's feature files, the test fails with an issue on the file. It passes when there are none.

The test navigator lists the scenarios that Xcode found when it last indexed the target. Xcode doesn't always index again when only a feature file changes. Editing a scenario's steps or examples keeps its results on its row. A scenario that you add or rename runs with the others and shows in the test report. But its row in the navigator can wait until Xcode indexes the target again, for example after you build it or reopen the project.

## How failures are reported

The runner reports each failure on the line that caused it:

- A step that no step definition matches fails on its line in the feature file, and the message includes a step definition to paste into `setupSteps()`.
- A step that more than one step definition matches fails on its line in the feature file, and none of them runs.
- A step definition that throws fails on the step's line in the feature file. A hook that throws fails at the line where you wrote the hook, as with CucumberSwift.
- A `wait(for:timeout:)` fails when its timeout passes first, or when it sees an inverted expectation fulfilled. The failure appears on the step's line in the feature file, with XCTest's message for that result, as in CucumberSwift. This also works in Swift 6.1. The step runs to its end, and the scenario's later steps don't run. To wait without holding the main actor, write `await wait(for:timeout:)`.

If a step has no step definition or more than one, or its step definition or a step hook throws, the scenario's later steps don't run. Its `AfterScenario` hooks still run. A `BeforeStep` hook that throws also skips its step, and the step's `AfterStep` hooks still run. A `BeforeScenario` hook that throws skips the scenario's steps. An `AfterScenario` or feature hook that throws stops nothing else.

A hook that throws doesn't stop the later hooks of the same kind, as with CucumberSwift. A hook that throws, or fails an `#expect`, fails its scenario and feature, as with CucumberSwift. The report shows the failure on the step that is current when the hook runs. A `BeforeStep` hook fails its own step. A `BeforeScenario` hook fails the scenario's first step, and a `BeforeFeature` hook fails the first step of the feature's first scenario. The steps after it don't run. An `AfterStep`, `AfterScenario` or `AfterFeature` hook runs after the step is reported. So it leaves that step as it was, and fails the scenario or the feature.

A step or a hook that doesn't finish within `asyncStepTimeout` fails on its line, as in CucumberSwift. See <doc:#Step-and-hook-options>.

A failed `#expect`, or any other issue recorded while a step or a hook runs, is reported on the step's line in the feature file, or the scenario's for a scenario hook. Its message gives the step as it ran, with an example's values, such as `Then the basket has 3 cukes`, and where it was recorded, such as `Recorded at StepDefinitions.swift:31`. A step definition that throws gets the step in its message too. This needs Swift 6.2 or later. With Swift 6.1, a failed `#expect` is reported where you wrote it.

### After a failed assertion

Swift Testing records a failed `#expect` or `Issue.record` without telling the step, so the step's own code can't stop at it. The runner learns of the issue afterwards, with these results:

- **The step runs to its end, and then counts as failed.** Every failure inside it is reported. The scenario's later steps don't run and aren't in the report. Its `AfterScenario` and `AfterStep` hooks still run. CucumberSwift does the same once a step has failed.
- **`continueTestingAfterFailure` cancels async steps.** If you return `false` from your `StepImplementation`, an `async` step's task is also cancelled at its first failed expectation, so a step that's waiting stops waiting. The runner still waits for the task to finish. A synchronous step can't be stopped part way, whatever the setting says. XCTest can stop one at a failed assertion, but Swift Testing can't.
- **`try #require`, or any error a step throws, stops the step at once.** Use it where the next line can't make sense after this one failed.

This needs Swift 6.2 or later. With Swift 6.1, the runner can't see a failed `#expect`. The step is reported as passed and the scenario goes on, so use `try #require` where a step must stop the scenario.

### Skip a scenario

To skip the rest of a scenario, for example when a service it needs is unavailable, throw `XCTSkip` from a step definition, as with CucumberSwift:

```swift
import CucumberSwiftTestingMacros
import Testing
import XCTest

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Given("the card terminal is offline") {
            throw XCTSkip("The card terminal is offline")
        }
    }
}
```

With Swift 6.3 or later, `try Test.cancel("The card terminal is offline")` does the same.

The scenario's later steps don't run. Xcode shows the step's test as skipped, with your reason, and each later step's test as skipped, with "Skipped:" and your reason. With one test per scenario, the scenario's test is skipped. The step's `AfterStep` hooks and the scenario's `AfterScenario` hooks still run. In the JSON report, the step is `skipped`, and the steps after it aren't listed, as with CucumberSwift. A step that has already failed an `#expect` stays failed. Before Swift 6.3, Xcode shows these tests as passed. See <doc:#Requirements>.

## Step and hook options

The `StepImplementation` properties and functions below work as they do in CucumberSwift. Declare them next to `setupSteps()`. Each one is optional:

```swift
import CucumberSwiftTestingMacros
import Foundation

extension Cucumber: @retroactive StepImplementation {
    public var asyncStepTimeout: TimeInterval { 120 }
    public var reverseOrderForAfterHooks: Bool { true }
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("wip")
    }
    public func setupSteps() { /* Your steps */ }
}
```

The options work like this:

- **`shouldRunWith(scenario:tags:)`** decides in code which scenarios run. `CUCUMBER_TAGS` takes over when it's set. The runner calls it once for each scenario, before any scenario runs, after it calls `setupSteps()` if that hasn't happened yet. Xcode shows a scenario that it leaves out as skipped, as it does with `CUCUMBER_TAGS`. An example of a Scenario Outline that it leaves out isn't a test case at all, as with `CUCUMBER_TAGS`.
- **`reverseOrderForAfterHooks`** runs the `AfterScenario` and `AfterStep` hooks in the reverse of their usual order.
- **`asyncStepTimeout`** is how many seconds a step or a hook may run, 60 by default. A step or hook that suspends for longer is cancelled and fails on its line in the feature file, if what it awaits ends when it's cancelled. The runner waits for it to finish. As in CucumberSwift, the timeout applies only to a step or a hook that suspends. One that blocks the main actor can't be interrupted, and isn't failed.
- **`continueTestingAfterFailure`** is described in <doc:#After-a-failed-assertion>.
- **`verbose`** is described in <doc:#Reports-verbose-output-and-custom-reporters>.
- **`regexLiteralStyle`** sets how the suggested step definitions for undefined steps write their regex literals when `Cucumber.generateRegexLiterals` is on. The style is `#/…/#` by default, or ``RegexLiteralStyle/bareSlash``. The runner suggests Cucumber expressions by default. For regex literals, set `Cucumber.generateRegexLiterals = true` in `setupSteps()`, or `CUCUMBER_GENERATE_REGEX_LITERALS` to `YES`, as in <doc:Matching-Steps#Generate-regex-literals-instead>. With `CucumberSwiftTestingMacros` linked, the suggestions are step definition macros, unless `Cucumber.generateMacros` is `false`. See <doc:Matching-Steps#Step-definition-macros>.

### Run another step

> Deprecation Warning: `ExecuteFirstStep(keyword:matching:)` is deprecated, in this runner and in CucumberSwift's, and will be removed in a future major version. It still works as before.
>
> Cucumber's own guidance recommends against one step definition running another. Share the code through a helper function instead. See [Cucumber anti-patterns](https://cucumber.io/docs/guides/anti-patterns/) and [step organization](https://cucumber.io/docs/gherkin/step-organization/).

Put the code that both step definitions need in a function, and call the function from each:

```swift
import CucumberSwiftTestingMacros

@MainActor func addCukes(_ count: Int) {
    Basket.shared.add(count)
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Given("I add {int} cukes to the basket") { (count: Int) in
            addCukes(count)
        }
        #When("I check out as a guest") {
            addCukes(2)
        }
    }
}
```

## Reports, verbose output and custom reporters

The runner writes the Cucumber JSON report, prints verbose output and tells your own reporters what it sees, with the same settings, the same report and the same `CucumberTestObserver` as CucumberSwift.

**The JSON report.** The runner writes the report as scenarios finish, to `_cucumberReport.json` in the documents folder. To write it somewhere else, set `Cucumber.reportPath` in `setupSteps()`, or the environment variable `CUCUMBER_REPORT_PATH`, to a full path, as <doc:Generating-Reports#Choose-where-the-report-is-written> describes. If both are set, the static variable wins. The runner creates the folder.

Swift Testing runs the tests of a process side by side, in no order that you can rely on. The report still holds every scenario once, with the features in the order of their feature files, and each feature's scenarios in the order of their lines, as CucumberSwift's report does. It's the same report, with the same keys, for the same feature files, and it validates against Cucumber's JSON schema.

A feature's `uri` is the `file://` URL of its feature file in the test bundle, as CucumberSwift writes it, even though the runner reads the feature files when the tests build. If the test bundle has no copy, as when a Swift package leaves the `Features` folder out, the URL points where the copy would be, in the bundle's `Features` folder. A hook's or an observer's `Feature.uri` is the same URL. Failures are still reported in the feature file you edit, so that Xcode shows them there.

When the tests finish, the runner copies the report to `CucumberTestResultsFor<target>.json` in the documents folder, and replaces the copy from the run before, as CucumberSwift does. So the script in <doc:Generating-Reports#Automatic-reports> finds it.

These rules also apply to the report:

- **A test run replaces the report.** One process runs a test target's tests, so each run starts a report of its own. Two test targets that run in one `xcodebuild` or `swift test` run write to the same path, one after the other. If you need both reports, give each target its own `CUCUMBER_REPORT_PATH`.
- **A step is `failed` when its step definition throws, when no step definition matches it, and when one of its step hooks throws.** Its `error_message` is the error. An ambiguous step is `ambiguous`. The steps after a failed one aren't in the report, as with CucumberSwift.
- **A failed `#expect` fails its step in the report too, with Swift 6.2 or later.** Swift Testing doesn't tell the running code when an expectation fails. The runner learns of it from the same issue handling that moves the issue to the feature file's line. With Swift 6.1, such a step is reported as `passed`, though Swift Testing still fails the test. A step that throws, with `try #require` or otherwise, is `failed` in every version.

**Verbose output.** The runner prints the lines that <doc:Verbose-Output> shows, with the same three switches: `Cucumber.verboseOutput`, `StepImplementation.verbose` and the environment variable `CUCUMBER_VERBOSE`, set to `1` or `true`. Any one of them turns it on:

```swift
extension Cucumber: @retroactive StepImplementation {
    public var verbose: Bool { true }
    public func setupSteps() { /* Your steps */ }
}
```

**Custom reporters.** Write a `CucumberTestObserver` and hand it to the runner with `CucumberTestObservable`, as <doc:Generating-Reports#Custom-reporters> shows for CucumberSwift:

```swift
final class MyTestObserver: CucumberTestObserver {
    func testSuiteStarted(at date: Date) {}
    func testSuiteFinished(at date: Date) {}
    func didStart(feature: Feature, at date: Date) {}
    func didStart(scenario: Scenario, at date: Date) {}
    func didStart(step: Step, at date: Date) {}
    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
}

extension Cucumber: @retroactive CucumberTestObservable {
    public var observers: [CucumberTestObserver] { [MyTestObserver()] }
}
```

The `Feature`, `Scenario` and `Step` that an observer receives are this runner's own, the ones that step definitions and hooks see. `Reporter.Result` is the same type. The runner calls observers on the main actor, in the order things happen:

- The test suite starts before the first scenario, and finishes after the last.
- A feature starts with its first scenario that runs, after its `BeforeFeature` hooks. It finishes after its last scenario and its `AfterFeature` hooks. If `CUCUMBER_TAGS` filters out all of a feature's scenarios, the feature doesn't start.
- A scenario starts before its hooks, and finishes after its `AfterScenario` hooks. It finishes `.failed` if a step or a hook failed.
- A step starts before its `BeforeStep` hooks, and finishes before its `AfterStep` hooks run, as in CucumberSwift. So an `AfterStep` hook that fails fails the scenario, not the step that the observers were told about.

A step with no step definition finishes `.failed`, with the message that the runner records. An ambiguous step finishes `.ambiguous`. The events of one scenario arrive in order. Don't assume anything about the order of events from different scenarios.

## Write features in Swift

CucumberSwift's DSL lets you write a feature in Swift, in `setupSteps()`. The DSL has `Feature`, `Scenario`, `ScenarioOutline`, `Background`, `Rule` and `Description`.

> Note: Prefer feature files whenever you can. Product owners, testers and developers can all read and write them, and the plugin checks them when the tests build. Use the DSL only where a feature is better written in code, as an imperative take on Gherkin.

The DSL comes in two styles. Keep to one style in a test target. Mixing the styles works, but the code is harder to read.

- **DSL macros.** The macros, such as `#Feature`, `#Scenario` and `#Given(I: openTheShop())`, need the Macros trait and `CucumberSwiftTestingMacros`. The compiler writes each step's text into the test, so the text is the same wherever the tests run. Use the macros whenever you can.
- **DSL functions.** The functions, such as `Feature`, `Scenario` and `Given(I: openTheShop())`, work as they do in CucumberSwift. The runner reads each step's text from the Swift file when the tests run. On a device, or from an archived test bundle, the steps have no text.

@TabNavigator {
@Tab("DSL macros") {
```swift
import CucumberSwiftTestingMacros
import Testing

func openTheShop() {}
@MainActor func addCukes(_ count: Int) { Basket.shared.add(count) }
func payAtTheTill() async throws {}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Feature("Checkout") {
            #Background {
                #Given(I: openTheShop())
            }
            #Scenario("Buy cukes") {
                #When(I: addCukes(2))
                #Then(I: payAtTheTill)
                #And(the: { #expect(Basket.shared.count == 2) })
            }
        }
    }
}
```
}
@Tab("DSL functions") {
```swift
import CucumberSwiftTesting
import Testing

func openTheShop() {}
@MainActor func addCukes(_ count: Int) { Basket.shared.add(count) }
func payAtTheTill() async throws {}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Feature("Checkout") {
            Background {
                Given(I: openTheShop())
            }
            Scenario("Buy cukes") {
                When(I: addCukes(2))
                Then(I: payAtTheTill)
                And(the: { #expect(Basket.shared.count == 2) })
            }
        }
    }
}
```
}
}

A step definition, such as `#Given("I do X") { }`, matches a step of a feature file, so it belongs in `setupSteps()`. A DSL step, such as `#Given(I: addCukes(2))`, is the code a scenario runs, so it belongs in a scenario. Writing either one where the other belongs is an error. The macros report it when the code compiles, and `CucumberSwiftLint` reports it when the target builds. With the functions, the test run also fails at the line of each misplaced step. <doc:Checking-Feature-Files#What-it-checks> shows each error and how to fix it.

A DSL step takes a call, such as `addCukes(2)`, an async function, such as `payAtTheTill`, or a closure. You choose its label from `I:`, `it:`, `my:`, `some:`, `a:` and `the:`. The step's text is the label and the code after it, as written, such as `I: addCukes(2)`. A macro reads each line break in a step written over several lines as a space.

Hooks, tags, `CUCUMBER_TAGS`, `shouldRunWith(scenario:tags:)`, the report and verbose output treat these scenarios as they treat a feature file's scenarios. Each feature ends after its last scenario. A step definition that matches a step's text runs instead of the step, as it does in CucumberSwift. Call `continueAfterFailure(false)` on a step, such as `#Then(the: check).continueAfterFailure(false)`, to cancel an async step at its first failed expectation.

Features written in the DSL run as one test of the generated suite, named **Swift DSL features**, because the plugin can't read them when the tests build. The test has a case for each step, or for each scenario with `Cucumber.oneTestPerScenario`. Each case is named after the feature, the scenario and the step, such as `Checkout › Buy cukes › 2 › When I: addCukes(2)`.

The plugin adds the test when one of the test target's Swift files calls `Feature`. If `setupSteps()` writes features that the test doesn't run, such as features from another module, the run fails and says so.

With parallel testing on, each scenario is one case, and scenarios run at the same time, as a feature file's scenarios do. Set `Cucumber.parallelTestingUnit` to `.feature` to run one feature at a time. A failure appears in the Swift file, at the step's line, as it does in CucumberSwift.

## Move unit tests to Swift Testing

A project can move its unit tests to Swift Testing and keep its UI tests on CucumberSwift and XCTest, because UI tests can't move. Each test target links one runner:

| Test target | Product | Runs feature files with |
|---|---|---|
| UI tests | `CucumberSwift` | XCTest, as before |
| Unit tests | `CucumberSwiftTestingMacros` (or `CucumberSwiftTesting`) and `CucumberSwiftTestingPlugin` | Swift Testing |

One scheme can test both targets. To move a unit test target:

1. Replace its `CucumberSwift` or `CucumberSwiftMacros` dependency with `CucumberSwiftTestingMacros`, or with `CucumberSwiftTesting` without the macros, and add the plugin, as in <doc:#Set-up-a-Swift-package> or <doc:#Set-up-an-Xcode-project>.
2. In its step definitions, import that module instead of `CucumberSwift` or `CucumberSwiftMacros`. Mark the conformance `@retroactive`, and remove `bundle`, because this runner doesn't use it. Otherwise, step definitions written as macros or with the plain DSL stay as they are, and so do features written in the Swift DSL. If you filter scenarios in code, declare `shouldRunWith(scenario:tags:)`. This runner calls only that one, so it ignores an older `shouldRunWith(tags:)`, and every scenario runs.
3. Replace each `XCTAssert` with `#expect`, or with `try #require` where the step must stop at once. A failed `#expect` lets its step run to the end, as <doc:#After-a-failed-assertion> describes.
4. Check <doc:#Differences-from-the-XCTest-runner> and <doc:Settings#Settings-that-work-differently> for what differs.

**Sharing step definitions between the runners.** A step definition file that both targets compile needs a different `import` in each, and assertions that both runners report. Before Swift 6.4, neither runner sees the other's assertions. Swift Testing ignores a failed `XCTAssert`, and CucumberSwift's XCTest runner ignores a failed `#expect`, so in either case the step passes. A failed `try #require` throws, and both runners fail a step that throws, on its line in the feature file. Keep the step definitions for UI tests and for unit tests apart where you can, because they usually do different things.

## Differences from the XCTest runner

The Swift Testing runner does everything the XCTest runner does, with these exceptions:

1. **No UI testing.** Swift Testing doesn't support `XCUIApplication`, so you can use it only for unit tests. This is a known limitation of Swift Testing that Apple describes in [Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/).
2. **`continueTestingAfterFailure`.** This is the setting for fail-fast mode. By default, it's `true`, and both runners let a step run to its end after a failed assertion. Return `false` to fail fast. XCTest then stops the step at its first failed assertion. Swift Testing can't stop the step's code part way at a failed `#expect`. So check `continueTestingAfterFailure` in the step. Use `#expect` when it's `true`, and `try #require` when it's `false`, because it stops the step at once. See <doc:#After-a-failed-assertion>.

   ```swift
   import CucumberSwiftTestingMacros
   import Testing

   extension Cucumber: @retroactive StepImplementation {
       // false: fail fast, stopping a step at its first failed assertion.
       public var continueTestingAfterFailure: Bool { false }

       public func setupSteps() {
           #Then("the basket has {int} cukes") { (count: Int) in
               if self.continueTestingAfterFailure {
                   // Keeps going after a failure, as XCTest does with the flag on.
                   #expect(Basket.shared.count == count)
               } else {
                   // Stops the step at once, as XCTest does with the flag off.
                   try #require(Basket.shared.count == count)
               }
           }
       }
   }
   ```

3. **`parallelTesting` and shared state.** XCTest runs parallel tests in separate processes, so their state is isolated. Swift Testing runs them in one process, so scenarios can see each other's state. Parallel testing works with both runners, and you turn it on the same way. Use `Scenario.state(_:)` to share state between steps and to keep it apart between scenarios. It works the same with both runners. See <doc:#Sharing-state-between-steps-in-a-scenario>.

   ```swift
   import CucumberSwiftTestingMacros
   import Testing

   final class Cart {
       var cukes = 0
   }

   enum Shop {
       // A concurrency-safe container for this scenario's state.
       static var cart: Cart { Scenario.state(Cart.init) }
   }

   extension Cucumber: @retroactive StepImplementation {
       public func setupSteps() {
           #Given("I add {int} cukes to my cart") { (count: Int) in
               // Writes to this scenario's cart.
               Shop.cart.cukes += count
           }
           #Then("my cart has {int} cukes") { (count: Int) in
               // Reads the same cart, not another scenario's.
               #expect(Shop.cart.cukes == count)
           }
       }
   }
   ```

   The container is safe to use from any task of the step. The value you keep in it isn't made safe for you. Steps run on the main actor, so a plain class works. If you pass the value to other tasks, make it `Sendable`, for example an `actor`.

4. **The Info.plist keys `FeaturesPath` and `FeatureScenarioDelimiter`.** The plugin finds the feature files in the test target's folder, whatever `FeaturesPath` says. The runner reads `FeaturesPath` only to map the files to the bundled files for the report's URIs. It doesn't read `FeatureScenarioDelimiter`. Support for both is planned ([#462](https://github.com/cucumberswift/CucumberSwift/issues/462)).

<doc:Settings#Settings-that-work-differently> has more on the settings. <doc:#Requirements> lists the Swift version limits.

### Use Swift Testing's own tools

`Cucumber.expectation(description:)` and `wait(for:timeout:)` work in this runner as they do with CucumberSwift. In a step definition that you write for this runner, you can use Swift Testing's own tools for the same job instead. Make the step `async`, then use these tools:

- To wait for something, `await` an `async` API. A callback wrapped in `withCheckedContinuation` doesn't stop waiting when the step is cancelled. If the callback never comes, the run waits for it, even with `asyncStepTimeout`.
- To check that something happens, and how many times, use `confirmation(_:expectedCount:)`. It fails the step if the confirmation is confirmed a different number of times before its closure returns.

<!-- swift-example: file swift6 -->
```swift
import CucumberSwiftTestingMacros
import Foundation
import Testing

@MainActor
final class Checkout {
    static let shared = Checkout()
    var onOrderPlaced: (() -> Void)?

    func placeOrder() async -> Bool {
        onOrderPlaced?()
        return true
    }
}

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        // Was: let placed = expectation(description: "placed"), then wait(for: [placed], timeout: 5)
        #When("I place the order") { () async in
            await confirmation("the order is placed") { orderPlaced in
                Checkout.shared.onOrderPlaced = { orderPlaced() }
                let succeeded = await Checkout.shared.placeOrder()
                #expect(succeeded)
            }
        }
    }
}
```

A step or a hook that suspends for longer than `asyncStepTimeout` is cancelled and fails on its line in the feature file, if what it awaits ends when it's cancelled. See <doc:#Step-and-hook-options>.

Feature files in any language still work, because their steps match by their text. The runner suggests Cucumber expressions for undefined steps, unless `Cucumber.generateRegexLiterals` asks for regex literals. It suggests step definition macros when the target links `CucumberSwiftTestingMacros`.
