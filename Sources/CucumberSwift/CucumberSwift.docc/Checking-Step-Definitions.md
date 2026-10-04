# Checking Step Definitions When They Compile

Write step definitions as macros, and the compiler checks each pattern and closure where you write it, and offers a fix for the common mistakes.

## Overview

A step definition written with ``Given``, ``When`` or ``Then`` is only checked when the tests run. A Cucumber expression that is missing a `}`, a regular expression that will not compile, or a closure that reads the wrong parameter shows up as a failure after a full build and test launch.

The step definition macros, `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`, check the same things while your code compiles:

```swift
import CucumberSwiftMacros

extension Cucumber: StepImplementation {
    public func setupSteps() {
        #Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
            basket.add(count, to: container)
        }
    }
}
```

The closure takes one argument per parameter in the expression, already converted to its type. A mistake is a compile error on the line that has it, and where the fix is clear, Xcode offers to make it for you.

Each macro expands to the step definition you would otherwise write by hand, so nothing about how steps match or run changes. Feature files, hooks and the step definitions you already have keep working, and you can mix both styles in one target.

## Requirements

| | In a Swift package | In an Xcode project, or one Tuist generates |
|---|---|---|
| Xcode | 16.3 (Swift 6.1) or later | 26.4 or later |
| macOS to build on | 15.2 or later | 26.2 or later |
| Where the tests run | iOS 13, macOS 10.15 and tvOS 13 or later | iOS 13, macOS 10.15 and tvOS 13 or later |

- **In a Swift package**, you need Swift 6.1, the first version with package traits, which the macros are behind.
- **In an Xcode project**, you need Xcode 26.4, the first to turn on a package dependency's traits in a project. With an earlier Xcode, turn the trait on from a local package, as described in <doc:Checking-Step-Definitions#Use-the-macros-in-an-Xcode-project-before-Xcode-264>, or run your tests from a Swift package, as described in <doc:Running-Tests-With-Swift-Package-Manager>.
- **The tests run wherever CucumberSwift runs.** A macro expands into an ordinary step definition when your code compiles, so it adds nothing at run time.
- **Swift Package Manager only.** Carthage builds CucumberSwift from its Xcode project, which cannot deliver macros, so a Carthage install keeps the step definition functions.

## Add the macros to your package

The macros are a separate product, `CucumberSwiftMacros`, behind a package trait named `Macros` (see <doc:Checking-Step-Definitions#Requirements>). They need the swift-syntax package, which SwiftPM downloads only when the trait is on. A package that does not turn the trait on never downloads swift-syntax.

In your `Package.swift`, turn the trait on and depend on the product:

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
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")],
            resources: [.copy("Features")],
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
    ]
)
```

Then `import CucumberSwiftMacros` where you write step definitions. It imports CucumberSwift and CucumberSwiftExpressions as well.

In an Xcode project, turn on the `Macros` trait in the CucumberSwift package dependency's settings, then add `CucumberSwiftMacros` to your test target. This needs Xcode 26.4 or later: see <doc:Checking-Step-Definitions#Requirements>. With an earlier Xcode, turn the trait on from a local package instead: see <doc:Checking-Step-Definitions#Use-the-macros-in-an-Xcode-project-before-Xcode-264>.

In a project that Tuist generates, turn the trait on where the project lists its packages, and depend on the product:

```swift
let project = Project(
    name: "MyApp",
    packages: [
        .package(url: "https://github.com/cucumberswift/CucumberSwift", from: "6.4.0", traits: ["Macros"])
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

Tuist writes the trait into the Xcode project it generates, so it needs the same Xcode as any Xcode project. If the trait is off, or your Xcode does not apply it, each macro you use is an error that says to turn the `Macros` trait on.

### Use the macros in an Xcode project before Xcode 26.4

Before Xcode 26.4, an Xcode project can't turn on a package's traits, but a Swift package that the project depends on can, in its own `Package.swift`, with any Xcode that has Swift 6.1. SwiftPM then builds CucumberSwift with the trait for the whole project. So add a small local package that does only that:

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

Add the folder to your project as a local package: in Xcode, **File > Add Package Dependencies… > Add Local…**, without adding its product to any target; in Tuist, `.package(path: "MacrosTrait")` in `Project.packages`. Then add CucumberSwift to the project as usual, without the trait, add `CucumberSwiftMacros` to your test target, and `import CucumberSwiftMacros`, exactly as with Xcode 26.4. When you move to Xcode 26.4 or later, remove `MacrosTrait` and turn the trait on in the project instead; your step definitions don't change.

The same package turns the trait on for the Swift Testing runner's `CucumberSwiftTestingMacros`; see <doc:Running-Feature-Files-With-Swift-Testing>.

The first time you build a macro, Xcode asks you to trust and enable it. Recent versions of Xcode and SwiftPM download swift-syntax prebuilt, so it does not slow the build down.

## Write a step definition

Each macro takes the pattern, a string literal, and a closure. The closure takes one argument for each parameter of a Cucumber expression, or each capture group of a regular expression, in the order they appear. Give each argument its type:

| In the pattern | The argument's type |
|---|---|
| `{int}` | `Int` |
| `{float}` | `Float` |
| `{double}` | `Double` |
| `{string}`, `{word}` or `{}` | `String` |
| A capture group, in a pattern that starts with `^`, ends with `$` or is written between `/` | `String` |
| A custom parameter type, such as `{color}` | The parameter's output type |

The types must be written out. Swift checks a macro's arguments before the macro runs, so it cannot work them out from the pattern. If one is wrong, the macro tells you which type to use.

To read the step itself, for example its data table or doc string, add a last argument of type `Step`:

```swift
#When("I eat {int} cukes") { (count: Int, step: Step) in
    XCTAssertNotNil(step.dataTable, "List the cukes in a data table.")
    basket.eat(count)
}
```

A closure can be `async` and `throws`, and can have a capture list, exactly as with ``Given``. See <doc:Matching-Steps#Async-steps>.

```swift
#Then("^the basket holds (\\d+) cukes?$") { [weak self] (count: String) async throws in
    try await self?.basket.waitForCount(Int(count))
}
```

### Custom parameter types

A custom parameter type, such as `{color}`, needs no extra declaration. The macro reads it as `\.color` on `Match`, through the extension you already write for it, and the compiler checks the argument's type against the parameter's output. The parameter's name must be a valid Swift identifier.

### Keywords

`#Given`, `#When`, `#Then`, `#And` and `#But` fit steps with those keywords, and `#MatchAll` fits every step, exactly as ``Given``, ``When``, ``Then``, ``And``, ``But`` and ``MatchAll`` do. A step written with `*`, or with a keyword in another language, matches as it does without macros. See <doc:Matching-Steps#When-more-than-one-step-definition-matches-a-step>.

Every localized step definition has a macro too, with the same name: `#ES_Dado` for ``ES_Dado``, `#FR_Quand` for `FR_Quand`, and so on.

```swift
#ES_Dado("tengo {int} pepinos") { (cantidad: Int) in
    cesta.añadir(cantidad)
}
```

## Mistakes the compiler finds

Each mistake is an error on its own line. Click the error's icon to see the whole message and, where there is one, the fix: click **Apply** to make the change.

![A Swift file in Xcode with four step definition macros marked as errors, each message shown on its line: the pattern has 2 parameters but the closure takes 1 argument; {int} gives Int but 'count' is declared as String; the '{' does not have a matching '}'; and a pattern ending in "$" is treated as a regular expression that is not valid.](CheckingStepDefinitions-FixIt.png)

| Mistake | Example | Fix |
|---|---|---|
| The closure takes too few or too many arguments | `#Given("I have {int} cukes in my {string}") { (count: Int) in … }` | Changes the closure's arguments to `(count: Int, string: String)` |
| An argument has the wrong type | `#Given("I have {int} cukes") { (count: String) in … }` | Changes `String` to `Int` |
| A parameter is missing its `}` | `#Given("I have {int cukes")` | Inserts `}` after `{int` |
| Any other Cucumber expression that does not follow the syntax, such as empty optional text or a parameter inside optional text | `#Given("I have () cukes")` | None: the error says what is wrong and how to fix it |
| A pattern that is read as a regular expression does not compile | `#Given("I have {int} cukes$")`, where the `$` makes it a regular expression | Removes the `^`, `$` or slashes, when what is left is a valid Cucumber expression |
| The pattern is not a string literal | `#Given("I have \(count) cukes")` | None: write the pattern out |

A pattern that compiles but matches no step in your feature files is not a compile error: macros cannot read files. <doc:Checking-Feature-Files> reports those steps while you build.

## See what a macro does

In Xcode, right-click a macro and choose **Expand Macro**. The expansion is the step definition the macro stands for, and you can set breakpoints in it:

```swift
Given("I have {int} cukes in my {string}" as CucumberExpression) { match, _ in
    let count: Int = try match.first(\.int)
    let container: String = try match.first(\.string)
    basket.add(count, to: container)
}
```

It reads the parameters the same way as the step definitions CucumberSwift generates for undefined steps (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>). A parameter type that the pattern uses more than once is read by position, such as `match[\.int, index: 1]`.
