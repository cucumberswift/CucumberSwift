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

Each macro expands to the step definition you would otherwise write by hand, so nothing about how steps match or run changes. Feature files, the hook functions and the step definitions you already have keep working, and you can mix both styles in one target.

This article describes what the compiler checks. <doc:Using-Step-Definition-Macros> shows how to set the macros up, write step definitions with them and convert the ones you have.

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
