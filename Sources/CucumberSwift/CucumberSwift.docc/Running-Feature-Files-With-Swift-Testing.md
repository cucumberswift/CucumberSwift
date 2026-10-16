# Running Feature Files with Swift Testing

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

Run your feature files with Swift Testing in a unit test target, with the step definitions you already have.

## Overview

CucumberSwift runs feature files with XCTest. In a unit test target, you can run them with Swift Testing instead. A build tool plugin reads the target's feature files when it builds, and generates a Swift Testing test for each scenario:

- a suite for each feature,
- a test for each Scenario,
- a parameterized test for each Scenario Outline, with one test case for each row of its Examples tables.

Xcode's test navigator shows every feature and scenario before anything runs, and you can run a single scenario from Xcode, with `swift test --filter`, or with `xcodebuild -only-testing`.

Step definitions are written as for CucumberSwift: `extension Cucumber: StepImplementation`, `setupSteps()`, `Given`, `When`, `Then`, `And`, `But` and `MatchAll`, and the step definition macros. Backgrounds, Rules, Scenario Outlines, tags and `CUCUMBER_TAGS`, doc strings, data tables, scenario and step hooks, and feature files in other languages work as they do with CucumberSwift.

## Requirements

- **Swift 6.1 (Xcode 16.3) or later, and Swift Package Manager.** The runner is the `CucumberSwiftTesting` product, and the plugin is `CucumberSwiftTestingPlugin`. Carthage can't deliver a build tool plugin. <doc:Running-Tests-In-Xcode#CucumberSwiftTestingPlugin> covers the plugin alongside CucumberSwift's others.
- **Unit test targets only.** Xcode doesn't allow Swift Testing in UI test targets. UI tests keep running their feature files with CucumberSwift and XCTest.
- **`#expect` and `#require`, not `XCTAssert`.** Before Swift 6.4, Swift Testing ignores an XCTest assertion that fails inside one of its tests, so the scenario would pass. Step definitions that this runner runs must use Swift Testing's expectations.
- **One runner per test target.** Link either `CucumberSwift` or `CucumberSwiftTesting` to a test target, not both. They have their own `Cucumber`, `Given` and the rest, with the same names, so a file can't import both. In a target that links both, each runner runs every scenario with its own step definitions, and CucumberSwift fails the test run if it isn't set up too. A project can use both, in different targets: see <doc:#Move-unit-tests-to-Swift-Testing>.

## Set up a Swift package

Turn on CucumberSwift's `Macros` trait, add `CucumberSwiftTestingMacros` to the test target, and apply the two plugins to it: `CucumberSwiftTestingPlugin`, which generates the tests, and `CucumberSwiftLint`, which checks the feature files and step definitions, as it does with the XCTest runner:

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

The plugin finds every `.feature` file in the target's folder. `CucumberSwiftTestingMacros` has the step definition macros, and imports `CucumberSwiftTesting`, the runner, too.

The macros need the trait, which downloads swift-syntax. Before Swift 6.4, SwiftPM also needs swift-syntax declared next to CucumberSwift to resolve the trait, as above: see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>. To write step definitions without them, leave the trait off and depend on `CucumberSwiftTesting` instead; see <doc:#Without-the-macros>.

## Set up an Xcode project

1. Add the CucumberSwift package to the project, turn on its `Macros` trait in the package dependency's settings, add the swift-syntax package to the project as <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64> describes, and add `CucumberSwiftTestingMacros` to your unit test target. Setting a package dependency's traits in an Xcode project needs Xcode 26.4 or later. With an earlier Xcode, add a local package that only turns the trait on, as <doc:Using-Step-Definition-Macros#Before-Xcode-264> describes, and add `CucumberSwiftTestingMacros` from CucumberSwift as above; or add `CucumberSwiftTesting` and write step definitions without the macros.
2. In the test target's **Build Phases**, add `CucumberSwiftTestingPlugin` and `CucumberSwiftLint` under **Run Build Tool Plug-ins**. Xcode asks you to trust the plugins the first time they run; on a CI machine, pass `-skipPackagePluginValidation` to `xcodebuild` instead.
3. Add your `Features` folder to the test target, for example as a folder reference in **Copy Bundle Resources**. The plugin only sees files that belong to the target.

## Write step definitions

Register step definitions in `setupSteps()`, as with CucumberSwift, and write them with the step definition macros, `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`. The compiler checks each expression against its closure: one argument for each parameter, of the parameter's type, and optionally the `Step` last. Because `Cucumber` and `StepImplementation` both come from `CucumberSwiftTesting`, Swift 6 asks you to mark the conformance `@retroactive`:

```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        BeforeScenario { _ in
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

<doc:Using-Step-Definition-Macros> describes the macros in full, with the argument each parameter gives, and <doc:Checking-Step-Definitions> the mistakes the compiler reports and the fixes Xcode offers. They work the same with this runner, apart from the localized macros, such as `#ES_Dado`, which are only in `CucumberSwiftMacros`, not in `CucumberSwiftTestingMacros`.

A step definition can be synchronous or `async`, and it runs on the main actor. It takes a Cucumber expression, or a string that starts with `^` or ends with `$`, or is written between `/`, for a regular expression. It can also take a regex literal, such as `#/…/#`, with the step functions and with the macros (see <doc:Using-Step-Definition-Macros#Regex-literals>), which needs iOS 16, macOS 13 or tvOS 16 at run time. The `Step` has the step's `match`, `keyword`, `docString`, `dataTable`, `tags` and `scenario`, as with CucumberSwift.

`BeforeFeature`, `AfterFeature`, `BeforeScenario`, `AfterScenario`, `BeforeStep` and `AfterStep` take an optional `priority`, as with CucumberSwift: hooks with a priority run first, lowest first.

### Feature hooks

`BeforeFeature` runs once, before the first scenario of a feature, and `AfterFeature` once, after its last. Each takes the `Feature`:

```swift
import CucumberSwiftTesting
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        BeforeFeature { feature in
            // Once for "\(feature.title)", before its first scenario.
            Basket.shared.add(10)
        }
        AfterFeature { _ in
            Basket.shared.empty()
        }
    }
}
```

They run once for each feature, around all of its scenarios, even when Swift Testing runs the feature's scenarios at the same time: the scenarios wait for `BeforeFeature` to finish. The tests that CucumberSwiftTestingPlugin generates mark where each feature ends. They need Swift 6.1, the runner's minimum.

As with CucumberSwift, `BeforeFeature` hooks run before the observers hear that the feature started, and `AfterFeature` hooks before they hear that it finished. A feature none of whose scenarios run, because `CUCUMBER_TAGS` filters them out, runs neither. A feature hook that throws fails at the line where you wrote it, and the feature's scenarios still run.

### Attachments

`Attach` adds an attachment, such as a log or a file, to the test that is running. Call it from any hook or step, as with CucumberSwift. It takes a Swift Testing `Attachment`, where CucumberSwift takes an `XCTAttachment`:

```swift
import CucumberSwiftTesting
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        Then("I save the basket") { _, _ in
            #if compiler(>=6.2)
            Attach(Attachment("\(Basket.shared.count) cukes", named: "basket.txt"))
            #endif
        }
    }
}
```

Xcode's test report shows the attachment under the scenario, and `swift test --attachments-path` writes it to a folder. An attachment added in `AfterFeature` is under the feature. The JSON report doesn't have attachments, as with CucumberSwift. `Attach` needs Swift 6.2, the first with attachments in Swift Testing. With Swift 6.1 it's unavailable: calling it is a compile error, so no attachment is lost without your noticing. To keep supporting Swift 6.1, put the call between `#if compiler(>=6.2)` and `#endif`, as the example does. 

### Without the macros

Each macro expands to a step definition you can also write yourself, with `Given`, `When`, `Then`, `And`, `But` or `MatchAll` and a closure that takes the `Match` and the `Step`:

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

This needs no package trait, and so works in an Xcode project with any supported Xcode. You can mix both styles in one target.

## Run scenarios

Each scenario's test is named after its title in camel case: the scenario "Pay with a gift card" in the feature "Checkout" is `CucumberFeatures/Checkout/PayWithAGiftCard()`. That is how CucumberSwift names the tests it generates with `Cucumber.readableTestNames` off, and this runner doesn't have that setting: the name is always camel case. Xcode's test navigator and test reports show the titles as you wrote them, such as "Pay with a gift card", and a repeated name gets `_2`, `_3` and so on.

```bash
swift test --filter PayWithAGiftCard
xcodebuild test -scheme MyApp -only-testing:'MyAppTests/CucumberFeatures/Checkout/PayWithAGiftCard()'
```

A Scenario Outline is one test, and each example is one of its test cases, named after the line of its row, such as `Example (line 17)`, so that its results stay on its row when you change a value. Xcode can run a single example from the test navigator, but `xcodebuild -only-testing` can only select the whole outline: given a test case, it runs nothing, and still succeeds.

`CUCUMBER_TAGS` works as it does with CucumberSwift: a comma-separated list of regular expressions, and a scenario runs when any of its tags matches any of them. The other scenarios are reported as skipped. An outline whose examples are all left out runs no test cases, which Swift Testing reports as a pass.

Scenarios run one at a time, as with CucumberSwift, because step definitions usually share state. That applies to the scenarios: your target's other Swift Testing tests aren't held back by it, and can run alongside them.

### Check the feature files

Besides the scenarios, the runner adds one test, `CucumberFeatures/gherkin()`, shown as "Feature files are valid Gherkin". It fails, with an issue on the file, for each problem the Gherkin parser finds in the target's feature files, and passes when there is none.

The test navigator lists the scenarios that Xcode found when it last indexed the target, and it doesn't always index again when only a feature file changes. Editing a scenario's steps or examples keeps its results on its row. A scenario you add or rename runs with the others, and shows in the test report, but its row in the navigator can wait until Xcode indexes the target again, for example after you build it or reopen the project.

## How failures are reported

- A step that no step definition matches fails on its line in the feature file, and the message includes a step definition to paste into `setupSteps()`.
- A step that more than one step definition matches fails on its line in the feature file, and none of them runs.
- A step definition that throws fails on the step's line in the feature file. A hook that throws fails at the line where you wrote the hook, as with CucumberSwift.

In each case the scenario's later steps don't run, and its `AfterScenario` hooks still do. A `BeforeStep` hook that throws also skips its step, and the step's `AfterStep` hooks still run.

A hook that throws doesn't stop the hooks after it of the same kind, as with CucumberSwift. A feature is `failed` in the report when one of its steps is, not when a hook is.

A step that never finishes holds up the run: the runner has no timeout for an async step, as CucumberSwift's `asyncStepTimeout` gives.

A failed `#expect`, or any other issue recorded while a step or a hook runs, is reported on the step's line in the feature file, or the scenario's for a scenario hook. Its message gives the step as it ran, with an example's values, such as `Then the basket has 3 cukes`, and where it was recorded, such as `Recorded at StepDefinitions.swift:31`. A step definition that throws gets the step in its message too. This needs Swift 6.2 or later; with Swift 6.1, a failed `#expect` is reported where you wrote it.

### Stop at the first failed assertion

The runner keeps Swift Testing's own rules, which differ from XCTest's. A scenario is one test, so:

- **`#expect` and `Issue.record` don't stop anything.** They fail the test, and the rest of the step, and the scenario's later steps, still run. This is what `#expect` does in every Swift version, and what XCTest does by default for an assertion inside a step, where `continueTestingAfterFailure` is on.
- **`try #require`, or any error a step throws, stops the step and the scenario.** The scenario's later steps don't run and aren't in the report, its `AfterScenario` and `AfterStep` hooks still do, and the step is reported `failed`. Use it where CucumberSwift would have `continueTestingAfterFailure` return `false`, or where the next step can't make sense after this one failed.

CucumberSwift skips the later steps of a scenario after any failed assertion, because each step is a test of its own. If a step definition you move to this runner relied on that, change its `#expect` to `try #require`: see <doc:#Move-unit-tests-to-Swift-Testing>.

## Reports, verbose output and custom reporters

The runner writes the Cucumber JSON report, prints verbose output and tells your own reporters what it sees, with the same settings, the same report and the same `CucumberTestObserver` as CucumberSwift.

**The JSON report.** The report is written as scenarios finish, to `_cucumberReport.json` in the documents folder. Set `Cucumber.reportPath` in `setupSteps()`, or the environment variable `CUCUMBER_REPORT_PATH`, to a full path to write it somewhere else, as <doc:Generating-Reports#Choose-where-the-report-is-written> describes. The static variable wins when both are set, and the runner creates the folder.

Swift Testing runs the tests of a process side by side, in no order you can rely on. The report holds every scenario once, with the features in the order of their feature files and each feature's scenarios in the order of their lines, as CucumberSwift's does. It is the same report, with the same keys, for the same feature files, and it validates against Cucumber's JSON schema. Two things differ: a feature's `uri` is the path of its feature file on the Mac that built the tests, as a `file://` URL, where CucumberSwift's is the path inside the test bundle; and the runner doesn't copy the report when the test bundle finishes, as CucumberSwift does to `CucumberTestResultsFor<target>.json`.

- **A test run replaces the report.** One process runs a test target's tests, so each run starts a report of its own. Two test targets that run in one `xcodebuild` or `swift test` run write to the same path one after the other: give each its own `CUCUMBER_REPORT_PATH` if you need both.
- **A step is `failed` when its step definition throws, when no step definition matches it, and when one of its step hooks throws.** Its `error_message` is the error. An ambiguous step is `ambiguous`. The steps after a failed one aren't in the report, as with CucumberSwift.
- **A failed `#expect` fails its step in the report too, with Swift 6.2 or later.** Swift Testing doesn't tell the code that is running when an expectation fails, so the runner learns of it from the same issue handling that moves the issue to the feature file's line. With Swift 6.1 such a step is reported as `passed`, though Swift Testing still fails the test; a step that throws, with `try #require` or otherwise, is `failed` in every version.

**Verbose output.** It prints the lines <doc:Verbose-Output> shows, with the same three switches: `Cucumber.verboseOutput`, `StepImplementation.verbose` and the environment variable `CUCUMBER_VERBOSE`, which takes `1` or `true`. Any one of them turns it on.

```swift
extension Cucumber: @retroactive StepImplementation {
    public var verbose: Bool { true }
    public func setupSteps() { /* Your steps */ }
}
```

**Custom reporters.** Write a `CucumberTestObserver` and hand it to the runner with `CucumberTestObservable`, as <doc:Generating-Reports#Custom-Reporters> shows for CucumberSwift:

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

The `Feature`, `Scenario` and `Step` an observer receives are this runner's own, the ones step definitions and hooks see; `Reporter.Result` is the same type. The runner calls observers on the main actor, in the order things happen:

- the test suite starts before the first scenario, and finishes after the last,
- a feature starts with its first scenario that runs, after its `BeforeFeature` hooks, and finishes after its last and its `AfterFeature` hooks: a feature none of whose scenarios run, because `CUCUMBER_TAGS` filters them out, doesn't start,
- a scenario starts before its hooks, and finishes after its `AfterScenario` hooks, `.failed` if a step or a hook failed, and
- a step starts before its `BeforeStep` hooks, and finishes after its `AfterStep` hooks.

A step with no step definition finishes `.failed`, with the message the runner records, and an ambiguous step finishes `.ambiguous`. The events of one scenario arrive in order; don't assume anything about the order of events from different scenarios.

## Move unit tests to Swift Testing

A project can move its unit tests to Swift Testing and keep its UI tests, which can't move, on CucumberSwift and XCTest. Each test target links one runner:

| Test target | Product | Runs feature files with |
|---|---|---|
| UI tests | `CucumberSwift` | XCTest, as before |
| Unit tests | `CucumberSwiftTestingMacros` (or `CucumberSwiftTesting`) and `CucumberSwiftTestingPlugin` | Swift Testing |

One scheme can test both targets. To move a unit test target:

1. Replace its `CucumberSwift` or `CucumberSwiftMacros` dependency with `CucumberSwiftTestingMacros`, or with `CucumberSwiftTesting` without the macros, and add the plugin, as in <doc:#Set-up-a-Swift-package> or <doc:#Set-up-an-Xcode-project>.
2. In its step definitions, import that module instead of `CucumberSwift` or `CucumberSwiftMacros`, mark the conformance `@retroactive`, and remove `bundle`, which this runner doesn't use. Step definitions written as macros, or with the plain DSL, otherwise stay as they are.
3. Replace each `XCTAssert` with `#expect`, or with `try #require` where the step can't go on: a failed `#expect` doesn't stop the scenario, as <doc:#Stop-at-the-first-failed-assertion> describes.
4. Remove anything listed in <doc:#What-isnt-available>.

**Sharing step definitions between the runners.** A step definition file that both targets compile needs a different `import` in each, and assertions that both runners report. Before Swift 6.4, neither runner sees the other's: Swift Testing ignores a failed `XCTAssert`, and CucumberSwift's XCTest runner ignores a failed `#expect`, so in either case the step passes. A failed `try #require` throws, and both runners fail a step that throws, on its line in the feature file. Keep the step definitions for UI tests and for unit tests apart where you can: they usually do different things.

## What isn't available

These parts of CucumberSwift have no counterpart in this runner:

- the Swift DSL for writing features: `Feature`, `Scenario`, `Given(I:)` and the rest,
- `ExecuteFirstStep`,
- the `StepImplementation` properties: `shouldRunWith(scenario:tags:)`, `continueTestingAfterFailure`, `reverseOrderForAfterHooks`, `asyncStepTimeout` and `regexLiteralStyle`,
- the `Cucumber` settings, such as `readableTestNames`: the runner reads only `CUCUMBER_TAGS`, `CUCUMBER_REPORT_PATH` and `CUCUMBER_VERBOSE`, with `Cucumber.reportPath` and `Cucumber.verboseOutput`, as <doc:Settings> describes,
- `Cucumber.expectation(description:)` and `wait(for:timeout:)`,
- step definitions that take `[String]`, the deprecated regular expression API, and
- the localized step types such as `ES_Dado`.

Feature files in any language still work: their steps match by their text. The step definitions the runner suggests for undefined steps are always Cucumber expressions.
