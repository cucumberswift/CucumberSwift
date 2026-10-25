# Checking step definitions when they compile

@Metadata {
    @Available(Xcode, introduced: "16.3")
    @Available(Swift, introduced: "6.1")
}

Write step definitions as macros, and the compiler checks each pattern and closure where you write it. Xcode offers a fix for the common mistakes.

## Overview

Write your step definitions with the step definition macros, `#Given`, `#When`, `#Then`, `#And`, `#But` and `#MatchAll`. The compiler then checks each one while your code compiles:

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

The closure takes 1 argument for each parameter in the expression, already converted to its type. A mistake is a compile error on the line that has it. When the fix is clear, Xcode offers to make it for you.

The ``Given``, ``When`` and ``Then`` functions are checked only when the tests run. With them, a Cucumber expression that is missing a `}`, a regular expression that doesn't compile, or a closure that reads the wrong parameter fails after a full build and test launch.

Each macro expands to the step definition you would otherwise write by hand, so steps match and run in the same way. Your feature files, hook functions and existing step definitions keep working, and you can mix both styles in 1 target.

This article describes what the compiler checks. <doc:Using-Step-Definition-Macros> shows how to set up the macros, write step definitions with them, and convert the ones you have.

## Mistakes the compiler finds

The compiler reports each mistake as an error on its own line. Click the error's icon to see the whole message. If the error has a fix, click **Apply** to make the change.

![A Swift file in Xcode with 4 step definition macros marked as errors. In the first, the pattern has 2 parameters but the closure takes 1 argument. In the second, {int} gives Int but 'count' is declared as String. In the third, the '{' does not have a matching '}'. In the fourth, a pattern ending in "$" is read as a regular expression that is not valid.](CheckingStepDefinitions-FixIt.png)

| Mistake | Example | Fix |
|---|---|---|
| The closure takes too few or too many arguments | `#Given("I have {int} cukes in my {string}") { (count: Int) in … }` | Changes the closure's arguments to `(count: Int, string: String)` |
| An argument has the wrong type | `#Given("I have {int} cukes") { (count: String) in … }` | Changes `String` to `Int` |
| A parameter is missing its `}` | `#Given("I have {int cukes")` | Inserts `}` after `{int` |
| A Cucumber expression breaks another syntax rule, such as empty optional text or a parameter inside optional text | `#Given("I have () cukes")` | None. The error says what is wrong and how to fix it. |
| A pattern that is read as a regular expression does not compile | `#Given("I have {int} cukes$")`, where the `$` makes it a regular expression | Removes the `^`, `$` or slashes, when what is left is a valid Cucumber expression |
| The pattern is not a string literal or a regex literal | `#Given("I have \(count) cukes")` | None. Write the pattern out. |
| A function is passed instead of a closure | `#Given("I have {int} cukes", addCukes)` | None. Write a closure that calls the function. |
| A custom parameter's name is not a Swift identifier, because the macro reads it as `\.name` on `Match` | `#Given("I have {my-color} cukes")` | None. Rename the parameter type. |
| A regex literal's closure takes too few or too many arguments | `#Given(#/^I have (\d+) (\w+)$/#) { (count: Substring) in … }` | Changes the closure's arguments to `(count: Substring, group: Substring)` |
| An argument for a regex literal's capture isn't a `Substring` | `#Given(#/^I have (\d+) cukes$/#) { (count: Int) in … }` | Changes `Int` to `Substring` |
| An argument for a regex literal's capture is `Substring` where the capture gives `Substring?`, or the other way round | `#Given(#/^I have (\d+)?$/#) { (count: Substring) in … }` | None. Swift reports its own error, inside the expansion. |

Each macro reports 1 kind of mistake at a time. If the pattern's parameters and the closure's arguments differ in number, you see only that error. Once the number is right, you see 1 type error for each wrong argument. Fix the first error and build again to see the next.

Macros can't read files, so a pattern that compiles but matches no step in your feature files is not a compile error. <doc:Checking-Feature-Files> reports those steps when you build.

## See what a macro does

In Xcode, right-click a macro and choose **Expand Macro**. The expansion is the step definition that the macro stands for. You can set breakpoints in it:

<!-- swift-example: steps -->
```swift
Given("I have {int} cukes in my {string}" as CucumberExpression) { match, _ in
    let count: Int = try match.first(\.int)
    let container: String = try match.first(\.string)
    basket.add(count, to: container)
}
```

The expansion reads the parameters in the same way as the step definitions that CucumberSwift generates for undefined steps (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>). If the pattern uses a parameter type more than once, the expansion reads it by position, such as `match[\.int, index: 1]`.

A closure with a capture list, such as `[weak self]`, expands differently. So does a closure that contains a closure with a capture list. The expansion first declares the closure as a constant with its type, then passes it to the step definition. Swift compiles the plain form when you write it by hand, but not when a macro writes it:

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

A regex literal's step definition reads all the arguments from the match's output at once, so that Swift checks them against the regex:

<!-- swift-example: steps -->
```swift
Given(#/^I have (\d+) cukes in my (?<container>\w+)$/#) { match, _ in
    let (_, count, container): (_, Substring, Substring) = match.output
    basket.add(Int(count) ?? 0, to: String(container))
}
```

With a capture list, the expansion gives a regex literal's closure its type through a small generic function instead. It does this because the type names the regex's `Output`, a type that only Swift knows.
