# Using the Step Definition Macros

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

Set up the step definition macros in a Swift package, an Xcode project or a Tuist project, write step definitions with them, and fix what goes wrong.

## Overview

The step definition macros, `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`, are another way to write the step definitions you would write with ``Given``, ``When`` and the like. The closure takes one argument per parameter in the pattern, already converted to its type, instead of reading each one from `match`. For example, a feature file has this step:

```gherkin
Given I have 5 cukes
```

This step definition matches it, with `count` set to 5:

<!-- swift-example: steps -->
```swift
#Given("I have {int} cukes") { (count: Int) in
    basket.add(count)
}
```

The compiler checks each pattern and closure where you write it, and offers a fix for the common mistakes: see <doc:Checking-Step-Definitions>. Each macro expands to the step definition you would otherwise write by hand, so nothing about how steps match or run changes. Feature files, the hook functions and the step definitions you already have keep working, and you can mix both styles in one target.

This article covers, in order: what the macros need, setting them up for each kind of project, writing step definitions with them for XCTest and for Swift Testing, converting the step definitions you have, and troubleshooting.

## Requirements

| | In a Swift package | In an Xcode project |
|---|---|---|
| Xcode | 16.3 (Swift 6.1) or later | 26.4 or later |
| swift-syntax | 600.0.0 up to, but not including, 605.0.0 | 600.0.0 up to, but not including, 605.0.0 |
| Where the tests run | iOS 13, macOS 10.15, tvOS 13 and watchOS 7.4 or later | iOS 13, macOS 10.15, tvOS 13 and watchOS 7.4 or later |
| Where step definitions with a regex literal run | iOS 16, macOS 13, tvOS 16 and watchOS 9 or later | iOS 16, macOS 13, tvOS 16 and watchOS 9 or later |

- **Both are tested.** CI builds and tests a Swift package that uses the macros with exactly Xcode 16.3, and a Tuist project that uses them with exactly Xcode 26.4, on macOS 15 and macOS 26 build machines. Nothing else is claimed: the macOS an Xcode needs is Apple's requirement for that Xcode.
- **In a Swift package**, you need Swift 6.1, the first version with package traits, which the macros are behind.
- **In an Xcode project**, you need Xcode 26.4, the first to turn on a package dependency's traits in a project. With an earlier Xcode, turn the trait on from a local package, as described in <doc:Using-Step-Definition-Macros#Before-Xcode-264>, or run your tests from a Swift package, as described in <doc:Running-Tests-With-Swift-Package-Manager>.
- **In a Tuist project**, the Xcode project's requirement applies, and Tuist 4.203.0 or later to set the trait in `Project.swift`. See <doc:Using-Step-Definition-Macros#Set-up-a-Tuist-project>.
- **Convert to Gherkin Macros** (see <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros>) is tested the same way in a Swift package: CI runs the command with exactly Xcode 16.3. In an Xcode project it needs the trait on, so Xcode 26.4, as the macros do, but CI doesn't run the command there.
- **swift-syntax 600 to 604.** SwiftPM picks one swift-syntax version for your whole package, so the macros accept any version in that range: your package can also use another macro package, as long as the two ranges overlap. CI tests the macros with the oldest, 600.0.0, every night, and with the version CucumberSwift's own `Package.resolved` pins on every change. Versions before 600 don't build.
- **The tests run wherever CucumberSwift runs.** A macro expands into an ordinary step definition when your code compiles, so it adds nothing at run time.
- **Regex literals need iOS 16, macOS 13, tvOS 16 or watchOS 9**, as Swift's `Regex` does, with or without the macros. Below those versions, mark the code that uses them with `@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)`, or use a string pattern. See <doc:Using-Step-Definition-Macros#Regex-literals>.
- **Swift Package Manager only.** Carthage builds CucumberSwift from its Xcode project, which cannot deliver macros, so a Carthage install keeps the step definition functions.

## Set up a Swift package

The macros are a separate product, `CucumberSwiftMacros`, behind a package trait named `Macros`. They need the swift-syntax package, which SwiftPM downloads only when the trait is on. With Swift 6.2, a package that does not turn the trait on doesn't download swift-syntax. Swift 6.1 may still record a pin for it in `Package.resolved`, because the dependency is declared, but it doesn't build it.

In your `Package.swift`, turn the trait on, declare swift-syntax as well, and depend on the product:

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
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")],
            resources: [.copy("Features")],
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
    ]
)
```

Then `import CucumberSwiftMacros` where you write step definitions. It imports CucumberSwift and CucumberSwiftExpressions as well. You can remove the swift-syntax dependency once you use Swift 6.4 or later: see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>.

To run your feature files with Swift Testing instead, depend on `CucumberSwiftTestingMacros` rather than `CucumberSwiftMacros`, and apply its plugin: <doc:Running-Feature-Files-With-Swift-Testing#Set-up-a-Swift-package> shows the manifest.

## Set up an Xcode project

With Xcode 26.4 or later:

1. Add the CucumberSwift package with **File > Add Package Dependencies…**, and turn on the `Macros` trait in the package dependency's settings.
2. Add the swift-syntax package to the project as well, without adding any of its products to a target, as <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64> describes.
3. Add `CucumberSwiftMacros` to your test target, or `CucumberSwiftTestingMacros` for Swift Testing (see <doc:Running-Feature-Files-With-Swift-Testing#Set-up-an-Xcode-project>), and `import` it where you write step definitions.

### Before Xcode 26.4

Before Xcode 26.4, an Xcode project can't turn on a package's traits, but a Swift package that the project depends on can, in its own `Package.swift`, with any Xcode that has Swift 6.1. SwiftPM then builds CucumberSwift with the trait for the whole project. So add a small local package that does only that:

```swift
// swift-tools-version:6.1
// MacrosTrait/Package.swift, next to your Xcode project.
import PackageDescription

let package = Package(
    name: "MacrosTrait",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS("7.4")],
    products: [
        .library(name: "MacrosTrait", targets: ["MacrosTrait"])
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.4.0", traits: ["Macros"])
    ],
    targets: [
        // Depends on a CucumberSwift product, so that SwiftPM counts the dependency, and its trait, as used.
        .target(
            name: "MacrosTrait",
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")])
    ]
)
```

Its target needs one source file, which can be empty, such as `Sources/MacrosTrait/MacrosTrait.swift`.

Add the folder to your project as a local package with **File > Add Package Dependencies… > Add Local…**, without adding its product to any target. Then add CucumberSwift to the project as usual, without the trait, and the swift-syntax package, to the project rather than to `MacrosTrait` (see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>). Add `CucumberSwiftMacros` or `CucumberSwiftTestingMacros` to your test target, and `import` it, exactly as with Xcode 26.4. When you move to Xcode 26.4 or later, remove `MacrosTrait` and turn the trait on in the project instead; your step definitions don't change.

## Set up a Tuist project

In a project that Tuist generates, turn the trait on where the project lists its packages, and depend on the product:

<!-- swift-example: fragment: a Tuist Project.swift, which needs Tuist; Fixtures/StepDefinitionMacrosTuist builds one -->
```swift
let project = Project(
    name: "MyApp",
    packages: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift", from: "6.4.0", traits: ["Macros"]),
        // Before Swift 6.4, SwiftPM needs this to resolve the Macros trait. No target uses it.
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"605.0.0")
    ],
    targets: [
        .target(
            name: "MyAppTests",
            // …
            dependencies: [
                .package(product: "CucumberSwiftMacros"),
                .package(product: "CucumberSwiftLint", type: .plugin)
            ])
    ]
)
```

Tuist writes the trait into the Xcode project it generates, so it needs the same Xcode as any Xcode project, 26.4 or later. The `traits:` parameter is new in Tuist 4.203.0: with an earlier Tuist, `Project.swift` doesn't compile with it. CI generates and tests a project like this one with Xcode 26.4 and the Tuist version CucumberSwift pins.

With a Tuist earlier than 4.203.0, or an Xcode earlier than 26.4, turn the trait on from the `MacrosTrait` local package instead, as described in <doc:Using-Step-Definition-Macros#Before-Xcode-264>, and list it with the project's other packages:

<!-- swift-example: fragment: a Tuist Project.swift, which needs Tuist; Fixtures/SwiftTestingAndXCTestMacrosTuist builds one -->
```swift
let project = Project(
    name: "MyApp",
    packages: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift", from: "6.4.0"),
        // Only turns on CucumberSwift's Macros trait. No target uses it.
        .package(path: "MacrosTrait"),
        // Before Swift 6.4, SwiftPM needs this to resolve the Macros trait. No target uses it.
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"605.0.0")
    ],
    targets: [
        .target(
            name: "MyAppTests",
            // …
            dependencies: [
                .package(product: "CucumberSwiftMacros"),
                .package(product: "CucumberSwiftLint", type: .plugin)
            ])
    ]
)
```

The targets depend on `CucumberSwiftMacros` from CucumberSwift, exactly as with the `traits:` parameter, so moving to it later changes only the `packages` list. CI tests this setup with Xcode 16.3, the oldest Xcode it supports, and with the Xcode it tests by default.

If your project also uses Tuist's own integration for some packages, the ones in `Tuist/Package.swift` that targets reach with `.external(name:)`, see <doc:Using-Step-Definition-Macros#Multiple-commands-produce-swift-syntaxbuild>.

## The first build

The first time you build a macro, Xcode asks you to trust and enable it (see <doc:Using-Step-Definition-Macros#Xcode-asks-you-to-trust-the-macros>). A clean build also compiles swift-syntax. Xcode 26 and Swift 6.2 or later can use a prebuilt swift-syntax instead, but only when swift.org publishes one for both your toolchain and the swift-syntax version your package resolves, and not in every build even then. Swift 6.1 always compiles it.

## Declare swift-syntax before Swift 6.4

Before Swift 6.4, SwiftPM leaves swift-syntax out when it resolves CucumberSwift from its URL with the `Macros` trait on, so resolving fails:

```
error: exhausted attempts to resolve the dependencies graph, with the following dependencies unresolved:
* 'swift-syntax' from https://github.com/swiftlang/swift-syntax.git
```

That's a SwiftPM bug, fixed in Swift 6.4 ([swift-package-manager#10409](https://github.com/swiftlang/swift-package-manager/pull/10409)). Until you use Swift 6.4 or later, declare swift-syntax yourself, next to CucumberSwift, with a range that overlaps the one CucumberSwift accepts (see <doc:Using-Step-Definition-Macros#Requirements>). Nothing needs to use it: declaring it is enough for SwiftPM to resolve it.

- **In a Swift package**, add it to the `dependencies` of the `Package.swift` that turns the trait on, as in <doc:Using-Step-Definition-Macros#Set-up-a-Swift-package>.
- **In an Xcode project**, add it to the project's packages, without adding any of its products to a target: in Xcode, **File > Add Package Dependencies…**; in Tuist, in `Project.packages`. That holds whether the project turns the trait on itself, with Xcode 26.4 or later, or through `MacrosTrait` (see <doc:Using-Step-Definition-Macros#Before-Xcode-264>). Declaring it in `MacrosTrait` doesn't help.

CI resolves and builds the Swift package setup above, swift-syntax included, from a git URL of the commit it tests.

## Write step definitions with the macros

Each macro takes the pattern, a string literal or a regex literal, and a closure. Register the step definitions in `setupSteps()`, as you would without the macros.

### With XCTest

With CucumberSwift's runner, import `CucumberSwiftMacros`:

```swift
import CucumberSwiftMacros
import XCTest

extension Cucumber: StepImplementation {
    public func setupSteps() {
        #Given("I have {int} cukes") { (count: Int) in
            basket.add(count)
        }
        #When("I eat {int} cukes") { (count: Int) in
            basket.eat(count)
        }
    }
}
```

### With Swift Testing

With the Swift Testing runner, import `CucumberSwiftTestingMacros`. Because `Cucumber` and `StepImplementation` both come from `CucumberSwiftTesting`, Swift 6 asks you to mark the conformance `@retroactive`:

```swift
import CucumberSwiftTestingMacros
import Testing

extension Cucumber: @retroactive StepImplementation {
    public func setupSteps() {
        #Given("I have {int} cukes") { (count: Int) in
            Basket.shared.add(count)
        }
        #Then("the basket has {int} cukes") { (count: Int) in
            #expect(Basket.shared.count == count)
        }
    }
}
```

The macros work the same with both runners, localized macros included (see <doc:Using-Step-Definition-Macros#Keywords-in-other-languages>). <doc:Running-Feature-Files-With-Swift-Testing> describes the Swift Testing runner.

### Cucumber expressions

The closure takes one argument for each parameter of a Cucumber expression, or each capture group of a regular expression, in the order they appear. Give each argument its type:

| In the pattern | The argument's type |
|---|---|
| `{int}` | `Int` |
| `{float}` | `Float` |
| `{double}` | `Double` |
| `{string}`, `{word}` or `{}` | `String` |
| A capture group, in a pattern that starts with `^`, ends with `$` or is written between `/` | `String` |
| A custom parameter type, such as `{color}` | The parameter's output type |

The types must be written out. Swift checks a macro's arguments before the macro runs, so it cannot work them out from the pattern. If one is wrong, the macro tells you which type to use, for the built-in parameter types: `{int}`, `{float}`, `{double}`, `{string}`, `{word}` and `{}`. For a custom parameter type, the compiler checks the type against the parameter's output, and its error is Swift's own, inside the macro's expansion.

To read the step itself, for example its data table or doc string, add a last argument of type `Step`:

<!-- swift-example: steps -->
```swift
#When("I eat {int} cukes") { (count: Int, step: Step) in
    XCTAssertNotNil(step.dataTable, "List the cukes in a data table.")
    basket.eat(count)
}
```

A closure can be `async` and `throws`, and can have a capture list, exactly as with ``Given``. Async steps run as they do without the macros, and from 6.6.0 they can call XCUI in a UI test target: see <doc:Matching-Steps#Async-steps>, whose **UI tests** item says how they behave.

<!-- swift-example: steps -->
```swift
#Then("^the basket holds (\\d+) cukes?$") { [basket] (count: String) async throws in
    try await basket.waitForCount(Int(count))
}
```

### Regex literals

The macros take a regex literal too, `#/…/#`, or `/…/` where your target allows bare regex literals, as the Swift 6 language mode does. The step matches when the regex matches its whole text, exactly as with ``Given``'s regex literal form.

For the step `Given I have 5 cukes`:

<!-- swift-example: steps -->
```swift
#Given(#/^I have (?<count>\d+) cukes$/#) { (count: Substring) in
    basket.add(Int(count) ?? 0)
}
```

The closure takes one argument per capture group, in order, and optionally the `Step` last. Each argument's type is the capture's type in the regex's `Output`, as Swift gives it:

| In the regex | The argument's type |
|---|---|
| A capture group, numbered or named | `Substring` |
| A capture group that may not take part in the match: in an alternation, such as `(a)\|(b)`, or repeated zero or more times, such as `(\d+)?` or `(,\d+)*` | `Substring?` |

Every group counts, including one inside another: `#/^((\d+) red) cukes$/#` gives two arguments. A string pattern read as a regular expression, such as `"^((\\d+) red) cukes$"`, gives only its outer group. A named group's name doesn't need to match the argument's.

A capture is always text, which the closure converts itself. For typed arguments, such as an `Int` from `{int}` or a type of your own from a custom parameter type, use a Cucumber expression: it is the recommended pattern, and <doc:Matching-Steps#Choose-a-pattern> compares the three kinds.

Regex literals need iOS 16, macOS 13, tvOS 16 or watchOS 9 at run time. A macro with a regex literal in code that can run on earlier versions is a compile error that says so, and Xcode offers to add `@available` to that code.

### Custom parameter types

A custom parameter type, such as `{airport}`, needs no extra declaration. The macro reads it as `\.airport` on `Match`, through the extension you already write for it (see <doc:Matching-Steps#Matching-with-Cucumber-Expressions>), and the argument's type is the parameter's output:

<!-- swift-example: steps -->
```swift
#Given("there are {int} flights from {airport}") { (count: Int, airport: Airport) in
    XCTAssertIdentical(airport, Airport.lax)
}
```

The compiler checks the argument's type against the parameter's output. The parameter's name must be a valid Swift identifier. `{bigdecimal}`, `{biginteger}`, `{byte}`, `{short}` and `{long}` aren't built in, so the macros read them as custom parameter types too, and each needs an accessor of its name on `Match`.

### Keywords in other languages

`#Given`, `#When`, `#Then`, `#And` and `#But` fit steps with those keywords, and `#MatchAll` fits every step, exactly as ``Given``, ``When``, ``Then``, ``And``, ``But`` and ``MatchAll`` do. A step written with `*`, or with a keyword in another language, matches as it does without macros. See <doc:Matching-Steps#When-more-than-one-step-definition-matches-a-step>.

Every localized step definition has a macro too, with the same name: `#ES_Dado` for ``ES_Dado``, `#FR_Quand` for `FR_Quand`, and so on. `CucumberSwiftMacros` and the Swift Testing runner's `CucumberSwiftTestingMacros` both have them.

<!-- swift-example: steps -->
```swift
#ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
    cesta.añadir(cantidad)
}
```

### Hooks

The hooks have macros too, `#BeforeFeature`, `#AfterFeature`, `#BeforeScenario`, `#AfterScenario`, `#BeforeStep` and `#AfterStep`, so a step definition file can be written in one style. Each expands to the hook function of the same name, with the same `priority:` and closure, so it runs exactly as that does: in the same order, on the main actor, and failing the same way when it throws. The closure takes the hook's `Feature`, `Scenario` or `Step`, or no argument, and may be `async throws`:

<!-- swift-example: steps -->
```swift
#BeforeScenario {
    try await server.reset()
}
#AfterScenario(priority: 1) { (scenario: Scenario) in
    print("Finished \(scenario.title)")
}
#BeforeStep { @MainActor step async throws in
    try await basket.waitForCount(nil)
    print("Running \(step.match)")
}
```

The compiler checks the closure where you write it: a closure with more than one argument, or an argument of another type, is an error that names the type the hook passes, with a fix. The hook functions keep working, and a project can use both. Tagged hooks have no macro.

## Convert existing step definitions

The **Convert to Gherkin Macros** command rewrites step definitions written as ``Given`` and the like as macros, wherever a macro expands to the same step definition, and hook calls such as `BeforeScenario { … }` as their macros. <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros> says how to run it, what it converts and what it leaves, and <doc:Running-Tests-In-Xcode#Convert-a-file-a-folder-or-everything> how to convert one file, one folder or everything.

What it leaves for you to do:

- **Set the project up first.** It never edits `Package.swift`, `Project.swift` or the Xcode project, so turn the trait on and add the macros product as described above. Until you do, it stops and says what to change.
- **Convert what it leaves by hand.** It marks each step definition it can't convert with a `#warning` that gives the reason. <doc:Running-Tests-In-Xcode#What-it-leaves> lists the reasons.
- **Trust the macros** the first time you build the converted code (see <doc:Using-Step-Definition-Macros#Xcode-asks-you-to-trust-the-macros>).
- **Review and build.** Check the changes with your version control, and build your tests: a macro reports a mistake the original only found when the tests ran.

## Step definitions for undefined steps

Once a test target links the macros, CucumberSwift suggests a macro for each step that has no step definition, with either runner, rather than a function. See <doc:Matching-Steps#Step-definition-macros>.

## Troubleshooting

### Xcode asks you to trust the macros

The first time you build a macro, Xcode stops with a warning that the macro must be enabled, and each macro in your code shows an error that its implementation could not be found. Click the warning and choose **Trust & Enable**: <doc:Running-Tests-In-Xcode#Trust-the-plugins> shows both. `swift build` and `swift test` don't ask.

### The build fails in CI

On a CI machine, nobody can answer Xcode's request to trust a macro, so pass `-skipMacroValidation` to `xcodebuild`, and `-skipPackagePluginValidation` if a target applies CucumberSwift's plugins. The same goes for a project that Tuist generates. <doc:Running-Tests-In-Xcode#Build-an-Xcode-project-in-CI> has the command.

### Each macro says to turn the Macros trait on

The trait isn't on for CucumberSwift, or your Xcode doesn't apply it. Turn it on as described for your kind of project above. In an Xcode project or a Tuist project, setting it on the package needs Xcode 26.4 or later: with an earlier Xcode, use the `MacrosTrait` local package (see <doc:Using-Step-Definition-Macros#Before-Xcode-264>).

### swift-syntax can't be resolved

Before Swift 6.4, SwiftPM can fail to resolve swift-syntax when you add CucumberSwift by URL with the trait on: see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>.

### Another macro package needs a different swift-syntax

SwiftPM picks one swift-syntax version for all your packages, so every package that depends on it must accept that version. When the ranges don't overlap, resolving fails:

```
error: Dependencies could not be resolved because root depends on 'swift-syntax' 509.0.0..<510.0.0 and 'cucumberswift' depends on 'swift-syntax' 600.0.0..<605.0.0.
```

The message names the two ranges that conflict, and the package each comes from: here, your own `Package.swift`, which asks for 509, and CucumberSwift, which accepts 600 up to, but not including, 605. To fix it:

- **Widen your own range** when it is yours, as here, so that it overlaps 600.0.0..<605.0.0.
- **Update the other package** to a release whose range overlaps CucumberSwift's. Most macro packages have moved to 600 or later.
- **Keep the macros out of that package.** If the other package can't move yet, leave the trait off where it is used, and write step definitions with ``Given`` and the like: they need no swift-syntax.

### Multiple commands produce swift-syntax.build

A build fails with many errors like this one:

```
error: Multiple commands produce '…/Build/Intermediates.noindex/swift-syntax.build/Debug/SwiftSyntax.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata'
```

The project builds swift-syntax twice, into the same folder: once through Xcode's own package integration, for the packages in `Project.packages` (or the project's package dependencies) such as CucumberSwift, and once through Tuist's integration, for a package in `Tuist/Package.swift` that targets reach with `.external(name:)` and that depends on swift-syntax, such as another macro package. It shows only when Xcode compiles swift-syntax itself for its own integration, rather than using a prebuilt one (see <doc:Using-Step-Definition-Macros#The-first-build>), so a project can build for a while and then fail after a change of Xcode or of swift-syntax version.

Build swift-syntax once: add every package that depends on swift-syntax through Xcode's integration, next to CucumberSwift in `Project.packages`, and depend on its products with `.package(product:)` instead of `.external(name:)`:

<!-- swift-example: fragment: a Tuist Project.swift, which needs Tuist; it shows a package moved out of Tuist/Package.swift -->
```swift
let project = Project(
    name: "MyApp",
    packages: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift", from: "6.4.0", traits: ["Macros"]),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"605.0.0"),
        // Moved here from Tuist/Package.swift, because it depends on swift-syntax too.
        .package(url: "https://github.com/example/OtherMacros", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "MyAppTests",
            // …
            dependencies: [
                .package(product: "CucumberSwiftMacros"),
                .package(product: "OtherMacros")    // was .external(name: "OtherMacros")
            ])
    ]
)
```

Then remove the package from `Tuist/Package.swift`, and run `tuist install` and `tuist generate` again. Packages that don't depend on swift-syntax can stay where they are.

## See Also

- <doc:Checking-Step-Definitions>
- <doc:Running-Feature-Files-With-Swift-Testing>
- <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros>
- <doc:Matching-Steps>
