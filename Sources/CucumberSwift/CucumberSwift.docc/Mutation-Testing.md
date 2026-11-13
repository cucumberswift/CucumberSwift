# Mutation testing

Find the scenarios that still pass when the code they test is wrong.

## Overview

The `cucumberswift-mutation-test` command safely changes your code in small ways, runs your tests against each change, and lists the changes that no test noticed. Run it from a Swift package that has CucumberSwift tests, or on an Xcode project as <doc:#Xcode-projects> shows:

```bash
swift run cucumberswift-mutation-test
```

> Note: What is mutation testing? Mutation testing is a technique for making small changes in code to see if tests still pass. If they do, we say a "mutant" survived. The goal of mutation testing is to "kill mutants" by finding tests that pass when they should fail and improving them. Don't worry, no bugs will be introduced into your code on purpose! The command changes only a throwaway copy of your code in a temporary folder, and never touches your repository. See <doc:#Know-that-your-files-are-safe>.

The example on this page is derived from our [MutationTesting sample project](https://github.com/cucumberswift/CucumberSwiftSample/tree/main/Tuist/MutationTesting). The sample's `Basket.swift` gives 10% off from 3 items and free shipping over 100:

```swift
/// A shopping basket: 10% off from 3 items, and free shipping over 100.
public final class Basket {
    public private(set) var prices = [Int]()
    public private(set) var isSaved = false

    public init() {}

    public func add(_ price: Int) {
        prices.append(price)
    }

    public func add(contentsOf more: [Int]) {
        // cucumberswift:mutation-ignore - reserving capacity changes speed, not results
        prices.reserveCapacity(prices.count + more.count)
        prices.append(contentsOf: more)
    }

    public var total: Int {
        let sum = prices.reduce(0, +)
        // Takes 10% off when the basket has 3 or more items. Integer division rounds the result down.
        let discounted = prices.count >= 3 ? sum * 9 / 10 : sum
        return discounted > 100 ? discounted : discounted + 5
    }

    public func checkout() {
        guard !prices.isEmpty else { return }
        isSaved = true
    }

    /// No scenario prints a receipt: a coverage gap, so mutation testing leaves its mutant out of the score.
    public func receipt() -> String {
        prices.isEmpty ? "Nothing to pay" : "Total: \(total)"
    }
}
```

Its `Basket.feature` checks three cases:

```gherkin
@before
Feature: Basket
  10% off from 3 items, and free shipping over 100.

  Scenario: Two items pay shipping
    Given a basket with items costing 20 and 30
    Then the total is 55

  Scenario: Three items get a discount
    Given a basket with items costing 50, 50 and 50
    Then the total is 135

  Scenario: Checking out saves the basket
    Given a basket with items costing 20 and 30
    When I check out
    Then the basket is saved
```

The command changes `Basket.swift` in 17 ways, one at a time. Run it on these scenarios, tagged `@before`:

```bash
swift run cucumberswift-mutation-test --tags before
```

Each line names a mutant, its place, its rule, the change and the result:

```
1/17 Sources/Shop/Basket.swift:4:39 BooleanLiteral false → true: Survived (7.1 s)
2/17 Sources/Shop/Basket.swift:9:9 RemoveCall prices.append(price) → (removed): Killed (6.2 s)
3/17 Sources/Shop/Basket.swift:14:9 RemoveCall prices.reserveCapacity(prices.count + more.count) → (removed): Ignored (0.0 s)
4/17 Sources/Shop/Basket.swift:14:45 ArithmeticOperator + → -: Ignored (0.0 s)
5/17 Sources/Shop/Basket.swift:15:9 RemoveCall prices.append(contentsOf: more) → (removed): Killed (5.9 s)
6/17 Sources/Shop/Basket.swift:21:26 SwapTernary prices.count >= 3 ? sum * 9 / 10 : sum → prices.count >= 3 ? sum : sum * 9 / 10: Killed (5.8 s)
7/17 Sources/Shop/Basket.swift:21:39 RelationalOperator >= → <: Killed (5.6 s)
8/17 Sources/Shop/Basket.swift:21:39 RelationalOperator >= → >: Killed (5.7 s)
9/17 Sources/Shop/Basket.swift:21:50 ArithmeticOperator * → /: Killed (6.0 s)
10/17 Sources/Shop/Basket.swift:21:54 ArithmeticOperator / → *: Killed (5.9 s)
11/17 Sources/Shop/Basket.swift:22:16 SwapTernary discounted > 100 ? discounted : discounted + 5 → discounted > 100 ? discounted + 5 : discounted: Killed (5.7 s)
12/17 Sources/Shop/Basket.swift:22:27 RelationalOperator > → <=: Killed (5.9 s)
13/17 Sources/Shop/Basket.swift:22:27 RelationalOperator > → >=: Survived (6.0 s)
14/17 Sources/Shop/Basket.swift:22:59 ArithmeticOperator + → -: Killed (6.2 s)
15/17 Sources/Shop/Basket.swift:26:15 LogicalNot ! → (removed): Killed (5.5 s)
16/17 Sources/Shop/Basket.swift:27:19 BooleanLiteral true → false: Killed (5.8 s)
17/17 Sources/Shop/Basket.swift:32:9 SwapTernary prices.isEmpty ? "Nothing to pay" : "Total: \(total)" → prices.isEmpty ? "Total: \(total)" : "Nothing to pay": NoCoverage (0.0 s)
```

The run ends with the score and the mutants that no scenario noticed, with the scenarios that run their code:

```
Mutation score: 85.7% (12 of 14 mutants detected)
Killed 12, timed out 0, survived 2, did not build 0, ignored 2, in code no scenario runs 1

Mutants that no test noticed:
  Sources/Shop/Basket.swift:4:39 BooleanLiteral false → true
    Scenarios that run this code: Two items pay shipping (line 5), Three items get a discount (line 9), Checking out saves the basket (line 13)
  Sources/Shop/Basket.swift:22:27 RelationalOperator > → >=
    Scenarios that run this code: Two items pay shipping (line 5), Three items get a discount (line 9)
```

No scenario has a total of exactly 100, so changing `>` to `>=` changes nothing that a scenario checks. No scenario checks that an empty basket isn't saved, so a basket that starts out saved passes them all. The sample's `Basket-killed.feature`, tagged `@after`, has the same scenarios and adds one scenario for each of them:

```gherkin
  Scenario: A total of exactly 100 pays shipping
    Given a basket with items costing 50 and 50
    Then the total is 105

  Scenario: An empty basket isn't saved
    Given an empty basket
    When I check out
    Then the basket isn't saved
```

With those scenarios, every mutant is killed:

```
Mutation score: 100.0% (14 of 14 mutants detected)
Killed 14, timed out 0, survived 0, did not build 0, ignored 2, in code no scenario runs 1
```

## Turn it on

Turn mutation testing on in the package or Xcode project that contains your scenarios. <doc:Mutation-Testing#Swift-packages> describes a Swift package, and <doc:Mutation-Testing#Xcode-projects> describes an Xcode project.

### Swift packages

Mutation testing reads your Swift code with swift-syntax, so it needs CucumberSwift's `Macros` package trait, as <doc:Using-Step-Definition-Macros> describes. Before Swift 6.4, SwiftPM also needs swift-syntax declared next to CucumberSwift. The sample's `Package.swift` does both, and uses a local CucumberSwift checkout when `CUCUMBER_SWIFT_PATH` is set:

```swift
// swift-tools-version:6.1
import PackageDescription

// The same code and scenarios as Project.swift, as a Swift package, for `swift run cucumberswift-mutation-test`.
// Mutation testing runs on Swift packages: it copies this package to a temporary folder, changes
// Sources/Shop there, and runs `swift test` against each change. It never changes this folder.
//
// Mutation testing reads Swift code with swift-syntax, so CucumberSwift's Macros trait is on. To use a
// local CucumberSwift checkout, set CUCUMBER_SWIFT_PATH, as for Project.swift:
//
//     CUCUMBER_SWIFT_PATH=~/src/CucumberSwift swift run cucumberswift-mutation-test
let cucumberSwift: Package.Dependency = {
    if let path = Context.environment["CUCUMBER_SWIFT_PATH"], !path.isEmpty {
        return .package(name: "CucumberSwift", path: path, traits: ["Macros"])
    }
    return .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.9.0", traits: ["Macros"])
}()

let package = Package(
    name: "MutationTesting",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Shop", targets: ["Shop"])
    ],
    dependencies: [
        cucumberSwift,
        // Before Swift 6.4, SwiftPM needs this to resolve the Macros trait. No target uses it.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
    ],
    targets: [
        .target(name: "Shop", path: "Sources/Shop"),
        .testTarget(
            name: "MutationTestingTests",
            dependencies: [
                "Shop",
                .product(name: "CucumberSwift", package: "CucumberSwift")
            ],
            path: "Tests",
            resources: [.copy("Features")]
        )
    ]
)
```

Without the trait, the command prints what to turn on and changes nothing. It needs Swift 6.1 or later, and it works with the XCTest runner and the Swift Testing runner alike.

### Xcode projects

The command builds and tests an Xcode project with `xcodebuild`, so the project needs no change. An Xcode project has no `Package.swift` to run the command from. Clone CucumberSwift at the version your project uses, and run its command from your project's folder with `--package-path`. The command reads your Swift code with swift-syntax, so it needs the `Macros` package trait:

```bash
swift run --package-path ~/src/CucumberSwift --traits Macros cucumberswift mutation-test \
  --project Shop.xcodeproj --scheme Shop --destination 'platform=macOS'
```

Name the project with `--project`, or a workspace with `--workspace`. Give the scheme and the destination that `xcodebuild` runs the tests with. The command passes the destination to `xcodebuild` as it is, and our GitHub Actions CI workflow tests it with `platform=macOS`. The scheme's test action must run unit test bundles that use CucumberSwift, with the XCTest runner or the Swift Testing runner. UI test bundles aren't supported, because the changed code runs in the app.

The command mutates the Swift files in the `Sources` folder of your project's folder. Pass `--sources` once for each other folder with code. An Xcode project has no package to read its targets from, so `--target` isn't available. These options apply to Xcode projects:

| Option | Effect |
|---|---|
| `--project <name>` or `--workspace <name>` | The `.xcodeproj` or `.xcworkspace` in the project's folder. Pass one of them. |
| `--scheme <name>` | The scheme that builds and tests the project. |
| `--destination <destination>` | The `-destination` that `xcodebuild` builds for and runs the tests on. |
| `--test-target <name>` | A test target of the scheme. Pass it once for each test target that contains scenarios when the scheme has several. The run then tests only the targets you name, and tests every target of the scheme when you name none. |
| `--sources <folder>` | A folder with code to mutate, relative to the project's folder. The default is `Sources`. |
| `--xcodebuild-arg <argument>` | Adds one argument to every `xcodebuild` command, such as `-quiet`. Repeat it for more arguments. |

The command runs `xcodebuild` with `-skipMacroValidation` and `-skipPackagePluginValidation`, so Xcode doesn't ask to trust the macros and plugins of your project's packages, and with `CODE_SIGNING_ALLOWED=NO`.

## Find those mutants!

Run the `cucumberswift-mutation-test` command to find the mutants that your scenarios miss. Run it from the command line or from Xcode. Either way, it works on a throwaway copy of your package and writes its reports to `.build/mutation-testing` in the package, where your tests read the last run's report.

### From the command line

Run the command in the folder with your `Package.swift`. The sample's `--tags before` chooses its `@before` scenarios, as `CUCUMBER_TAGS` does:

```bash
swift run cucumberswift-mutation-test --tags before
```

The command prints a line for each mutant as it tests it:

```
Found 17 mutants in 1 file.
Building the copy and running the tests 2 times without a change.
The tests take 3.1 s. A mutant times out after 30 s.
Coverage: 3 scenarios ran. A mutant in code that no scenario runs isn't tested.
1/17 Sources/Shop/Basket.swift:4:39 BooleanLiteral false → true: Survived (6.5 s, 3 of 3 scenarios)
2/17 Sources/Shop/Basket.swift:9:9 RemoveCall prices.append(price) → (removed): Killed (6.3 s, 1 of 3 scenarios)
…
Mutation score: 85.7% (12 of 14 mutants detected)
Killed 12, timed out 0, survived 2, did not build 0, ignored 2, in code no scenario runs 1
```

Each line of a tested mutant ends with the number of scenarios that the command ran for it, out of the scenarios that ran without a change. Without coverage, the command runs every scenario for every mutant and prints no number. The section <doc:Mutation-Testing#Run-only-the-scenarios-that-cover-a-mutant> describes how the command picks the scenarios.

Add `--format xcode` to also print each surviving mutant as a warning in the compiler's format, with the file's full path. Xcode shows such a warning at its line when a Run Script build phase prints it:

```
…/Sources/Shop/Basket.swift:4:39: warning: No test failed after changing false to true at Basket.swift:4. Add a scenario that checks this code.
…/Sources/Shop/Basket.swift:22:27: warning: No test failed after changing > to >= at Basket.swift:22. Add a scenario that checks this code.
```

### From Xcode

Open your package in Xcode. In the Project navigator, Control-click the package and choose **Mutation Testing** in the CucumberSwift section of the menu. Select the target with your code, add `--tags before` under **Arguments** to choose the sample's `@before` scenarios, and click **Run**. The first time, Xcode asks to let the command write to the package folder, where it puts its report:

![The Mutation Testing dialog in Xcode. The MutationTesting package lists its targets, MutationTestingTests and Shop. Under Arguments, --tags before is checked. The dialog has Cancel and Run buttons.](MutationTesting-XcodeDialog.png)

Xcode shows the run's output in the Report navigator, as an entry named after the command. The output ends with the score and a warning for each surviving mutant:

![The Report navigator in Xcode with the output of the Mutation Testing command. It lists the 17 mutants and their results, then "Mutation score: 85.7% (12 of 14 mutants detected)", the mutants that no test noticed with the scenarios that run their code, the folder of the reports, .build/mutation-testing in the package, and 2 warnings: no test failed after changing false to true at Basket.swift:4, and no test failed after changing > to >= at Basket.swift:22.](MutationTesting-Xcode.png)

### On an Xcode project

The command tests an Xcode project by running `xcodebuild` on a copy of it. This section describes what it runs, how it counts the tests, and how to see the surviving mutants in Xcode. Run the command from your project's folder, as <doc:#Xcode-projects> shows. The command copies the folder to a temporary folder, as <doc:#Know-that-your-files-are-safe> describes for a package. It builds the copy once with `xcodebuild build-for-testing` and code coverage on, then runs `xcodebuild test-without-building` on the copy without a change. For each mutant, it builds the copy with the change and runs `test-without-building` again. Every build uses one DerivedData folder in the temporary folder, so each build reuses the products of the first.

The command counts the tests that ran from the result bundle of each `xcodebuild` run, not from the exit status, because `xcodebuild` exits with success when it runs no test. The command stops when a run of the tests runs no test: the run of the unchanged project, or the run for a mutant.

The command passes the `CUCUMBER_` variables of its environment on to the tests, so `--tags` and `CUCUMBER_TAGS` choose the scenarios, as <doc:#Choose-what-to-test> describes. The command writes its reports to `.build/mutation-testing` in your project's folder, so add `.build` to your `.gitignore`.

To see the surviving mutants as warnings in Xcode, add `--format xcode` and run the command from a Run Script build phase. Put the phase in a target of its own, because the command runs your whole test suite for each mutant. Set the target's `ENABLE_USER_SCRIPT_SANDBOXING` build setting to `NO`, because Xcode's script sandbox blocks `swift` and `xcodebuild`. The phase starts the command with `env -i`, so the build's variables don't reach the command's own `xcodebuild`:

```bash
env -i HOME="$HOME" DEVELOPER_DIR="$DEVELOPER_DIR" TMPDIR="$TMPDIR" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    /usr/bin/swift run --package-path ~/src/CucumberSwift --traits Macros cucumberswift mutation-test \
    --root "$SRCROOT" --project Shop.xcodeproj --scheme Shop --destination 'platform=macOS' --format xcode
```

Xcode then shows each warning at its line when you build that target.

## Read the results

The command gives each mutant one of these results:

| Result | Meaning | Counts in the score |
|---|---|---|
| Killed | A test failed | Yes, as detected |
| Timeout | The tests ran longer than the limit, as when a change makes a loop endless | Yes, as detected |
| Survived | Every test passed | Yes, as not detected |
| CompileError | The changed code didn't build, so no test could notice it | No |
| Ignored | A `cucumberswift:mutation-ignore` comment marks its line | No |
| NoCoverage | No scenario runs its code, so no scenario can notice the change | No |

The mutation score is the share of the counted mutants that a test detected. A NoCoverage mutant is in code that no scenario runs. That is a coverage gap, not a scenario that misses a change, so the score leaves it out. The sample's `receipt()` is code that no scenario runs:

<!-- swift-example: fragment: an excerpt of the sample's Basket.swift, shown in full above -->
```swift
/// No scenario prints a receipt: a coverage gap, so mutation testing leaves its mutant out of the score.
public func receipt() -> String {
    prices.isEmpty ? "Nothing to pay" : "Total: \(total)"
}
```

> Note: Mutation testing depends on good test coverage. It tests only the code that your scenarios run, so code they never run gets no mutation testing at all, and a high mutation score can hide it. A feature's coverage score counts only the functions its scenarios enter, so a function that no scenario calls, such as `receipt()`, shows only in the summary's share of all measured code. Raise your coverage first, as <doc:Measuring-Code-Coverage> describes.

The command writes its reports to `.build/mutation-testing` in the package, or to the folder that `--output` names:

| File | Contents |
|---|---|
| `summary.txt` | The score and the surviving mutants, as printed |
| `mutation-report.json` | Every mutant, in the Stryker mutation report format |
| `cucumber-mutant-<number>.json` | The Cucumber JSON report of the run for that mutant, with the mutant added to its steps |

### Open the report in a Stryker viewer

`mutation-report.json` is in the Stryker mutation testing report format, version 2, the format that Stryker's mutation testing tools write. Its schema is in the [mutation-testing-elements repository](https://github.com/stryker-mutator/mutation-testing-elements/tree/master/packages/report-schema). A viewer for that format, such as [Mutation Testing Elements](https://github.com/stryker-mutator/mutation-testing-elements), shows the mutants over your source code. The report's `statusReason` names the failed steps of a killed mutant, the scenarios that run the code of a surviving one, and the comment's text for an ignored one. Each mutant's `killedBy` lists the scenarios that failed on it, and its `coveredBy` lists the scenarios that run its code. Both use the IDs in `testFiles`, such as `Features/Basket-killed.feature:18`, which is the feature file's path inside the test bundle and the scenario's line.

### Find the scenario in the Cucumber report

The command adds each mutant to the Cucumber JSON report that your tests write (see <doc:Generating-Reports>), as an `embeddings` entry, so existing Cucumber tools show it with the step:

- For a killed mutant, the entry is on each step that failed.
- For a surviving mutant, the entry is on the last step of every scenario that ran, because each of them passed without noticing it.

The entry is CucumberSwift's own JSON, not the Stryker format, with the mutant's number, rule, change, place and result:

```json
{ "change" : "> → >=", "location" : "Sources/Shop/Basket.swift:22:27", "mutant" : 13, "mutator" : "RelationalOperator", "status" : "Survived" }
```

## Ignore an equivalent mutant

Some mutants change the code without changing what it does. No scenario can kill such an equivalent mutant, so it would survive every run, and fail every Mutation test. Mark its line with a `cucumberswift:mutation-ignore` comment, and say why after the marker. In the sample, removing the call to `reserveCapacity` only changes how fast the basket grows:

<!-- swift-example: fragment: an excerpt of the sample's Basket.swift, shown in full above -->
```swift
public func add(contentsOf more: [Int]) {
    // cucumberswift:mutation-ignore - reserving capacity changes speed, not results
    prices.reserveCapacity(prices.count + more.count)
    prices.append(contentsOf: more)
}
```

A comment on a line of its own marks the next line of code, and a comment at the end of a line marks that line. The command neither tests nor counts the mutants on a marked line. The report lists them as Ignored, with the comment's text as the reason. The sample's run lists two mutants as ignored: the removed call and the changed `+` on the same line.

## Fail your tests on a surviving mutant

Each feature can get a Mutation test that fails when a mutant in its code survived the last run. Turn on `Cucumber.mutationTesting`, set `Cucumber.mutationReport` to the full path of the run's `mutation-report.json`, and run your tests with code coverage on, as <doc:Measuring-Code-Coverage> describes. The sample's step definitions do this once the command has written its report:

<!-- swift-example: steps -->
```swift
let sample = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let report = sample.appendingPathComponent(".build/mutation-testing/mutation-report.json")
if FileManager.default.fileExists(atPath: report.path) {
    Cucumber.mutationTesting = true
    Cucumber.mutationReport = report.path
}
```

The environment variables `CUCUMBER_MUTATION_TESTING` and `CUCUMBER_MUTATION_REPORT` set `Cucumber.mutationTesting` and `Cucumber.mutationReport` from outside the code. With the XCTest runner, each feature's `Coverage scores` suite then has a third test, `Mutation`, after `Coverage` and `Redundancy`. It fails when any mutant in the code that the feature's scenarios run survived, with an error on the feature and on each scenario that runs that code. These are the sample's errors after the run above:

```
Basket.feature:1   Mutation testing: the scenarios still pass after 2 of the 14 changes to the code they run, in the mutation report of Nov 5, 2026 at 10:11 AM. …
Basket.feature:5   This scenario still passes when false at Basket.swift:4 is changed to true. Add a step that checks this code.
Basket.feature:9   This scenario still passes when false at Basket.swift:4 is changed to true. Add a step that checks this code.
Basket.feature:13  This scenario still passes when false at Basket.swift:4 is changed to true. Add a step that checks this code.
Basket.feature:5   This scenario still passes when > at Basket.swift:22 is changed to >=. Add a step that checks this code.
Basket.feature:9   This scenario still passes when > at Basket.swift:22 is changed to >=. Add a step that checks this code.
```

Xcode shows the errors on the feature and on each scenario, and lists them under the feature's `Mutation` test:

![The Basket feature file in Xcode. The feature's first line has an error that the scenarios still pass after 2 of the 14 changes to the code they run. The scenarios at lines 5 and 9 each have 2 errors, and the scenario at line 13 has 1. Each error names a change that the scenario still passes with.](MutationTesting-Fails.png)

The Swift Testing runner prints the same errors with the feature file and line, as it does the coverage errors.

The test run doesn't change any code. It matches each mutant in the report to the scenarios that ran its code, through the coverage it measures, so mutation testing needs coverage: with coverage off, there is no Mutation test. A feature whose scenarios run no mutant's code passes. Three more cases fail the Mutation test, so that turning it on never passes silently:

- **No report, or one that can't be read.** Run `cucumberswift-mutation-test` first.
- **A report about other code.** The report contains each file's text as it was. A file that changed since then makes the report out of date, so the Mutation test fails until you run the command again.
- **A report about other scenarios.** The report lists every scenario that its run tested. The Mutation test fails when one of the feature's scenarios isn't in that list, as when the command ran with other `CUCUMBER_TAGS` than the tests.

Run the command with the same `CUCUMBER_TAGS` as the tests that read its report. The sample's `MutationTesting` scheme runs `@before`, and its `MutationTesting-Killed` scheme runs `@after`.

## Compare scenarios by what they check

The Mutation test also changes how the redundancy compares your scenarios. A scenario is redundant only when the other scenarios run all of its code and fail on every mutant it fails on. <doc:Finding-Redundant-Scenarios#Compare-scenarios-by-what-they-check> shows the sample's results, and <doc:Advanced-Testing> explains how coverage, redundancy and mutation testing work together.

## Choose what to test

Without options, the command mutates every library and executable target of the package in the current folder. These options narrow or tune a run:

```bash
swift run cucumberswift-mutation-test --target Shop --max-mutants 20
```

| Option | Effect |
|---|---|
| `--root <folder>` | Tests the package in this folder instead of the current folder. |
| `--target <name>` | Mutates only that target's code. Repeat it for more targets. |
| `--tags <expression>` | Runs only the scenarios with these tags, as `CUCUMBER_TAGS` does. |
| `--dry-run` | Lists the mutants and runs no tests. |
| `--max-mutants <n>` | Tests only the first `n` mutants, in file and line order. |
| `--baseline-runs <n>` | Runs the tests `n` times without a change first. The default is 2. |
| `--timeout-multiplier <n>` | Stops a mutant's tests after `n` times the baseline's time. The default is 3. |
| `--minimum-timeout <seconds>` | The shortest time limit. The default is 30. |
| `--work-dir <folder>` | Puts the temporary copy in this folder, which can't be in a `.build` folder. |
| `--output <folder>` | Writes the reports to this folder. |
| `--format xcode` | Also prints each surviving mutant as a warning in the compiler's format. |

The command passes its environment on to the tests, so `CUCUMBER_TAGS` chooses the scenarios too, as `--tags` does. It first builds the copy and runs your tests twice without any change. It stops if they fail, because a failing mutant would prove nothing, and it stops if they run no test, because `swift test` exits with success when it finds none. Fix the tests first.

### The changes it makes

The command makes these changes, one at a time. It reads your code as swift-syntax parses it, so it never changes an operator inside a string or a comment, and it makes the same mutants, in the same order, every time:

| Rule | Change |
|---|---|
| `RelationalOperator` | `>` to `>=` and `<=`, `>=` to `>` and `<`, `<` to `<=` and `>=`, `<=` to `<` and `>`, `==` to `!=`, `!=` to `==` |
| `LogicalOperator` | `&&` to `\|\|`, and `\|\|` to `&&` |
| `ArithmeticOperator` | `+` to `-`, `-` to `+`, `*` to `/`, `/` to `*`, unless an operand is a string literal |
| `BooleanLiteral` | `true` to `false`, and `false` to `true` |
| `LogicalNot` | Removes the `!` of a negation |
| `SwapTernary` | `condition ? a : b` to `condition ? b : a` |
| `RemoveCall` | Removes a call whose result isn't used, except logging and assertion calls such as `print`, `logger.info` and `assert` |

### Keep the run short

The command builds and runs your test suite once for each mutant, after a few seconds of rebuilding the one changed file. The first run without a change measures which scenarios run which code. The command doesn't test a mutant in code that no scenario runs, and it runs only the scenarios that run the code of every other mutant. Two options cut a run down further: `--target` limits the code, and `--max-mutants` limits the count.

### Run only the scenarios that cover a mutant

The command runs the scenarios that run a mutant's code by setting `CUCUMBER_SCENARIOS` to their ids, with each of the three build tools it tests with: Swift Package Manager (<doc:Mutation-Testing#Swift-packages>), Xcode (<doc:Mutation-Testing#Xcode-projects>) and Bazel (<doc:Running-Tests-With-Bazel>). The XCTest runner and the Swift Testing runner both read the variable. You can set it yourself to run one scenario of the sample, the "Three items get a discount" scenario on line 9 of `Basket.feature`:

```bash
CUCUMBER_SCENARIOS=Features/Basket.feature:9 swift test
```

An id is the path of the feature file inside the test bundle, a colon and the line of the scenario. <doc:Settings#Settings-that-work-differently> describes the format of the list.

An Xcode project with several test targets that you name with `--test-target` gets one more saving. The command runs a test target only when its built bundle contains a feature file of the mutant's scenarios. When no bundle contains one, or the command can't find a bundle, it runs every target.

## Know that your files are safe

The command never changes your package. It follows these rules:

- It copies the package into a temporary folder, or into `~/Library/Caches` when the temporary folder isn't writable, and mutates only the copy. The copy is never inside the package. It uses copy-on-write clones where the file system supports them. It leaves out `.git` and the build folders.
- It deletes the copy and its lock file when the run ends, fails, or stops on Control-C or a termination signal.
- A run killed with `kill -9` can't clean up. The next run reads the lock file, sees that the process is gone, and deletes the old copy first.
- It compares every file in the package, and git's status, index and `HEAD`, before and after the run. It fails and names the file if anything changed.
- It never runs `git add`, `git commit`, `git stash` or `git checkout`. A package with uncommitted changes is fine, because the copy takes the files as they are.

The command stops with an error that lists the folders it tried if none of them is writable. It never falls back to changing your files.

## Limits

The command has these limits today:

- It runs the whole test suite for each mutant that a scenario covers. It doesn't yet run only the scenarios that cover the changed code.
- It doesn't yet remember the result of an earlier run, so every run tests every mutant again.
- It doesn't run UI tests, because the changed code runs in the app and each mutant would need a full UI test run.
- A test that writes to your source files isn't made safe by the copy.
- A path dependency with a relative path outside the package (`path: "../Shared"`) isn't found in the copy. Use an absolute path or a URL.
- The temporary copy can't be in a folder with a space in its path, because Swift Testing finds no tests in such a package. The command picks a folder without a space itself, and stops with an error if you pass `--work-dir` with one.
