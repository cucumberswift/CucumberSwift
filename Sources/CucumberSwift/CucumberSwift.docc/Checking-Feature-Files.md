# Checking Feature Files While You Build

See mistakes in your feature files as warnings in Xcode, before you run a single test.

## Overview

Without it, you find a mistake in a feature file only when the tests run: a misspelt keyword, a table row with a cell too many, a doc string that never closes, or a step that no step definition matches. The `CucumberSwiftLint` build tool plugin checks every `.feature` file in a target each time you build it, and reports each problem as a warning on the line it was found on. Xcode shows the warnings in the editor and in the Issue navigator, as it does for Swift.

![A feature file in Xcode with four warnings shown inline: an undefined step on line 8, the misspelt keyword "Thne" on line 12, a table row with one cell too many on line 21, and a doc string that is never closed on line 25.](CheckingFeatureFiles-Warnings.png)

The plugin only reports warnings. It never fails a build, and it changes nothing about how the tests run.

It needs CucumberSwift added with Swift Package Manager, and Xcode 16.0 or later. Carthage can't deliver Swift package plugins.

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

### Keep it on in CI

Leave the plugin on for every build, on your Mac and in CI. It only reports warnings and never fails a build, so a CI build that compiles your tests checks every feature file too, and its log lists each problem as `file:line:column: warning: …`, which Xcode Cloud and most CI services show with the build's other warnings. On a CI machine, pass `-skipPackagePluginValidation` to `xcodebuild`, as above.

### What it checks

In feature files:

- **Keywords.** In English only: text where a step should be, and a word that looks like a misspelt keyword (`Thne`, `Gvien`, `feature:`, `Scenario` without its colon), with a suggestion. Suggestions cover the step keywords, `Feature:`, `Background:`, `Scenario:` and `Examples:`, but not `Rule:`. In a scenario, the usual message for a misspelt step keyword is "Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Then'?".
- **Structure.** A step outside a scenario or background, a step after `Examples`, and `Examples` outside a scenario.
- **Tables.** A row with a different number of cells from the first row of its table, and a table that doesn't follow a step or `Examples`.
- **Doc strings.** A doc string that doesn't follow a step, or is never closed.

A feature file in another language has a comment such as `# language: fr`. The plugin reads its headers and steps with that language's keywords, as CucumberSwift does, and checks everything except keywords: it says nothing about a line it can't read as a header or a step. CucumberSwift and the plugin both honour the comment on any line, from that line on, so put it on the first line. If CucumberSwift doesn't support the language, the plugin warns on the comment, and reads on in the language it was reading before, as CucumberSwift does.

Against the target's step definitions:

- **Undefined steps.** A step that none of the target's step definitions matches. Each step of a `Scenario Outline` is checked with the values from its `Examples` filled in.
- **Step definitions that can never match.** A string pattern that starts with `^`, ends with `$` or is written between `/`, but isn't a valid regular expression, or a regex literal that doesn't compile. The warning is on the step definition's line.

### Fix misspelt keywords

When the plugin suggests a keyword, as in "Did you mean 'Then'?", the **Fix Feature Files** command makes the change for you. It applies every such suggestion in your feature files at once, and changes nothing else.

![A feature file in Xcode with seven warnings that each suggest a keyword: "feture", "Scenario Outline" without its colon, "Gvien", "Wehn", "Thne", "scenario" in lowercase, and "Adn".](FixFeatureFiles-Before.png)

In Xcode, right-click the project or package in the Project navigator, and choose **Fix Feature Files** under CucumberSwift:

![The Project navigator's shortcut menu for a project, with Fix Feature Files in its CucumberSwift section.](FixFeatureFiles-Menu.png)

Then choose the targets whose feature files to fix, and click **Run**:

![The Fix Feature Files dialog, listing the project's test target, with Cancel and Run buttons.](FixFeatureFiles-Dialog.png)

The command fixes each keyword, and the warnings are gone after the next build:

![The same feature file after the command, with Feature, Scenario Outline, Given, When, Then, Scenario and And spelt correctly, and no warnings.](FixFeatureFiles-After.png)

In Terminal, run `swift package fix-feature-files` in the package's folder. Without `--target`, it fixes the feature files in the folders of every target of the package. Add `--target MyAppTests` to fix only the feature files in that target's folder, the same files the build plugin checks.

The command needs permission to change files in your project or package. Xcode asks before it runs, and you can tell it not to ask again. `swift package` asks in Terminal, or you can pass `--allow-writing-to-package-directory`.

It lists each line it changed, before and after, with the file's absolute path:

```
/Users/me/MyApp/Tests/MyAppTests/Features/Login.feature:12: Thne the user is signed in → Then the user is signed in
Fixed 1 line in 1 of 4 feature files.
```

Fixing a line can turn the lines after it into steps, which the plugin checks more closely, so the command checks each file again and applies any new suggestion until nothing is left to fix. Text between a header and its first step is a description, where any text is allowed, so the command fixes a line there only when the line after it is a step, a table or a doc string. A line it leaves keeps its warning, for you to fix or ignore. A file with nothing to fix is left exactly as it was. If a file can't be read or saved, for example because it is read-only, the command names it and fails. Other warnings, such as an undefined step or a table row with a cell too many, are still yours to fix.

The command only needs CucumberSwift added with Swift Package Manager; the build plugin doesn't have to be added to a target.

### Know its limits

The plugin reads your step definitions from the Swift files in the target. It finds the step definitions written with `Given`, `When`, `Then`, `And`, `But` and `MatchAll`, with the step classes such as `GivenStep`, with the localized step functions such as `FR_Soit`, and with the macros such as `#Given` and `#FR_Soit`, whose pattern is written in place: a string literal, `#/…/#` or `/…/`. So:

- A pattern built at run time, or a string with interpolation, is invisible to it. A step that only such a pattern matches is reported as undefined.
- A custom parameter type is registered at run time, so the plugin treats it as matching anything.
- If the target has no step definitions at all, for example because they are in another module, the plugin doesn't check for undefined steps.
- It doesn't take a step definition's keyword into account: a `Given` definition matches a `Then` step.

These give wrong results:

- A step definition that is commented out counts as defined.
- A raw string (`#"…"#`), a multi-line string and a multi-line regex literal aren't read, so a step that only they match is reported as undefined.
- A modifier on a pattern, such as `.ignoresCase()`, is ignored: the plugin checks the pattern as written.
- When only some of your step definitions are in the target, and the rest are in another module, the steps those match are reported as undefined.

For the full rules on how steps match step definitions, see <doc:Matching-Steps>.
