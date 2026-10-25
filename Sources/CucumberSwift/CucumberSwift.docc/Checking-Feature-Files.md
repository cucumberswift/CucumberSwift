# Checking feature files while you build

See mistakes in your feature files as warnings in Xcode, before you run a single test.

## Overview

The `CucumberSwiftLint` build tool plugin checks every `.feature` file in a target each time you build it. It reports each problem as a warning on the line where it found it, and Xcode shows those warnings in the editor and the Issue navigator. The plugin finds misspelt keywords, table rows with too many cells, doc strings that never close, and steps that no step definition matches. Without the plugin, you find these mistakes only when the tests run.

![A feature file in Xcode with four warnings shown inline: an undefined step on line 8, the misspelt keyword "Thne" on line 12, a table row with one cell too many on line 21, and a doc string that is never closed on line 25.](CheckingFeatureFiles-Warnings.png)

The plugin's warnings never fail a build, and the plugin changes nothing about how the tests run. A step in the wrong place in a feature written in the Swift DSL is the one exception. That is an error that fails the build, as <doc:#What-it-checks> explains.

The plugin needs CucumberSwift added with Swift Package Manager, and Xcode 16.0 or later. Carthage can't deliver Swift package plugins.

### Add the plugin to a Swift package

To use the plugin in a Swift package, add it to the test target that has the feature files:

<!-- swift-example: package-target -->
```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["CucumberSwift"],
    resources: [.copy("Features")],
    plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")]
)
```

### Add the plugin to an Xcode project

To use the plugin in an Xcode project, add it to the test target's build phases:

1. Select the project in the Project navigator, then the test target.
2. Open **Build Phases**, and expand **Run Build Tool Plug-ins**.
3. Click **+** and choose **CucumberSwiftLint**.

![The Build Phases tab of a test target, with Run Build Tool Plug-ins expanded and listing CucumberSwiftLint (CucumberSwift).](BuildToolPlugins-BuildPhases.png)

The plugin then checks the `.feature` files in the target, including those in a folder reference such as `Features`.

In a project that Tuist generates, add `.package(product: "CucumberSwiftLint", type: .plugin)` to the test target's `dependencies`. Tuist then adds the plugin to **Run Build Tool Plug-ins**.

### Trust the plugin

Xcode asks you to trust a package plugin the first time it builds a target that uses the plugin. The build stops with an error saying that the plugin must be enabled before it can be used. Xcode doesn't open a dialog by itself. Click the error in the Issue navigator, choose **Trust & Enable**, and build again.

![Xcode's dialog: Plugin "CucumberSwiftLintPlugin" from package "CucumberSwift" must be enabled before it can be used. Enable it now? With Trust & Enable and Cancel buttons.](BuildToolPlugins-Trust.png)

The Issue navigator may also show a warning that the macro "CucumberSwiftMacrosPlugin" must be enabled. The warning appears even when your project doesn't use the macros, because the macros come in the same package. The build still succeeds. To clear the warning, click it and choose **Trust & Enable**. Xcode asks once for each project.

Nobody can answer Xcode on a CI machine, so pass `-skipPackagePluginValidation` to `xcodebuild` there. `swift build` and `swift test` don't ask.

### Keep it on in CI

Leave the plugin on for every build, on your Mac and in CI. The plugin's warnings never fail a build, so a CI build that compiles your tests also checks every feature file. The build log lists each problem as `file:line:column: warning: …`. Xcode Cloud and most CI services show these lines with the build's other warnings. On a CI machine, pass `-skipPackagePluginValidation` to `xcodebuild` (see <doc:Checking-Feature-Files#Trust-the-plugin>).

### What it checks

The plugin checks the structure of each feature file and warns about these problems:

- **Misspelt keywords.** The plugin warns about text where a step should be, and about a word that looks like a misspelt keyword, such as `Thne`, `Gvien`, `feature:` or `Scenario` without its colon. Each warning suggests the keyword you probably meant. The plugin suggests the step keywords, `Feature:`, `Background:`, `Scenario:` and `Examples:`, but not `Rule:`, and it checks keywords in English only. For a misspelt step keyword in a scenario, the warning usually reads "Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Then'?"
- **Misplaced steps and examples.** The plugin warns about a step outside a scenario or background, a step after `Examples`, and `Examples` outside a scenario.
- **Malformed tables.** The plugin warns about a row whose number of cells differs from the first row of its table, and about a table that doesn't follow a step or `Examples`.
- **Malformed doc strings.** The plugin warns about a doc string that doesn't follow a step, and about one that is never closed.

A feature file in another language names its language in a comment, such as `# language: fr`. The plugin reads that file's headers and steps with the language's keywords, as CucumberSwift does. It checks everything except keywords, so it says nothing about a line it can't read as a header or a step. CucumberSwift and the plugin both apply the comment from its own line onwards, so put it on the first line. If CucumberSwift doesn't support the language, the plugin warns about the comment and keeps reading in the language it was reading before, as CucumberSwift does.

The plugin also checks the feature files against the target's step definitions, and warns about these problems:

- **Undefined steps.** The plugin warns about a step that none of the target's step definitions matches. It checks each step of a `Scenario Outline` with the values from its `Examples` filled in.
- **Step definitions that can never match.** The plugin warns about a string pattern that starts with `^`, ends with `$` or is written between slashes but isn't a valid regular expression, and about a regex literal that doesn't compile. The warning appears on the step definition's line.

> Note: CucumberSwift supports two ways to write a feature. The recommended declarative way is a feature file. Its steps describe the behaviour in Gherkin, and step definitions in `setupSteps()` match them. The imperative way is a feature written in the Swift DSL, whose steps are the code they run. Write each feature one way only. A step of one kind written inside the other is an error that fails the build.

The plugin reports one of two errors when a target mixes the two ways, and the build fails. With the macros, the compiler also reports them.

#### A declarative step definition inside an imperative DSL function call

The plugin reports an error when a step definition is written inside a `Feature`, `Scenario`, `Background`, `ScenarioOutline` or `Rule`. A step definition matches a step of a feature file, so it belongs in `setupSteps()`, outside any feature. To fix the error, move the step definition out of the feature, or replace it with a DSL step.

@TabNavigator {
@Tab("DSL macros") {
##### Incorrect

<!-- swift-example: fragment: a compile error, on purpose: a step definition inside a scenario -->
```swift
public func setupSteps() {
    #Feature("Checkout") {
        #Scenario("Buy cukes") {
            // error: a step definition inside a feature
            #Given("I have {int} cukes") { (count: Int) in }
            #When(I: checkOut())
        }
    }
}
```

##### Correct

Declarative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Recommended: the declarative style.
    #Given("I have {int} cukes") { (count: Int) in }
}
```

Imperative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Supported, but discouraged: the imperative style.
    #Feature("Checkout") {
        #Scenario("Buy cukes") {
            #Given(I: addCukes(2))
            #When(I: checkOut())
        }
    }
}
```
}
@Tab("DSL functions") {
##### Incorrect

<!-- swift-example: members -->
```swift
public func setupSteps() {
    Feature("Checkout") {
        Scenario("Buy cukes") {
            // error: a step definition inside a feature
            Given("I have {int} cukes") { _, _ in }
            When(I: checkOut())
        }
    }
}
```

##### Correct

Declarative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Recommended: the declarative style.
    Given("I have {int} cukes") { _, _ in }
}
```

Imperative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Supported, but discouraged: the imperative style.
    Feature("Checkout") {
        Scenario("Buy cukes") {
            Given(I: addCukes(2))
            When(I: checkOut())
        }
    }
}
```
}
}

#### An imperative DSL function call inside a declarative feature's step definitions

The plugin reports an error when a DSL step is written outside a `Scenario`, `Background`, `ScenarioOutline` or a function marked `@StepBuilder`, such as among the step definitions in `setupSteps()`. A DSL step is the code a DSL scenario runs, so it belongs in a scenario. To fix the error, replace the DSL step with a step definition that matches a step of a feature file, or move it into a scenario. The plugin recognizes a DSL step by its label: `I:`, `it:`, `my:`, `some:`, `a:` or `the:`.

@TabNavigator {
@Tab("DSL macros") {
##### Incorrect

<!-- swift-example: fragment: a compile error, on purpose: a DSL step outside a scenario -->
```swift
public func setupSteps() {
    #Given("I have {int} cukes") { (count: Int) in }
    // error: a DSL step outside a scenario
    #When(I: checkOut())
}
```

##### Correct

Declarative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Recommended: the declarative style.
    #Given("I have {int} cukes") { (count: Int) in }
    #When("I check out") { checkOut() }
}
```

Imperative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Supported, but discouraged: the imperative style.
    #Feature("Checkout") {
        #Scenario("Check out") {
            #When(I: checkOut())
        }
    }
}
```
}
@Tab("DSL functions") {
##### Incorrect

<!-- swift-example: members -->
```swift
public func setupSteps() {
    Given("I have {int} cukes") { _, _ in }
    // error: a DSL step outside a scenario
    When(I: checkOut())
}
```

##### Correct

Declarative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Recommended: the declarative style.
    Given("I have {int} cukes") { _, _ in }
    When("I check out") { _, _ in checkOut() }
}
```

Imperative:

<!-- swift-example: members -->
```swift
public func setupSteps() {
    // Supported, but discouraged: the imperative style.
    Feature("Checkout") {
        Scenario("Check out") {
            When(I: checkOut())
        }
    }
}
```
}
}

### Fix misspelt keywords

The **Fix Feature Files** command applies the keywords that the plugin suggests, such as the one in "Did you mean 'Then'?". The command applies every suggestion in your feature files at once, and changes nothing else.

![A feature file in Xcode with seven warnings that each suggest a keyword: "feture", "Scenario Outline" without its colon, "Gvien", "Wehn", "Thne", "scenario" in lowercase, and "Adn".](FixFeatureFiles-Before.png)

In Xcode, right-click the project or package in the Project navigator, and choose **Fix Feature Files** under CucumberSwift:

![The Project navigator's shortcut menu for a project, with Fix Feature Files in its CucumberSwift section.](FixFeatureFiles-Menu.png)

Then choose the targets whose feature files to fix, and click **Run**:

![The Fix Feature Files dialog, listing the project's test target, with Cancel and Run buttons.](FixFeatureFiles-Dialog.png)

The command fixes each keyword, and the warnings are gone after the next build:

![The same feature file after the command, with Feature, Scenario Outline, Given, When, Then, Scenario and And spelt correctly, and no warnings.](FixFeatureFiles-After.png)

In Terminal, run `swift package fix-feature-files` in the package's folder. Without `--target`, it fixes the feature files in the folders of every target of the package. Add `--target MyAppTests` to fix only the feature files in that target's folder, the same files the build plugin checks.

The command needs permission to change files in your project or package. Xcode asks before it runs, and you can tell it not to ask again. `swift package` asks in Terminal, or you can pass `--allow-writing-to-package-directory`.

The command lists each line it changed, before and after, with the file's absolute path:

```
/Users/me/MyApp/Tests/MyAppTests/Features/Login.feature:12: Thne the user is signed in → Then the user is signed in
Fixed 1 line in 1 of 4 feature files.
```

Fixing a line can turn the lines after it into steps that the plugin checks more closely. The command therefore checks each file again, and applies new suggestions until nothing is left to fix.

Text between a header and its first step is a description, where any text is allowed. The command fixes a line in a description only when the next line is a step, a table or a doc string. A line that the command doesn't fix keeps its warning, for you to fix or ignore.

The command leaves a file with nothing to fix exactly as it was. If the command can't read or save a file, for example because the file is read-only, it names the file and fails. The command fixes keywords only. Other warnings, such as an undefined step or a table row with too many cells, are still yours to fix.

The command needs CucumberSwift added with Swift Package Manager. You don't need to add the build plugin to a target to use the command.

### Know its limits

The plugin reads your step definitions from the Swift files in the target. It finds step definitions written with `Given`, `When`, `Then`, `And`, `But` and `MatchAll`. It also finds the step classes, such as `GivenStep`, the localized step functions, such as `FR_Soit`, and the macros, such as `#Given` and `#FR_Soit`. The plugin reads a pattern only when it is written in place, as a string literal, `#/…/#` or `/…/`.

As a result, the plugin has these limits:

- The plugin can't see a pattern built at run time, or a string with interpolation. It reports a step that only such a pattern matches as undefined.
- A custom parameter type is registered at run time, so the plugin treats it as matching anything.
- If the target has no step definitions at all, for example because they are in another module, the plugin doesn't check for undefined steps.
- The plugin ignores a step definition's keyword, so a `Given` definition matches a `Then` step.

The plugin also gives wrong results in these cases:

- The plugin doesn't read a raw string (`#"…"#`), a multi-line string or a multi-line regex literal. It reports a step that only these patterns match as undefined.
- The plugin ignores a modifier on a pattern, such as `.ignoresCase()`, and checks the pattern as written.
- When only some of your step definitions are in the target, and the rest are in another module, the plugin reports the steps that the other module's definitions match as undefined.

For the full rules on how steps match step definitions, see <doc:Matching-Steps>.
