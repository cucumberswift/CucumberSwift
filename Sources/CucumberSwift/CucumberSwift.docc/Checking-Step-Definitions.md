# Checking Step Definitions When They Compile

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

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
| Where the tests run | iOS 13, macOS 10.15 and tvOS 13 or later | iOS 13, macOS 10.15 and tvOS 13 or later |
| Where step definitions with a regex literal run | iOS 16, macOS 13 and tvOS 16 or later | iOS 16, macOS 13 and tvOS 16 or later |

- **Both are tested.** CI builds and tests a Swift package that uses the macros with exactly Xcode 16.3, and a Tuist project that uses them with exactly Xcode 26.4, on macOS 15 and macOS 26 build machines. Nothing else is claimed: the macOS an Xcode needs is Apple's requirement for that Xcode.
- **In a Swift package**, you need Swift 6.1, the first version with package traits, which the macros are behind.
- **In an Xcode project**, you need Xcode 26.4, the first to turn on a package dependency's traits in a project. With an earlier Xcode, turn the trait on from a local package, as described in <doc:Checking-Step-Definitions#Use-the-macros-in-an-Xcode-project-before-Xcode-264>, or run your tests from a Swift package, as described in <doc:Running-Tests-With-Swift-Package-Manager>.
- **Convert to Gherkin Macros** (see <doc:Checking-Step-Definitions#Convert-existing-step-definitions>) is tested the same way in a Swift package: CI runs the command with exactly Xcode 16.3. In an Xcode project it needs the trait on, so Xcode 26.4, as the macros do, but CI doesn't run the command there.
- **The tests run wherever CucumberSwift runs.** A macro expands into an ordinary step definition when your code compiles, so it adds nothing at run time.
- **Regex literals need iOS 16, macOS 13 or tvOS 16**, as Swift's `Regex` does, with or without the macros. Below those versions, mark the code that uses them with `@available(iOS 16, macOS 13, tvOS 16, *)`, or use a string pattern. See <doc:Checking-Step-Definitions#Regex-literals>.
- **Swift Package Manager only.** Carthage builds CucumberSwift from its Xcode project, which cannot deliver macros, so a Carthage install keeps the step definition functions.

## Add the macros to your package

The macros are a separate product, `CucumberSwiftMacros`, behind a package trait named `Macros` (see <doc:Checking-Step-Definitions#Requirements>). They need the swift-syntax package, which SwiftPM downloads only when the trait is on. With Swift 6.2, a package that does not turn the trait on doesn't download swift-syntax. Swift 6.1 may still record a pin for it in `Package.resolved`, because the dependency is declared, but it doesn't build it.

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

<!-- swift-example: fragment: a Tuist Project.swift, which needs Tuist; Fixtures/SwiftTestingAndXCTestMacrosTuist builds one -->
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

The first time you build a macro, Xcode asks you to trust and enable it. A clean build also compiles swift-syntax. Xcode 26 and Swift 6.2 or later can use a prebuilt swift-syntax instead, but only when swift.org publishes one for both your toolchain and the swift-syntax version your package resolves, and not in every build even then. Swift 6.1 always compiles it.

## Convert existing step definitions

A project that already has step definitions written as ``Given`` and the like can have them rewritten as macros. The **Convert to Gherkin Macros** command changes only the step definitions it can convert exactly, and marks and lists each one it leaves, with the reason:

<!-- swift-example: steps -->
```swift
// Before
Given("I have {int} cukes in my {string}") { match, _ in
    let count = try match.first(\.int)
    let container = try match.first(\.string)
    basket.add(count, to: container)
}

// After
#Given("I have {int} cukes in my {string}") { (count: Int, container: String) in
    basket.add(count, to: container)
}
```

In Xcode, right-click the project or package in the Project navigator, and choose **Convert to Gherkin Macros** under CucumberSwift. Choose the targets whose Swift files to convert, and click **Run**.

In Terminal, run `swift package convert-to-gherkin-macros` in the package's folder. Without `--target`, it converts the Swift files in the folders of every target of the package. Add `--target MyAppTests` to convert one target's, and `--dry-run` to report what it would do without changing a file. The command needs permission to change files in your project or package: Xcode asks before it runs, and `swift package` asks in Terminal, or you can pass `--allow-writing-to-package-directory`. It checks that your project is set up for the macros first, as described under <doc:Checking-Step-Definitions#Before-it-changes-anything>.

It converts the step definitions of every macro keyword, including localized ones such as ``ES_Dado``, written with a trailing closure or with `callback:`, and with a pattern written as a string literal, with or without `as CucumberExpression`, which the macro adds itself, or as a regex literal, as described under <doc:Checking-Step-Definitions#Converting-regex-literals>. A step definition is converted when its closure reads each parameter from `match` in its first statements, in the pattern's order, as `let count = try match.first(\.int)` or `let count: Int = match[\.int, index: 0]`, and uses `match` for nothing else. Those statements become the closure's arguments, and the macro expands to the same step definition as before. A type you wrote on a read stays; otherwise the argument gets the type the pattern gives. Comments, formatting, a capture list, `async`, `throws` and other attributes stay as they are, and the command adds `import CucumberSwiftMacros` (or `CucumberSwiftTestingMacros`) when the file doesn't import it.

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

## Write a step definition

Each macro takes the pattern, a string literal or a regex literal (see <doc:Checking-Step-Definitions#Regex-literals>), and a closure. The closure takes one argument for each parameter of a Cucumber expression, or each capture group of a regular expression, in the order they appear. Give each argument its type:

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

A closure can be `async` and `throws`, and can have a capture list, exactly as with ``Given``. See <doc:Matching-Steps#Async-steps>.

<!-- swift-example: steps -->
```swift
#Then("^the basket holds (\\d+) cukes?$") { [basket] (count: String) async throws in
    try await basket.waitForCount(Int(count))
}
```

### Regex literals

The macros take a regex literal too, `#/…/#`, or `/…/` where your target allows bare regex literals, as the Swift 6 language mode does. The step matches when the regex matches its whole text, exactly as with ``Given``'s regex literal form.

<!-- swift-example: steps -->
```swift
#Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { (count: Substring, container: Substring) in
    basket.add(Int(count) ?? 0, to: String(container))
}
```

The closure takes one argument per capture group, in order, and optionally the `Step` last. Each argument's type is the capture's type in the regex's `Output`, as Swift gives it:

| In the regex | The argument's type |
|---|---|
| A capture group, numbered or named | `Substring` |
| A capture group that may not take part in the match: in an alternation, such as `(a)\|(b)`, or repeated zero or more times, such as `(\d+)?` or `(,\d+)*` | `Substring?` |

Every group counts, including one inside another: `#/^((\d+) red) cukes$/#` gives two arguments. A string pattern read as a regular expression, such as `"^((\\d+) red) cukes$"`, gives only its outer group. A named group's name doesn't need to match the argument's.

Swift, not the macro, works out a regex literal's `Output`, and it checks the closure's arguments against it in the macro's expansion: a missing argument, an extra one, or a wrong type, `Substring?` for `Substring` included, is a compile error. Where the macro can read the captures itself, it reports the error first, on your closure, with a fix: the closure takes the wrong number of arguments, or an argument isn't a `Substring`. For a regex with syntax that it doesn't read, such as `(?'name'…)` or the `n` and `x` options, the macro leaves the check to Swift, whose error is inside the expansion.

A capture is always text, which the closure converts itself. For typed arguments, such as an `Int` from `{int}` or a type of your own from a custom parameter type, use a Cucumber expression: it is the recommended pattern, and <doc:Matching-Steps#Choose-a-pattern> compares the three kinds.

Regex literals need iOS 16, macOS 13 or tvOS 16 at run time. A macro with a regex literal in code that can run on earlier versions is a compile error that says so, and Xcode offers to add `@available` to that code.

### Custom parameter types

A custom parameter type, such as `{color}`, needs no extra declaration. The macro reads it as `\.color` on `Match`, through the extension you already write for it, and the compiler checks the argument's type against the parameter's output. The parameter's name must be a valid Swift identifier. `{bigdecimal}`, `{biginteger}`, `{byte}`, `{short}` and `{long}` aren't built in, so the macros read them as custom parameter types too, and each needs an accessor of its name on `Match`.

### Keywords

`#Given`, `#When`, `#Then`, `#And` and `#But` fit steps with those keywords, and `#MatchAll` fits every step, exactly as ``Given``, ``When``, ``Then``, ``And``, ``But`` and ``MatchAll`` do. A step written with `*`, or with a keyword in another language, matches as it does without macros. See <doc:Matching-Steps#When-more-than-one-step-definition-matches-a-step>.

Every localized step definition has a macro too, with the same name: `#ES_Dado` for ``ES_Dado``, `#FR_Quand` for `FR_Quand`, and so on. They are only in `CucumberSwiftMacros`: the Swift Testing runner's `CucumberSwiftTestingMacros` doesn't have them.

<!-- swift-example: steps -->
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
| The pattern is not a string literal or a regex literal | `#Given("I have \(count) cukes")` | None: write the pattern out |
| A function is passed instead of a closure | `#Given("I have {int} cukes", addCukes)` | None: write a closure, which can call the function |
| A custom parameter's name is not a Swift identifier, because the macro reads it as `\.name` on `Match` | `#Given("I have {my-color} cukes")` | None: rename the parameter type |
| A regex literal's closure takes too few or too many arguments | `#Given(#/^I have (\d+) (\w+)$/#) { (count: Substring) in … }` | Changes the closure's arguments to `(count: Substring, group: Substring)` |
| An argument for a regex literal's capture isn't a `Substring` | `#Given(#/^I have (\d+) cukes$/#) { (count: Int) in … }` | Changes `Int` to `Substring` |
| An argument for a regex literal's capture is `Substring` where the capture gives `Substring?`, or the other way round | `#Given(#/^I have (\d+)?$/#) { (count: Substring) in … }` | None: Swift's own error, inside the expansion |

Each macro reports one kind of mistake at a time. When the pattern's parameters and the closure's arguments differ in number, you see only that error; once the number is right, the type errors show, one for each wrong argument. Fix the first, build again, and the next may appear.

A pattern that compiles but matches no step in your feature files is not a compile error: macros cannot read files. <doc:Checking-Feature-Files> reports those steps while you build.

## See what a macro does

In Xcode, right-click a macro and choose **Expand Macro**. The expansion is the step definition the macro stands for, and you can set breakpoints in it:

<!-- swift-example: steps -->
```swift
Given("I have {int} cukes in my {string}" as CucumberExpression) { match, _ in
    let count: Int = try match.first(\.int)
    let container: String = try match.first(\.string)
    basket.add(count, to: container)
}
```

It reads the parameters the same way as the step definitions CucumberSwift generates for undefined steps (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>). A parameter type that the pattern uses more than once is read by position, such as `match[\.int, index: 1]`.

A closure with a capture list, such as `[weak self]`, or one that contains a closure with a capture list, expands differently: the closure is first given its type as a constant, then passed to the step definition. Swift doesn't compile the plain form when a macro writes it, although it compiles written by hand.

<!-- swift-example: steps -->
```swift
{ () -> Then in
    let callback: @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void = { [basket] (match, _) async throws in
        let count: String = try match.first(\.anonymous)
        try await basket.waitForCount(Int(count))
    }
    return Then("^the basket holds (\\d+) cukes?$" as CucumberExpression, callback: callback)
}()
```

A regex literal's step definition reads every argument from the match's output at once, so that Swift checks them against the regex:

<!-- swift-example: steps -->
```swift
Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { match, _ in
    let (_, count, container): (_, Substring, Substring) = match.output
    basket.add(Int(count) ?? 0, to: String(container))
}
```

With a capture list, a regex literal's closure is given its type by a small generic function in the expansion instead, because the type names the regex's `Output`, which only Swift knows.
