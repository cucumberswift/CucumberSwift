# Running Feature Files with Swift Testing

Run your feature files with Swift Testing in a unit test target, with the step definitions you already have.

## Overview

CucumberSwift runs feature files with XCTest. In a unit test target, you can run them with Swift Testing instead. A build tool plugin reads the target's feature files when it builds, and generates a Swift Testing test for each scenario:

- a suite for each feature,
- a test for each Scenario,
- a parameterized test for each Scenario Outline, with one test case for each row of its Examples tables.

Xcode's test navigator shows every feature and scenario before anything runs, and you can run a single scenario from Xcode, with `swift test --filter`, or with `xcodebuild -only-testing`.

Step definitions are written as for CucumberSwift: `extension Cucumber: StepImplementation`, `setupSteps()`, `Given`, `When`, `Then`, `And`, `But` and `MatchAll`, and the step definition macros. Backgrounds, Rules, Scenario Outlines, tags and `CUCUMBER_TAGS`, doc strings, data tables, scenario and step hooks, and feature files in other languages work as they do with CucumberSwift.

## Requirements

- **Swift 6.1 (Xcode 16.3) or later, and Swift Package Manager.** The runner is the `CucumberSwiftTesting` product, and the plugin is `CucumberSwiftTestingPlugin`. Carthage can't deliver a build tool plugin.
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
        .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.4.0", traits: ["Macros"])
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

The macros need the trait, which downloads swift-syntax. To write step definitions without them, leave the trait off and depend on `CucumberSwiftTesting` instead; see <doc:#Without-the-macros>.

## Set up an Xcode project

1. Add the CucumberSwift package to the project, turn on its `Macros` trait in the package dependency's settings, and add `CucumberSwiftTestingMacros` to your unit test target. Setting a package dependency's traits in an Xcode project needs Xcode 26.4 or later. With an earlier Xcode, turn the trait on from a local package that re-exports `CucumberSwiftTestingMacros`, as <doc:Checking-Step-Definitions#Use-the-macros-in-an-Xcode-project-before-Xcode-264> describes, and keep CucumberSwift in the project for the plugins; or add `CucumberSwiftTesting` and write step definitions without the macros.
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

<doc:Checking-Step-Definitions> describes the macros in full: the argument each parameter gives, the mistakes the compiler reports, and the fixes Xcode offers. They work the same with this runner, apart from the localized macros, such as `#ES_Dado`, which it doesn't have.

A step definition can be synchronous or `async`, and it runs on the main actor. It takes a Cucumber expression, a string that starts with `^` or ends with `$` for a regular expression, or a regex literal. The `Step` has the step's `match`, `keyword`, `docString`, `dataTable`, `tags` and `scenario`, as with CucumberSwift.

`BeforeScenario`, `AfterScenario`, `BeforeStep` and `AfterStep` take an optional `priority`, as with CucumberSwift: hooks with a priority run first, lowest first.

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

Each scenario's test is named after its title, as CucumberSwift names the tests it generates: the scenario "Pay with a gift card" in the feature "Checkout" is `CucumberFeatures/Checkout/PayWithAGiftCard()`.

```bash
swift test --filter PayWithAGiftCard
xcodebuild test -scheme MyApp -only-testing:'MyAppTests/CucumberFeatures/Checkout/PayWithAGiftCard()'
```

A Scenario Outline is one test, and each example is one of its test cases, named as CucumberSwift names the example's scenario. Xcode can run a single example from the test navigator, but `xcodebuild -only-testing` can only select the whole outline: given a test case, it runs nothing, and still succeeds.

`CUCUMBER_TAGS` works as it does with CucumberSwift: a comma-separated list of regular expressions, and a scenario runs when any of its tags matches any of them. The other scenarios are reported as skipped. An outline whose examples are all left out runs no test cases, which Swift Testing reports as a pass.

Scenarios run one at a time, as with CucumberSwift, because step definitions usually share state.

The test navigator lists the scenarios that Xcode found when it last indexed the target, and it doesn't always index again when only a feature file changes. Editing a scenario's steps or examples keeps its results on its row. A scenario you add or rename runs with the others, and shows in the test report, but its row in the navigator can wait until Xcode indexes the target again, for example after you build it or reopen the project.

## How failures are reported

- A step that no step definition matches fails on its line in the feature file, and the message includes a step definition to paste into `setupSteps()`.
- A step that more than one step definition matches fails on its line in the feature file, and none of them runs.
- A step definition, or a step hook, that throws fails on the step's line in the feature file. A scenario hook that throws fails on the scenario's line.

In each case the scenario's later steps don't run, and its `AfterScenario` hooks still do.

A failed `#expect`, or any other issue recorded while a step or a hook runs, is reported on the step's line in the feature file, or the scenario's for a scenario hook, as CucumberSwift reports a failed XCTest assertion. Its message says where it was recorded, such as `Recorded at StepDefinitions.swift:31`. The scenario goes on after a failed `#expect`. This needs Swift 6.2 or later; with Swift 6.1, a failed `#expect` is reported where you wrote it.

## Move unit tests to Swift Testing

A project can move its unit tests to Swift Testing and keep its UI tests, which can't move, on CucumberSwift and XCTest. Each test target links one runner:

| Test target | Product | Runs feature files with |
|---|---|---|
| UI tests | `CucumberSwift` | XCTest, as before |
| Unit tests | `CucumberSwiftTestingMacros` (or `CucumberSwiftTesting`) and `CucumberSwiftTestingPlugin` | Swift Testing |

One scheme can test both targets. To move a unit test target:

1. Replace its `CucumberSwift` or `CucumberSwiftMacros` dependency with `CucumberSwiftTestingMacros`, or with `CucumberSwiftTesting` without the macros, and add the plugin, as in <doc:#Set-up-a-Swift-package> or <doc:#Set-up-an-Xcode-project>.
2. In its step definitions, import that module instead of `CucumberSwift` or `CucumberSwiftMacros`, mark the conformance `@retroactive`, and remove `bundle`, which this runner doesn't use. Step definitions written as macros, or with the plain DSL, otherwise stay as they are.
3. Replace each `XCTAssert` with `#expect`, or with `try #require` where the step can't go on.
4. Remove anything listed in <doc:#What-isnt-available>.

**Sharing step definitions between the runners.** A step definition file that both targets compile needs a different `import` in each, and assertions that both runners report. Before Swift 6.4, neither runner sees the other's: Swift Testing ignores a failed `XCTAssert`, and CucumberSwift's XCTest runner ignores a failed `#expect`, so in either case the step passes. A failed `try #require` throws, and both runners fail a step that throws, on its line in the feature file. Keep the step definitions for UI tests and for unit tests apart where you can: they usually do different things.

## What isn't available

These parts of CucumberSwift have no counterpart in this runner: `BeforeFeature` and `AfterFeature`, `shouldRunWith(scenario:tags:)`, verbose output and the JSON report, `ExecuteFirstStep`, `Attach`, and the localized step types such as `ES_Dado`. Feature files in any language still work: their steps match by their text.
