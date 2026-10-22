# Using the step definition macros

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

Set up the step definition macros in a Swift package, an Xcode project or a Tuist project, write step definitions with them, and fix what goes wrong.

## Overview

The step definition macros, `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`, are another way to write the step definitions that you would write with ``Given``, ``When`` and the like. The closure takes one argument for each parameter in the pattern, already converted to its type, instead of reading each one from `match`:

<!-- swift-example: steps -->
```swift
#Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
    basket.add(count, to: container)
}
```

The compiler checks each pattern and closure where you write it, and offers a fix for the common mistakes. See <doc:Checking-Step-Definitions>. Each macro expands to the step definition that you would otherwise write by hand, so steps match and run in the same way. Your feature files, hook functions and existing step definitions keep working, and you can mix both styles in one target.

This article describes what the macros need, how to set them up for each kind of project, and how to write step definitions with them for XCTest and for Swift Testing. It then covers converting the step definitions you have, and troubleshooting.

## Requirements

| | In a Swift package | In an Xcode project |
|---|---|---|
| Xcode | 16.3 (Swift 6.1) or later | 26.4 or later |
| swift-syntax | 600.0.0 up to, but not including, 605.0.0 | 600.0.0 up to, but not including, 605.0.0 |
| Where the tests run | iOS 13, macOS 10.15 and tvOS 13 or later | iOS 13, macOS 10.15 and tvOS 13 or later |
| Where step definitions with a regex literal run | iOS 16, macOS 13 and tvOS 16 or later | iOS 16, macOS 13 and tvOS 16 or later |

The notes below explain the requirements:

- **Both are tested.** CI builds and tests a Swift package that uses the macros with exactly Xcode 16.3, and a Tuist project that uses them with exactly Xcode 26.4, on macOS 15 and macOS 26 build machines. Nothing else is claimed. The macOS that an Xcode needs is Apple's requirement for that Xcode.
- **In a Swift package**, you need Swift 6.1, the first version with package traits. The macros are behind a trait.
- **In an Xcode project**, you need Xcode 26.4, the first version that can turn on a package dependency's traits in a project. With an earlier Xcode, turn the trait on from a local package, as <doc:Using-Step-Definition-Macros#Before-Xcode-264> describes. Or run your tests from a Swift package, as <doc:Running-Tests-With-Swift-Package-Manager> describes.
- **In a Tuist project**, the Xcode project's requirement applies. You also need Tuist 4.203.0 or later to set the trait in `Project.swift`. See <doc:Using-Step-Definition-Macros#Set-up-a-Tuist-project>.
- **Convert to Gherkin Macros** (see <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros>) is tested in the same way in a Swift package. CI runs the command with exactly Xcode 16.3. In an Xcode project, the command needs the trait on, so it needs Xcode 26.4, as the macros do. But CI doesn't run the command there.
- **swift-syntax 600 to 604.** SwiftPM picks one swift-syntax version for your whole package, so the macros accept any version in that range. Your package can also use another macro package, as long as the two ranges overlap. CI tests the macros every night with the oldest version, 600.0.0, and on every change with the version that CucumberSwift's own `Package.resolved` pins. Versions before 600 don't build.
- **The tests run wherever CucumberSwift runs.** A macro expands into an ordinary step definition when your code compiles, so it adds nothing at run time.
- **Regex literals need iOS 16, macOS 13 or tvOS 16**, as Swift's `Regex` does, with or without the macros. Below those versions, mark the code that uses them with `@available(iOS 16, macOS 13, tvOS 16, *)`, or use a string pattern. See <doc:Using-Step-Definition-Macros#Regex-literals>.
- **Swift Package Manager only.** Carthage builds CucumberSwift from its Xcode project, which can't deliver macros. So a Carthage install keeps the step definition functions.

## Set up a Swift package

To use the macros in a Swift package, turn on CucumberSwift's `Macros` trait in your `Package.swift`, declare swift-syntax as well, and depend on the `CucumberSwiftMacros` product:

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

Then `import CucumberSwiftMacros` where you write step definitions. It imports CucumberSwift and CucumberSwiftExpressions as well. Once you use Swift 6.4 or later, you can remove the swift-syntax dependency. See <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>.

The macros are a separate product, `CucumberSwiftMacros`, behind a package trait named `Macros`. They need the swift-syntax package, which SwiftPM downloads only when the trait is on. With Swift 6.2, a package that doesn't turn the trait on doesn't download swift-syntax. Swift 6.1 may still record a pin for it in `Package.resolved`, because the dependency is declared, but it doesn't build it.

To run your feature files with Swift Testing instead, depend on `CucumberSwiftTestingMacros` instead of `CucumberSwiftMacros`, and apply its plugin. <doc:Running-Feature-Files-With-Swift-Testing#Set-up-a-Swift-package> shows the manifest.

## Set up an Xcode project

With Xcode 26.4 or later, follow these steps:

1. Add the CucumberSwift package with **File > Add Package Dependencies…**, and turn on the `Macros` trait in the package dependency's settings.
2. Add the swift-syntax package to the project as well, without adding any of its products to a target, as <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64> describes.
3. Add `CucumberSwiftMacros` to your test target, or `CucumberSwiftTestingMacros` for Swift Testing (see <doc:Running-Feature-Files-With-Swift-Testing#Set-up-an-Xcode-project>), and `import` it where you write step definitions.

### Before Xcode 26.4

Before Xcode 26.4, an Xcode project can't turn on a package's traits. But a Swift package that the project depends on can turn them on in its own `Package.swift`, with any Xcode that has Swift 6.1. SwiftPM then builds CucumberSwift with the trait for the whole project. So add a small local package that does only that:

```swift
// swift-tools-version:6.1
// MacrosTrait/Package.swift, next to your Xcode project.
import PackageDescription

let package = Package(
    name: "MacrosTrait",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
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

Add the folder to your project as a local package with **File > Add Package Dependencies… > Add Local…**, without adding its product to any target. Then add CucumberSwift to the project as usual, without the trait. Add the swift-syntax package to the project too, not to `MacrosTrait` (see <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>). Add `CucumberSwiftMacros` or `CucumberSwiftTestingMacros` to your test target, and `import` it, exactly as with Xcode 26.4.

When you move to Xcode 26.4 or later, remove `MacrosTrait` and turn the trait on in the project instead. Your step definitions don't change.

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

Tuist writes the trait into the Xcode project that it generates, so it needs the same Xcode as any Xcode project, 26.4 or later. The `traits:` parameter is new in Tuist 4.203.0, so with an earlier Tuist, `Project.swift` doesn't compile with it. CI generates and tests a project like this one with Xcode 26.4 and the Tuist version that CucumberSwift pins.

With a Tuist earlier than 4.203.0, or an Xcode earlier than 26.4, turn the trait on from the `MacrosTrait` local package instead, as <doc:Using-Step-Definition-Macros#Before-Xcode-264> describes, and list it with the project's other packages:

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

The targets depend on `CucumberSwiftMacros` from CucumberSwift, exactly as with the `traits:` parameter, so moving to the parameter later changes only the `packages` list. CI tests this setup with Xcode 16.3, the oldest Xcode it supports, and with the Xcode it tests by default.

If your project also uses Tuist's own integration for some packages, the ones in `Tuist/Package.swift` that targets reach with `.external(name:)`, see <doc:Using-Step-Definition-Macros#Multiple-commands-produce-swift-syntaxbuild>.

## The first build

The first time you build a macro, Xcode asks you to trust and enable it (see <doc:Using-Step-Definition-Macros#Xcode-asks-you-to-trust-the-macros>). A clean build also compiles swift-syntax. Xcode 26 and Swift 6.2 or later can use a prebuilt swift-syntax instead. They do so only when swift.org publishes one for both your toolchain and the swift-syntax version that your package resolves, and not in every build even then. Swift 6.1 always compiles swift-syntax.

## Declare swift-syntax before Swift 6.4

Before Swift 6.4, SwiftPM leaves swift-syntax out when it resolves CucumberSwift from its URL with the `Macros` trait on, so resolving fails:

```
error: exhausted attempts to resolve the dependencies graph, with the following dependencies unresolved:
* 'swift-syntax' from https://github.com/swiftlang/swift-syntax.git
```

This is a SwiftPM bug, fixed in Swift 6.4 ([swift-package-manager#10409](https://github.com/swiftlang/swift-package-manager/pull/10409)). Until you use Swift 6.4 or later, declare swift-syntax yourself, next to CucumberSwift, with a range that overlaps the one CucumberSwift accepts (see <doc:Using-Step-Definition-Macros#Requirements>). Nothing needs to use it. Declaring it is enough for SwiftPM to resolve it. Declare it in one of these places:

- **In a Swift package**, add it to the `dependencies` of the `Package.swift` that turns the trait on, as in <doc:Using-Step-Definition-Macros#Set-up-a-Swift-package>.
- **In an Xcode project**, add it to the project's packages, without adding any of its products to a target. In Xcode, use **File > Add Package Dependencies…**. In Tuist, add it to `Project.packages`. This holds whether the project turns the trait on itself, with Xcode 26.4 or later, or through `MacrosTrait` (see <doc:Using-Step-Definition-Macros#Before-Xcode-264>). Declaring it in `MacrosTrait` doesn't help.

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
        #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
            basket.add(count, to: container)
        }
        #When("I eat {int} cukes") { (count: Int) in
            basket.eat(count)
        }
    }
}
```

### With Swift Testing

With the Swift Testing runner, import `CucumberSwiftTestingMacros`. `Cucumber` and `StepImplementation` both come from `CucumberSwiftTesting`, so Swift 6 asks you to mark the conformance `@retroactive`:

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

The macros work the same with both runners, including localized macros (see <doc:Using-Step-Definition-Macros#Keywords-in-other-languages>). <doc:Running-Feature-Files-With-Swift-Testing> describes the Swift Testing runner.

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

Write the types out. Swift checks a macro's arguments before the macro runs, so it can't work them out from the pattern. If a type is wrong for a built-in parameter type, `{int}`, `{float}`, `{double}`, `{string}`, `{word}` or `{}`, the macro tells you which type to use. For a custom parameter type, the compiler checks the type against the parameter's output, and the error is Swift's own, inside the macro's expansion.

To read the step itself, for example its data table or doc string, add a last argument of type `Step`:

<!-- swift-example: steps -->
```swift
#When("I eat {int} cukes") { (count: Int, step: Step) in
    XCTAssertNotNil(step.dataTable, "List the cukes in a data table.")
    basket.eat(count)
}
```

A closure can be `async` and `throws`, and can have a capture list, exactly as with ``Given``. Async steps run as they do without the macros, and from 6.6.0 they can call XCUI in a UI test target. See <doc:Matching-Steps#Async-steps>, whose **UI tests** item says how they behave. This step definition is async and has a capture list:

<!-- swift-example: steps -->
```swift
#Then("^the basket holds (\\d+) cukes?$") { [basket] (count: String) async throws in
    try await basket.waitForCount(Int(count))
}
```

### Regex literals

The macros take a regex literal too: `#/…/#`, or `/…/` where your target allows bare regex literals, as the Swift 6 language mode does. The step matches when the regex matches its whole text, exactly as with ``Given``'s regex literal form:

<!-- swift-example: steps -->
```swift
#Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { (count: Substring, container: Substring) in
    basket.add(Int(count) ?? 0, to: String(container))
}
```

The closure takes one argument for each capture group, in order, and optionally the `Step` last. Each argument's type is the capture's type in the regex's `Output`, as Swift gives it:

| In the regex | The argument's type |
|---|---|
| A capture group, numbered or named | `Substring` |
| A capture group that may not take part in the match: in an alternation, such as `(a)\|(b)`, or repeated zero or more times, such as `(\d+)?` or `(,\d+)*` | `Substring?` |

Every group counts, including one inside another: `#/^((\d+) red) cukes$/#` gives two arguments. A string pattern read as a regular expression, such as `"^((\\d+) red) cukes$"`, gives only its outer group. A named group's name doesn't need to match the argument's.

A capture is always text, which the closure converts itself. For typed arguments, such as an `Int` from `{int}` or a type of your own from a custom parameter type, use a Cucumber expression. Cucumber expressions are the recommended pattern, and <doc:Matching-Steps#Choose-a-pattern> compares the three kinds.

Regex literals need iOS 16, macOS 13 or tvOS 16 at run time. A macro with a regex literal in code that can run on earlier versions is a compile error that says so, and Xcode offers to add `@available` to that code.

### Custom parameter types

A custom parameter type, such as `{airport}`, needs no extra declaration. The macro reads it as `\.airport` on `Match`, through the extension that you already write for it (see <doc:Matching-Steps#Matching-with-Cucumber-expressions>). The argument's type is the parameter's output:

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

The hooks have macros too: `#BeforeFeature`, `#AfterFeature`, `#BeforeScenario`, `#AfterScenario`, `#BeforeStep` and `#AfterStep`. With them, you can write a step definition file in one style. Each macro expands to the hook function of the same name, with the same `priority:` and closure. So it runs exactly as the function does: in the same order, on the main actor, and failing in the same way when it throws. The closure takes the hook's `Feature`, `Scenario` or `Step`, or no argument, and may be `async throws`:

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

The compiler checks the closure where you write it. A closure with more than one argument, or an argument of another type, is an error that names the type that the hook passes, and offers a fix. The hook functions keep working, and a project can use both. Tagged hooks have no macro.

## Convert existing step definitions

The **Convert to Gherkin Macros** command rewrites step definitions written with ``Given`` and the like as macros, wherever a macro expands to the same step definition. It also rewrites hook calls, such as `BeforeScenario { … }`, as their macros. <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros> describes how to run it, what it converts and what it leaves. <doc:Running-Tests-In-Xcode#Convert-a-file-a-folder-or-everything> describes how to convert one file, one folder or everything.

The command leaves these things for you to do:

- **Set the project up first.** The command never edits `Package.swift`, `Project.swift` or the Xcode project, so turn the trait on and add the macros product as described above. Until you do, the command stops and says what to change.
- **Convert what it leaves by hand.** The command marks each step definition that it can't convert with a `#warning` that gives the reason. <doc:Running-Tests-In-Xcode#What-it-leaves> lists the reasons.
- **Trust the macros.** Xcode asks the first time you build the converted code (see <doc:Using-Step-Definition-Macros#Xcode-asks-you-to-trust-the-macros>).
- **Review and build.** Check the changes with your version control, and build your tests. A macro reports a mistake that the original found only when the tests ran.

## Step definitions for undefined steps

Once a test target links the macros, CucumberSwift suggests a macro, not a function, for each step that has no step definition, with either runner. See <doc:Matching-Steps#Step-definition-macros>.

## Troubleshooting

### Xcode asks you to trust the macros

The first time you build a macro, Xcode stops with a warning that the macro must be enabled, and each macro in your code shows an error that its implementation couldn't be found. Click the warning and choose **Trust & Enable**. <doc:Running-Tests-In-Xcode#Trust-the-plugins> shows both. `swift build` and `swift test` don't ask.

### The build fails in CI

On a CI machine, nobody can answer Xcode's request to trust a macro. So pass `-skipMacroValidation` to `xcodebuild`, and `-skipPackagePluginValidation` if a target applies CucumberSwift's plugins. The same goes for a project that Tuist generates. <doc:Running-Tests-In-Xcode#Build-an-Xcode-project-in-CI> has the command.

### Each macro says to turn the Macros trait on

The trait isn't on for CucumberSwift, or your Xcode doesn't apply it. Turn it on as described above for your kind of project. In an Xcode project or a Tuist project, setting it on the package needs Xcode 26.4 or later. With an earlier Xcode, use the `MacrosTrait` local package (see <doc:Using-Step-Definition-Macros#Before-Xcode-264>).

### swift-syntax can't be resolved

Before Swift 6.4, SwiftPM can fail to resolve swift-syntax when you add CucumberSwift by URL with the trait on. See <doc:Using-Step-Definition-Macros#Declare-swift-syntax-before-Swift-64>.

### Another macro package needs a different swift-syntax

SwiftPM picks one swift-syntax version for all your packages, so every package that depends on it must accept that version. When the ranges don't overlap, resolving fails:

```
error: Dependencies could not be resolved because root depends on 'swift-syntax' 509.0.0..<510.0.0 and 'cucumberswift' depends on 'swift-syntax' 600.0.0..<605.0.0.
```

The message names the two ranges that conflict, and the package that each comes from. Here, they're your own `Package.swift`, which asks for 509, and CucumberSwift, which accepts 600 up to, but not including, 605. To fix it, do one of these things:

- **Widen your own range** when it's yours, as here, so that it overlaps 600.0.0..<605.0.0.
- **Update the other package** to a release whose range overlaps CucumberSwift's. Most macro packages have moved to 600 or later.
- **Keep the macros out of that package.** If the other package can't move yet, leave the trait off where it's used, and write step definitions with ``Given`` and the like, which need no swift-syntax.

### Multiple commands produce swift-syntax.build

A build fails with many errors like this one:

```
error: Multiple commands produce '…/Build/Intermediates.noindex/swift-syntax.build/Debug/SwiftSyntax.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata'
```

The project builds swift-syntax twice, into the same folder. It builds it once through Xcode's own package integration, for the packages in `Project.packages` (or the project's package dependencies), such as CucumberSwift. It builds it again through Tuist's integration, for a package in `Tuist/Package.swift` that targets reach with `.external(name:)` and that depends on swift-syntax, such as another macro package. The error shows only when Xcode compiles swift-syntax itself for its own integration, instead of using a prebuilt one (see <doc:Using-Step-Definition-Macros#The-first-build>). So a project can build for a while, and then fail after a change of Xcode or of swift-syntax version.

To build swift-syntax once, add every package that depends on swift-syntax through Xcode's integration, next to CucumberSwift in `Project.packages`. Depend on its products with `.package(product:)` instead of `.external(name:)`:

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
