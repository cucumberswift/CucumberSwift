# Checking Feature Files While You Build

See mistakes in your feature files as warnings in Xcode, before you run a single test.

## Overview

Without it, you find a mistake in a feature file only when the tests run: a misspelt keyword, a table row with a cell too many, a doc string that never closes, or a step that no step definition matches. The `CucumberSwiftLint` build tool plugin checks every `.feature` file in a target each time you build it, and reports each problem as a warning on the line it was found on. Xcode shows the warnings in the editor and in the Issue navigator, as it does for Swift.

![A feature file in Xcode with four warnings shown inline: an undefined step on line 8, the misspelt keyword "Thne" on line 12, a table row with one cell too many on line 21, and a doc string that is never closed on line 25.](CheckingFeatureFiles-Warnings.png)

The plugin only reports warnings. It never fails a build, and it changes nothing about how the tests run.

It needs CucumberSwift added with Swift Package Manager, and Xcode 14 or later. Carthage can't deliver Swift package plugins.

### Add the plugin to a Swift package

Add the plugin to the test target that has the feature files:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["CucumberSwift"],
    resources: [.copy("Features")],
    plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")]
)
```

### Add the plugin to an Xcode project

1. Select the project in the Project navigator, then the test target.
2. Open **Build Phases**, and expand **Run Build Tool Plug-ins**.
3. Click **+** and choose **CucumberSwiftLint**.

The plugin checks the `.feature` files in the target, including those in a folder reference such as `Features`.

### Trust the plugin

The first time Xcode builds a target that uses a package plugin, it asks you to trust it. Choose **Trust & Enable**. On a CI machine, where nobody can answer, pass `-skipPackagePluginValidation` to `xcodebuild`. `swift build` and `swift test` don't ask.

### What it checks

In every feature file:

- **Keywords.** Text where a step should be, and a word that looks like a misspelt keyword (`Thne`, `Gvien`, `Scenario` without its colon), with a suggestion.
- **Structure.** A step outside a scenario or background, a step after `Examples`, and `Examples` outside a scenario.
- **Tables.** A row with a different number of cells from the first row of its table, and a table that doesn't follow a step or `Examples`.
- **Doc strings.** A doc string that doesn't follow a step, or is never closed.

In a feature file whose first line sets another language (`# language: fr`), it checks only tables and doc strings.

Against the target's step definitions:

- **Undefined steps.** A step that none of the target's step definitions matches. Each step of a `Scenario Outline` is checked with the values from its `Examples` filled in.
- **Step definitions that can never match.** A string pattern that starts with `^` or ends with `$` but isn't a valid regular expression, or a regex literal that doesn't compile. The warning is on the step definition's line.

### Know its limits

The plugin reads your step definitions from the Swift files in the target. It finds `Given`, `When`, `Then`, `And`, `But` and `MatchAll` calls whose pattern is written in place: a string literal, `#/…/#` or `/…/`. So:

- A pattern built at run time, or a string with interpolation, is invisible to it. A step that only such a pattern matches is reported as undefined.
- A custom parameter type is registered at run time, so the plugin treats it as matching anything.
- If the target has no step definitions at all, for example because they are in another module, the plugin doesn't check for undefined steps.
- It doesn't take a step definition's keyword into account: a `Given` definition matches a `Then` step.

For the full rules on how steps match step definitions, see <doc:Matching-Steps>.
