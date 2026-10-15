# Running Tests in Xcode

Set up Xcode for CucumberSwift, use its plugins to check and fix your feature files and step definitions, and run your scenarios.

## Overview

This article explains how to set up an Xcode project for CucumberSwift, use its plugins, and run your scenarios in Xcode and in CI.

The plugins are optional, and you can add them whenever they help, for example once your project has more than a few feature files. They check your feature files while you build, fix misspelt keywords, convert step definitions to macros, and run feature files with Swift Testing.

## Set up Xcode for CucumberSwift

This section explains how to add CucumberSwift to an Xcode project, and the one-time settings to make. To run scenarios, you only need to add CucumberSwift and turn off parallel testing; the rest is optional.

### Add CucumberSwift to your project

Add the CucumberSwift package to your project with **File > Add Package Dependencies…**, and add the `CucumberSwift` library to your test target. <doc:SPM-Step-By-Step> walks through it, with a `Features` folder, a first feature file and its step definitions. <doc:Matching-Steps> has every way to match a step.

Add it with Swift Package Manager to get the plugins. With Carthage, your tests run the same, but Carthage can't deliver Swift package plugins.

### Turn off parallel testing

Xcode turns parallel testing on for new test targets, and by default CucumberSwift's scenarios don't run correctly in parallel. Choose **Product > Test Plan > Edit Test Plan**, select **Options…** next to your test target, and set **Parallelization** to **Disabled**. Leave **Automatically include new tests** on: CucumberSwift creates its tests while they run. <doc:SPM-Step-By-Step> shows the setting, and <doc:Running-Scenarios-In-Parallel> describes an experiment that lets Xcode hand each scenario to one worker.

### Choose the plugins

CucumberSwift comes with four Swift package plugins of two kinds: two run by themselves, and you run the other two.

- **Build tool plugins run by themselves.** `CucumberSwiftLint` and `CucumberSwiftTestingPlugin` run on every build of a target you add them to. You add each one to a target yourself, because Xcode doesn't let a package apply a plugin to your targets.
- **Command plugins run only when you choose them.** Fix Feature Files and Convert to Gherkin Macros are commands on the project's menu as soon as the package is added, and they never run on a build.

| Plugin | Kind: when it runs | What it does | What you do | Needs |
|---|---|---|---|---|
| `CucumberSwiftLint` | Build tool plugin: on every build of a target you add it to | Checks feature files and step definitions | Add it to each test target with feature files (recommended) | Xcode 16.0 |
| `CucumberSwiftTestingPlugin` | Build tool plugin: on every build of a target you add it to | Generates Swift Testing tests from feature files | Add it to a target that runs feature files with Swift Testing | Xcode 16.3 |
| Command: Fix Feature Files | Command plugin: only when you choose it | Fixes misspelt keywords in feature files | Choose it on the project's menu when you want it | Xcode 16.0 |
| Command: Convert to Gherkin Macros | Command plugin: only when you choose it | Rewrites step definitions as step definition macros | Choose it on the project's menu when you want it | Xcode 16.3 and the `Macros` trait |

Xcode 16.0 to 16.2 read a manifest without `CucumberSwiftTestingPlugin` and Convert to Gherkin Macros, so they don't appear there.

<doc:Checking-Feature-Files> explains how to add `CucumberSwiftLint` to a test target, what it checks, and how to fix what it finds with **Fix Feature Files**.

### Trust the plugins

The first time Xcode builds a target that uses a package plugin, the build stops with an error saying the plugin must be enabled before it can be used. Xcode doesn't open a dialog by itself: click the error in the Issue navigator, and choose **Trust & Enable**. Then build again.

![Xcode's dialog: Plugin "CucumberSwiftLintPlugin" from package "CucumberSwift" must be enabled before it can be used. Enable it now? With Trust & Enable and Cancel buttons.](BuildToolPlugins-Trust.png)

Macros, such as the step definition macros, need the same. Until you enable them, the Issue navigator shows a warning that the macro must be enabled, and each macro in your code shows an error that its implementation could not be found. Click the warning, and choose **Trust & Enable**: the errors go.

![Xcode after converting step definitions, before the macros are enabled. The Issue navigator shows, outlined in red, the warning: Macro "CucumberSwiftMacrosPlugin" from package "CucumberSwift" must be enabled before it can be used in support of editor functionality. Each of #Given, #When and #Then shows the error: External macro implementation type 'CucumberSwiftMacrosPlugin.StepDefinitionMacro' could not be found.](ConvertToGherkinMacros-EnableMacros.png)

![Xcode's dialog: Macro "CucumberSwiftMacrosPlugin" from package "CucumberSwift" must be enabled before it can be used. Enable it now? With Trust & Enable and Cancel buttons.](ConvertToGherkinMacros-TrustMacros.png)

`swift build` and `swift test` don't ask. On a CI machine, where nobody can answer, pass `-skipPackagePluginValidation` and `-skipMacroValidation` to `xcodebuild` instead.

A command plugin asks instead for permission to change files in your project each time you run it, and you can tell Xcode not to ask again.

### Highlight feature files

Xcode shows `.feature` files as plain text. CucumberSwift comes with a Gherkin grammar for Xcode that colors keywords, tags, comments, strings, doc strings, `<placeholders>`, table separators and numbers. Only English keywords are colored. It also comes with code snippets for a feature, a scenario and a scenario outline. You install both with a script you run once. They are not part of the library, and the script changes nothing in Xcode itself: it copies files into your home folder.

![A feature file in Xcode with Gherkin highlighting: the tags, comment, and keywords such as Feature, Background, Scenario Outline, Given, When, Then and Examples are colored, as are the <placeholders>, the string, the table separators and the numbers.](HighlightFeatureFiles.png)

It relies on how Xcode loads grammars and plug-ins, which Apple doesn't document, so a future version of Xcode could stop highlighting your feature files. Your tests are not affected either way.

To install it, run the script from a copy of the CucumberSwift repository:

```bash
git clone --depth 1 https://github.com/cucumberswift/CucumberSwift.git
CucumberSwift/Tools/Xcode/gherkin-highlighting.sh install
```

Then quit and reopen Xcode. Xcode asks whether to load an unexpected code bundle, the Gherkin plug-in, which contains only data and no code; choose **Load Bundle**. Xcode asks again after each Xcode update.

Feature files then open as Gherkin: in the File inspector (View ▸ Inspectors ▸ File), their type is **Default - Gherkin Query Document**. A feature file Xcode has already opened before keeps the type it had, Default - Plain Text. Set it once: select the file, and in the File inspector choose **Gherkin Query Document** as its type, then close the file and open it again.

You can also choose Gherkin for the open file under Editor ▸ Syntax Coloring.

To add a snippet, open the Library in a feature file (View ▸ Show Library, or ⇧⌘L), search for `Gherkin`, and double-click the snippet or drag it into the file. Press Tab to move between its placeholders. Xcode doesn't offer code completion in feature files, so the snippets' completion shortcuts don't work there.

The script installs these items:

- `~/Library/Developer/Xcode/Plug-ins/Gherkin.ideplugin`, which tells Xcode that `.feature` files are Gherkin
- `~/Library/Developer/Xcode/Specifications/Gherkin.xclangspec`, the grammar
- three snippets in `~/Library/Developer/Xcode/UserData/CodeSnippets`

To remove them, run the script with `uninstall`, then quit and reopen Xcode. To see which of them are installed, run it with `status`: it lists each item as installed or not, and changes nothing.

```bash
CucumberSwift/Tools/Xcode/gherkin-highlighting.sh uninstall
CucumberSwift/Tools/Xcode/gherkin-highlighting.sh status
```

## Convert to Gherkin Macros

This section shows you how to rewrite your existing step definitions as step definition macros, with the **Convert to Gherkin Macros** command.

A project that already has step definitions written as ``Given`` and the like can have them rewritten as macros. The **Convert to Gherkin Macros** command changes only the step definitions it can convert exactly, and marks and lists each one it leaves, with the reason. It needs the `Macros` trait on for CucumberSwift: see <doc:Checking-Step-Definitions#Add-the-macros-to-your-package>.

Here are step definitions written without macros:

![Step definitions in Xcode before the command: Given, When and Then, each with a closure that reads its parameters from match, and a last Then that passes match to print.](ConvertToGherkinMacros-Before.png)

In Xcode, right-click the project or package in the Project navigator, and choose **Convert to Gherkin Macros** under CucumberSwift:

![The Project navigator's shortcut menu for a project, with Convert to Gherkin Macros and Fix Feature Files in its CucumberSwift section.](ConvertToGherkinMacros-Menu.png)

Choose the targets whose Swift files to convert, and click **Run**:

![The Convert to Gherkin Macros dialog, listing the project and its test target, with Cancel and Run buttons.](ConvertToGherkinMacros-Dialog.png)

Xcode asks for permission to change files in your project. Choose **Allow Command to Change Files**, or select **Don't ask again** first:

![Xcode's alert: 'Convert to Gherkin Macros' wants to change files in your project, with the command's reason, a Don't ask again checkbox, and Allow Command to Change Files, Show Command and Cancel buttons.](ConvertToGherkinMacros-Permission.png)

The command rewrites each step definition it can. Each closure takes the pattern's parameters as typed arguments, and the one it leaves has a `#warning` saying why:

![The same step definitions after the command: #Given, #When and #Then with typed arguments, such as (number: Int), and a #warning before the last Then: Convert to Gherkin Macros by hand: it passes match on to other code.](ConvertToGherkinMacros-After.png)

The first time you build the converted code, enable the macros, as in <doc:Running-Tests-In-Xcode#Trust-the-plugins>.

In Terminal, run `swift package convert-to-gherkin-macros` in the package's folder. Without `--target`, it converts the Swift files in the folders of every target of the package. Add `--target MyAppTests` to convert one target's, and `--dry-run` to report what it would do without changing a file. The command needs permission to change files in your project or package: Xcode asks before it runs, and `swift package` asks in Terminal, or you can pass `--allow-writing-to-package-directory`. It first checks that your project is set up for the macros.

It converts the step definitions of every macro keyword, including localized ones such as ``ES_Dado``, written with a trailing closure or with `callback:`, and with a pattern written as a string literal, with or without `as CucumberExpression`, which the macro adds itself, or as a regex literal. A step definition is converted when its closure reads each parameter from `match` in its first statements, in the pattern's order, as `let count = try match.first(\.int)` or `let count: Int = match[\.int, index: 0]`, and uses `match` for nothing else. Those statements become the closure's arguments, and the macro expands to the same step definition as before. A type you wrote on a read stays; otherwise the argument gets the type the pattern gives. Comments, formatting, a capture list, `async`, `throws` and other attributes stay as they are, and the command adds `import CucumberSwiftMacros` (or `CucumberSwiftTestingMacros`) when the file doesn't import it.

### Before it changes anything

The command checks your project's setup first, and changes nothing until the project is ready:

- **The `Macros` trait must be on for CucumberSwift.** The command reads and writes Swift code with swift-syntax, which only comes with the trait, so with the trait off it can't run. It stops, and its message is the first thing you see: the exact change for the kind of project it finds, whether a Swift package (the trait on the dependency, with `swift-tools-version` 6.1 or later), a Tuist project (`Project.swift`), or an Xcode project (the package's trait setting with Xcode 26.4 or later, or the local `MacrosTrait` package before it). When it can't tell which, it lists them all.
- **Each target it converts must depend on the macros product.** A target that depends on `CucumberSwift` but not on `CucumberSwiftMacros`, or on `CucumberSwiftTesting` but not on `CucumberSwiftTestingMacros`, stops the command, which names the target and says what to add. The converted step definitions couldn't compile without it.

It never edits `Package.swift`, `Project.swift` or the Xcode project: turning the trait on and adding the product are your changes, once, as in <doc:Checking-Step-Definitions#Add-the-macros-to-your-package>. When it stops for either reason, it exits with an error, so a script can tell.

In each file it converts, it imports the macros module for you: `CucumberSwiftMacros` after the file's import of `CucumberSwift`, or `CucumberSwiftTestingMacros` after its import of `CucumberSwiftTesting`. It keeps the import of the runner, which the macros module re-exports, and adds nothing to a file that imports the macros module already.

### Converting regex literals

A step definition with a regex literal, `#/…/#` or `/…/`, keeps it: the macros take it as it is (see <doc:Checking-Step-Definitions#Regex-literals>), so the step matches exactly the steps it matched before. Its closure reads each capture group in its first statements, in any order, by number or by a named group's name, as `let count = match.1`, `let city: Substring = match.output.2` or `let city = match.city`, and those statements become the closure's arguments. Each argument gets the capture's type in the regex's `Output`, `Substring`, or `Substring?` for a group that may not take part in the match, and a group the closure doesn't read becomes an argument named `_`:

<!-- swift-example: steps -->
```swift
// Before
Given(#/^I have (\d+) cukes( today)?$/#) { match, _ in
    let count = match.1
    basket.add(Int(count) ?? 0, to: "basket")
}

// After
#Given(#/^I have (\d+) cukes( today)?$/#) { (count: Substring, _: Substring?) in
    basket.add(Int(count) ?? 0, to: "basket")
}
```

A regex literal needs iOS 16, macOS 13 or tvOS 16 with or without the macros, so the code around it already has the `@available` that the macro needs. A regex with syntax that changes how its groups are numbered or what captures, such as `(?|…)` or the `n` and `x` options, is left as it is, because the command can't give each capture group its type.

### What it leaves

It leaves a step definition unchanged, and lists it with its reason, when:

- its closure passes `match` on to other code, reads `match.allParameters`, or reads a parameter after other code;
- it reads parameters in an order other than the pattern's, or reads a parameter type the pattern has once by position, or one it has more than once with `first`;
- its pattern is not a string literal or a regex literal, has a mistake the macro would report, or is a regex literal whose capture groups the command can't read;
- its closure is the deprecated `[String]` closure, uses `$0` and `$1`, or is a function or a selector;
- it declares a type other than the one the pattern gives, a capture group's included, or doesn't read a custom parameter type, so the macro's closure couldn't be given its type;
- the file declares a function, variable, type or parameter with the keyword's name where the call is, so the call may not be a step definition;
- the file imports neither CucumberSwift nor CucumberSwiftTesting, or both, or uses a localized step definition with CucumberSwiftTesting, which has no localized macros.

It puts a `#warning` before each one that stands alone as a statement, so the compiler points to it in Xcode's issue navigator and in the build output, and you can convert it by hand:

<!-- swift-example: steps -->
```swift
#warning("Convert to Gherkin Macros by hand: it passes match on to other code")
When("I pass match on") { match, _ in
    print(match)
}
```

Running the command again doesn't add a second warning, and a warning goes when you delete it. If your build treats warnings as errors, convert or delete these first. A call that may not be a step definition, because the file declares something with the keyword's name, gets no warning.

It prints a line for each step definition it found, with the file's absolute path and line, and a total:

```
/Users/me/MyApp/Tests/MyAppTests/Steps.swift:7: converted Given("I have {int} cukes in my {string}")
/Users/me/MyApp/Tests/MyAppTests/Steps.swift:12: left unchanged When("I pass match on"): it passes match on to other code
Converted 1 step definition in 1 of 4 Swift files. Left 1 unchanged, 1 marked with #warning.
```

Review the result with your version control before you commit it, and build your tests: a macro reports a mistake the original only found when the tests ran.

## CucumberSwiftTestingPlugin

This section explains how to run your feature files with Swift Testing, with the `CucumberSwiftTestingPlugin` build tool plugin.

`CucumberSwiftTestingPlugin` runs your feature files with Swift Testing instead of XCTest, in a unit test target. Each time the target builds, it reads the target's `.feature` files and generates a Swift Testing test for each scenario, which the `CucumberSwiftTesting` runner runs. It needs Xcode 16.3 (Swift 6.1) or later. It doesn't need the `Macros` trait, though the runner's step definition macros do.

In an Xcode project, select the test target, open **Build Phases**, expand **Run Build Tool Plug-ins**, click **+** and choose **CucumberSwiftTestingPlugin**, and add your `Features` folder to the target. In a Swift package, add `.plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift")` to the test target's `plugins`. In a project that Tuist generates, add `.package(product: "CucumberSwiftTestingPlugin", type: .plugin)` to its `dependencies`. Keep `CucumberSwiftLint` on the target too: it checks the same feature files, as <doc:Checking-Feature-Files> describes.

The tests need the plugin: without it there are none to run. <doc:Running-Feature-Files-With-Swift-Testing> sets up the runner, and says how to write step definitions for it and run its scenarios.

## Run the tests

This section explains how your scenarios appear in Xcode, and how to choose and run them.

Press ⌘U to run the tests. CucumberSwift reads your feature files when the test bundle starts and creates the tests then, so Xcode's test navigator shows them only after the first run. By default, each scenario becomes a test class named after its feature and scenario, such as `Checkout › Pay with a gift card`, and each of its steps becomes a test in that class, such as `3 › Then the order total is 99`. The steps are numbered so that they run in the order of the feature file. The test navigator lists a class's failed tests first, and then the most recently run first, so read the numbers for the order.

Settings change how your tests are named and laid out. You set each one with a static variable on `Cucumber` in your `StepImplementation`'s `setupSteps()`, or with an environment variable in a scheme or test plan. <doc:Settings> lists every setting.

### Choose a test per step or one test per scenario

CucumberSwift can lay out a scenario's tests in two ways. You choose; a test per step is the default.

| | A test per step (default) | One test per scenario |
|---|---|---|
| In the test navigator | A class per scenario, such as `Checkout › Pay with a gift card`, with a test for each step | One test per scenario, such as `Checkout › Pay with a gift card`, in the class `CucumberScenarioTest` |
| A step's result | Each step has its own result: passed, failed or skipped | The scenario has one result; its steps show as activities in the test report |
| Run one scenario from the test navigator | No: give it a tag of its own, and choose it with `CUCUMBER_TAGS` | Yes, with the scenario's run button |
| A failing step | Opens its line in the feature file | Opens its line in the feature file |
| Steps after a failure, or after a step that throws `XCTSkip` | Skipped | Skipped activities |

To have one test per scenario, set `Cucumber.oneTestPerScenario = true` in `setupSteps()`, or set `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES`. For example, keep a test per step in your default test plan, and add a test plan that sets `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES` for when you want to run scenarios one at a time.

Your step definitions, hooks and feature files don't change between the two. The tests' names do, so test plans that select or skip tests by name, and test history in CI, see different tests when you switch.

### Go from a failure to its step

A step that fails is reported at its line in the feature file. Click the failure in the issue navigator or the test report, and Xcode opens the feature file at that step and marks it there. The failure's call stack still leads to the line in your step definition that failed.

This holds for a failed assertion in a step definition, for a step that no step definition matches, and for a step that more than one step definition matches. Steps you write with the DSL have no feature file, so their failures stay in your Swift code.

Once a step fails, the rest of its scenario's steps don't run, and Xcode shows them as skipped, or with one test per scenario, as skipped activities.

A step that no step definition matches fails its own test, or with one test per scenario, its scenario's test. The failure message contains the step definition CucumberSwift generated for it. A step like that after a step that failed is skipped too, and its generated step definition is in the file attached to the `GenerateStepsStubsIfNecessary` test.

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

<!-- swift-example: steps -->
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

Then give each set of tags a test plan of its own. (To choose scenarios in code instead, see <doc:Settings#Choose-scenarios-in-code>.)

1. Create a test plan named after its tags, such as **Smoke**, with your test target in it.
2. In the test plan's **Configurations** tab, under **Arguments**, add the environment variable `CUCUMBER_TAGS` with the tags as its value, such as `Smoke`. Separate several tags with commas, such as `Smoke,Checkout`, to run the scenarios that have any of them.
3. Add the test plan to your scheme, and keep a test plan without `CUCUMBER_TAGS` as the scheme's default, so that ⌘U runs every scenario.

To run a set of tags, choose its test plan in the menu at the top of the test navigator, and run the tests. From the command line, name it with `-testPlan`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan Smoke
```

Use a test plan for each set of tags rather than a configuration for each in one test plan. A test plan runs all of its configurations, and Xcode's test navigator shows a scenario as not run unless it ran in every one of them.

A tag in `CUCUMBER_TAGS` matches a feature's or scenario's tags as a regular expression, without regard to case, so `Smoke` also matches `@SmokeTest`. Don't put spaces around the commas: they would be part of the expression. A feature tag applies to every scenario in the feature.

### Run one scenario

With a test per step, the default, Xcode's test navigator can't run one scenario on its own: the test classes exist only while the bundle runs, so Xcode can't find the one it's asked for, runs no tests, and reports success. The same happens with `xcodebuild -only-testing:` and a scenario's name. To run one scenario, give it a tag of its own and choose it with `CUCUMBER_TAGS`, or switch to one test per scenario.

With one test per scenario, a scenario's run button in the test navigator runs just that scenario. From the command line, name its test with `-only-testing:`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'MyAppTests/CucumberScenarioTest/Checkout › Pay with a gift card'
```

The test's name is its feature's and its scenario's, as the test navigator shows it. A scenario whose name repeats another's in the same feature gets a number, as in `Checkout › Pay 2`.

With parallel testing on, a scenario's test is in a class of its own, named with its position in the feature files: see <doc:Running-Scenarios-In-Parallel#Test-names>.

### Skip a scenario

To skip a scenario, for example when a service it needs is unavailable, throw `XCTSkip` from a step definition:

<!-- swift-example: steps -->
```swift
Given("the card terminal is offline") { _, _ in
    throw XCTSkip("The card terminal is offline")
}
```

The rest of the scenario doesn't run, and Xcode shows the steps after that one as skipped, with your reason. With one test per scenario, the scenario's test is skipped.

## Run the plugins in CI

This section explains how to run CucumberSwift's plugins in CI, where nobody is at Xcode to answer its prompts.

The build tool plugins run in any build of a target that applies them, so a CI build checks what Xcode checks on your Mac. The command plugins change files, and are for you to run, not CI, though one of them can report without changing anything.

| Plugin | In CI | How |
|---|---|---|
| `CucumberSwiftLint` | Runs in every build, and reports warnings, never errors | `swift build`, `swift test` or `xcodebuild`, on a target that applies it |
| `CucumberSwiftTestingPlugin` | Runs in every build | The same: the tests need it |
| **Convert to Gherkin Macros** | Can report what is left to convert, in a Swift package | `swift package --allow-writing-to-package-directory convert-to-gherkin-macros --dry-run` |
| **Fix Feature Files** | Not for CI: it changes files and has no report-only mode | Run it on your Mac |

### Build an Xcode project in CI

On a CI machine, nobody can answer Xcode's request to trust a plugin or a macro, so pass `-skipPackagePluginValidation`, and `-skipMacroValidation` if your step definitions use the macros. The same goes for a project that Tuist generates. Each flag trusts every package plugin or macro in the build, so use them only for code you trust.

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation -skipMacroValidation
```

### Build a Swift package in CI

`swift build` and `swift test` don't ask to trust plugins or macros, so they need no flags. To list the step definitions that Convert to Gherkin Macros would convert, without changing a file:

```bash
swift package --allow-writing-to-package-directory convert-to-gherkin-macros --dry-run
```

The command declares that it changes files, so `swift package` asks for the permission even with `--dry-run`, and in CI nobody can answer: `--allow-writing-to-package-directory` gives it. It exits with an error when the package isn't set up for the macros: when the `Macros` trait is off, or a target it converts doesn't depend on the macros product.
