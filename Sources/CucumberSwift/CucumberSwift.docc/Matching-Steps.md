# Matching steps

Match the steps of your feature files with step definitions, and choose how each one reads its arguments.

## Overview

A step definition matches steps by a pattern. You write it with a function named after its Gherkin keyword, such as ``Given``, ``When`` and ``Then``. The functions are also localized, such as ``ES_Dado`` for Spanish.

To have the compiler check each step definition's pattern and closure, write it as a macro such as `#Given` instead. See <doc:Using-Step-Definition-Macros>.

## Choose a pattern

A step definition's pattern can be a Cucumber expression, a regular expression written as a string, or a regex literal. Use a Cucumber expression unless you need something that only a regular expression can do. Cucumber expressions are the same in every Cucumber implementation. They read like the steps they match, and they give each argument its type.

| | Cucumber expression | Regular expression in a string | Regex literal |
|---|---|---|---|
| Example | `"I have {int} cukes"` | `"^I have (\\d+) cukes$"` | `#/^I have (\d+) cukes$/#` |
| Arguments | Typed: `Int` for `{int}`, `Double` for `{double}`, `String` for `{string}`, and any type of your own with a custom parameter type | `String`, one per top-level capture group | `Substring`, or `Substring?` for a group that may not match, one per capture group, nested ones included |
| Converting the text | CucumberSwift converts it. A value that can't be converted fails the step. | The closure converts it. | The closure converts it. |
| Checked when it compiles, with the step definition macros | The syntax, the number of arguments and each one's type | The syntax, the number of arguments, and that each is a `String` | The syntax, the number of arguments and each one's type, against the regex's output |
| Two step definitions with the same pattern | Reported | Reported | Not detected |
| Runs on | iOS 13, macOS 10.15, tvOS 13 and later | iOS 13, macOS 10.15, tvOS 13 and later | iOS 16, macOS 13, tvOS 16 and later |

Use a regular expression when the step needs something that a Cucumber expression can't say, such as alternatives of more than one word, lookarounds or a case-insensitive match. Prefer a regex literal to a regular expression in a string. Swift checks a regex literal's syntax when it compiles, with or without the macros. A regular expression in a string is checked only with the macros, and otherwise only when the tests run.

If you need a typed value from text that no built-in parameter matches, such as a date or an airport code, write a custom parameter type instead. You keep the Cucumber expression, and every step definition can reuse the parameter type (see <doc:Matching-Steps#Matching-with-Cucumber-expressions>).

CucumberSwift also suggests Cucumber expressions for undefined steps. See <doc:Matching-Steps#Step-definitions-for-undefined-steps>.

## How a string pattern is read

When you pass a string to ``Given``, ``When`` or ``Then``, CucumberSwift decides from its shape whether it's a regular expression or a Cucumber expression, as other Cucumber implementations do:

| The string | Is read as | Example |
|---|---|---|
| starts with `^` or ends with `$` | a regular expression | `Given("^I pay 5$")` |
| starts and ends with `/` | a regular expression | `Given("/I pay 5/")` |
| anything else | a Cucumber expression | `Given("I pay {int}")` |

In a string between slashes, the slashes aren't part of the regular expression.

A step definition whose closure takes `[String]`, such as `{ matches, _ in … matches[1] … }`, uses the older regular expression API. Its string is always a regular expression, and Xcode shows a deprecation warning.

### Upgrading to 6.0.0

Before 6.0.0, CucumberSwift read a string that started with `^` or ended with `$` as a Cucumber expression, with `^` and `$` as literal characters. So a step definition with an anchored pattern matched nothing, and its step was reported as unimplemented. From 6.0.0, the string is a regular expression and matches as written.

Most step definitions need no change. Step definitions whose closure takes `[String]` aren't affected, because they already read the string as a regular expression. For the rest, check any pattern that starts with `^` or ends with `$` but was meant literally, such as a price written as `"I owe 5$"`.

#### Anchored patterns

Each of these step definitions matches the step `the app is at the Main Menu`. The second one, a regular expression in a string, matches from 6.0.0 on. Older versions read it as a Cucumber expression, so it never matched. Use only one of them, because more than one for the same step makes the step ambiguous (see <doc:Matching-Steps#When-more-than-one-step-definition-matches-a-step>):

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
// a Cucumber expression
#Given("the app is at the Main Menu") { }

// a regular expression in a string
#Given("^the app is at the Main Menu$") { }

// a regex literal, which needs iOS 16, macOS 13 or tvOS 16 at run time
#Given(#/^the app is at the Main Menu$/#) { }
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
// a Cucumber expression
Given("the app is at the Main Menu") { _, _ in }

// a regular expression in a string
Given("^the app is at the Main Menu$") { _, _ in }

// a regex literal, which needs iOS 16, macOS 13 or tvOS 16 at run time
Given(#/^the app is at the Main Menu$/#) { _, _ in }
```
}
}

A regex literal without the `#` delimiters, `/^…$/`, is another alternative. It needs iOS 16, macOS 13 or tvOS 16 at run time, and a target that allows bare regex literals. The Swift 6 language mode allows them, and so does the `BareSlashRegexLiterals` feature (see <doc:Matching-Steps#Matching-with-regular-expressions>):

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps bare-slash-regex -->
```swift
#Given(/^the app is at the Main Menu$/) { }
```
}
@Tab("Carthage") {
<!-- swift-example: steps bare-slash-regex -->
```swift
Given(/^the app is at the Main Menu$/) { _, _ in }
```
}
}

#### A literal dollar sign or caret

A pattern that ends with `$` or starts with `^` changes meaning if you meant the character itself:

- If the pattern is a valid regular expression, it silently stops matching. `"I owe 5$"` no longer matches the step `I owe 5$`, because `$` now means "end of text":

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
// Before 6.0.0, this matched the step "I owe 5$".
// From 6.0.0, it matches nothing.
#Given("I owe 5$") { }
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
// Before 6.0.0, this matched the step "I owe 5$".
// From 6.0.0, it matches nothing.
Given("I owe 5$") { _, _ in }
```
}
}

- If the pattern isn't a valid regular expression, such as `"I owe {int}$"`, the test run stops with an error that names the pattern.

To match a literal `$` or `^`, write the whole pattern as a regular expression and escape the character. Both step definitions below match the step `I owe 5$`. Use only one, because several for the same step make it ambiguous. The regular expression in a string runs on every deployment target. The regex literal needs iOS 16, macOS 13 or tvOS 16:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
// a regular expression in a string
#Given("^I owe 5\\$$") { }

// a regex literal, which needs iOS 16, macOS 13 or tvOS 16 at run time
#Given(#/^I owe 5\$$/#) { }
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
// a regular expression in a string
Given("^I owe 5\\$$") { _, _ in }

// a regex literal, which needs iOS 16, macOS 13 or tvOS 16 at run time
Given(#/^I owe 5\$$/#) { _, _ in }
```
}
}

The bare form of the regex literal, `/^I owe 5\$$/`, also needs iOS 16, macOS 13 or tvOS 16, and a target that allows bare regex literals, as above:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps bare-slash-regex -->
```swift
#Given(/^I owe 5\$$/) { }
```
}
@Tab("Carthage") {
<!-- swift-example: steps bare-slash-regex -->
```swift
Given(/^I owe 5\$$/) { _, _ in }
```
}
}

To read the amount instead of matching one price, capture it. Again, choose one of the alternatives. A regular expression gives the closure text that the closure converts itself. The text is a `String` for a regular expression in a string, and a `Substring` for a regex literal:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
// a regular expression in a string
#Given("^I owe (\\d+)\\$$") { (amount: String) in }

// a regex literal
#Given(#/^I owe (\d+)\$$/#) { (amount: Substring) in }
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Given("^I owe (\\d+)\\$$") { match, _ in

    // a regular expression in a string: text
    let amount = match[\.anonymous, index: 0]
}
Given(#/^I owe (\d+)\$$/#) { match, _ in

    // a regex literal: its output, typed
    let (_, amount): (_, Substring) = match.output
}
```
}
}

## Async steps

A step definition can be `async` and `throws`. Write `await` in its closure and CucumberSwift runs it as an async step:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#Given("the user has signed in") {
    try await session.signIn(as: .testUser)
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Given("the user has signed in") { _, _ in
    try await session.signIn(as: .testUser)
}
```
}
}

A closure without `await` is an ordinary synchronous step definition. Async steps work with Cucumber expressions, string patterns and regex literals.

Steps still run one at a time, in the order of the feature file. The next step starts only when an async step has finished, so nothing in a scenario runs in parallel. A step definition's closure runs on the main actor. It can await work on other threads or actors, and it resumes on the main actor afterwards.

**Failures and errors.** An assertion that fails inside an async step fails the step, and so does a thrown error. As for any failed step, the rest of the scenario is skipped. By default, a failed assertion doesn't stop its step, and CucumberSwift doesn't cancel the step's task. If you turn off `continueTestingAfterFailure` by returning `false` from your `StepImplementation` (see <doc:Settings#Continue-after-a-failed-assertion>), CucumberSwift cancels the step's task when it fails. It then waits for the task to finish before it goes on.

**Timeout.** An async step fails, and is cancelled, if it hasn't finished within 60 seconds. The timeout applies only to async steps and async hooks. Synchronous steps and hooks have none. To change it, set `asyncStepTimeout`, in seconds, in your `StepImplementation`:

```swift
extension Cucumber: StepImplementation {
    public var asyncStepTimeout: TimeInterval { 120 }
    // ...
}
```

Cancellation is cooperative. CucumberSwift waits for a cancelled step to finish before it starts the next one. So a step that ignores cancellation holds up the run, but never overlaps the next step.

**UI tests.** In a UI test target, an async step or hook can query, tap and wait for elements with XCUI, as a synchronous one can. Its closure runs on the main actor, as `XCUIApplication` needs:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: fragment: taps with XCUIElement.tap(), which a macOS build doesn't have -->
```swift
#When("I add an item") {
    try await cart.prepare()
    app.buttons["add"].tap()
    XCTAssert(app.staticTexts["Items: 1"].waitForExistence(timeout: 10))
}
```
}
@Tab("Carthage") {
<!-- swift-example: fragment: taps with XCUIElement.tap(), which a macOS build doesn't have -->
```swift
When("I add an item") { _, _ in
    try await cart.prepare()
    app.buttons["add"].tap()
    XCTAssert(app.staticTexts["Items: 1"].waitForExistence(timeout: 10))
}
```
}
}

XCUI's own waits, such as `waitForExistence(timeout:)`, count toward the step's `asyncStepTimeout`, together with everything else the step does. So set the timeout longer than the whole step: all of its XCUI waits added up, plus its other work. If the timeout passes while an XCUI call is still waiting, XCTest interrupts that call ("Interrupted by waiter"), and the step fails with the timeout.

**Passing a function instead of a closure.** An async function keeps its own isolation. Mark it `@MainActor` if it needs the main actor, for example to change UI state. A plain `async` function doesn't run on the main actor. Either way, the next step waits for it.

**Running another step.** To share code between two step definitions, put it in a function and call the function from each one, as in <doc:Running-Feature-Files-With-Swift-Testing#Run-another-step>. Any step can call a synchronous helper. An `async` helper needs `await`, so only an async step or hook can call it.

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
func addCukes(_ count: Int) {
    basket.add(count, to: "basket")
}
#Given("I have {int} cukes in my basket") { (count: Int) in
    addCukes(count)
}
#When("I add {int} more cukes") { (count: Int) in
    addCukes(count)
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
func addCukes(_ count: Int) {
    basket.add(count, to: "basket")
}
Given("I have {int} cukes in my basket") { match, _ in
    addCukes(try match.first(\.int))
}
When("I add {int} more cukes") { match, _ in
    addCukes(try match.first(\.int))
}
```
}
}

> Deprecation Warning: `ExecuteFirstStep(matching:)` is deprecated and will be removed in a future major version.
>
> Cucumber's own guidance recommends against one step definition running another. Share the code through a helper function instead. See [Cucumber anti-patterns](https://cucumber.io/docs/guides/anti-patterns/) and [step organization](https://cucumber.io/docs/gherkin/step-organization/).

For an async step in the Swift DSL, pass an async function or closure, not a call. Prefer feature files where you can, and use the DSL where a feature is better written in code. With the Macros trait, write the feature with the DSL macros, such as `#Feature`, `#Scenario` and `#Given(I: signIn)`. They capture each step's text when the tests compile. Without the trait, as with Carthage, the step functions read the text from the Swift file when the tests run. Keep to one style in a test target:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
@MainActor func signIn() async throws { /* ... */ }

#Feature("Sign in") {
    #Scenario("A returning user") {
        #Given(I: signIn)                                 // an async function
        #When(I: { try await open(.settings) })           // a closure
        #Then(the: settingsAreShown())                    // a synchronous call, as before
    }
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
@MainActor func signIn() async throws { /* ... */ }

Feature("Sign in") {
    Scenario("A returning user") {
        Given(I: signIn)                                  // an async function
        When(I: { try await open(.settings) })            // a closure
        Then(the: settingsAreShown())                     // a synchronous call, as before
    }
}
```
}
}

### Swift 6 language mode

In a test target that builds in the Swift 6 language mode, mark the conformance `@retroactive`, because both `Cucumber` and `StepImplementation` come from CucumberSwift:

<!-- swift-example: file swift6 -->
```swift
extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }
    public func setupSteps() { /* ... */ }
}
```

The same goes for `extension Cucumber: @retroactive CucumberTestObservable` when you add a reporter (see <doc:Generating-Reports>).

`StepImplementation` and `CucumberTestObserver` are main-actor protocols. So `setupSteps()`, the steps, hooks and DSL steps declared in it, and a custom reporter's methods can all use main-actor code, such as `XCUIApplication`. An async step can also change a variable that it shares with other steps, such as a `var` declared in `setupSteps()`. CucumberSwift calls all of them on the main thread.

In the Swift 5 language mode, nothing changes. The protocols are marked `@preconcurrency`, so code written for earlier versions of CucumberSwift compiles as before.

## Matching with Cucumber expressions

[Cucumber expressions](https://github.com/cucumber/cucumber-expressions#readme) are the patterns that Cucumber recommends, and the ones to try first (see <doc:Matching-Steps#Choose-a-pattern>). A parameter such as `{int}` matches text and converts it to its type. A custom parameter type does the same for a type of your own, with its own regular expression. CucumberSwift reads a string pattern as a Cucumber expression unless it starts with `^`, ends with `$` or is written between slashes, as described above.

For example, take this step:

```gherkin
Given there are 3 flights from lax.
```

The step definition below matches it. The macro's closure takes each parameter as an argument, already converted to its type. With the function, you read each parameter from `match`:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#Given("there is/are/were {int} flight(s) from {airport}.") { (count: Int, airport: Airport) in
    XCTAssertEqual(count, 3)
    XCTAssertIdentical(airport, Airport.lax)
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Given("there is/are/were {int} flight(s) from {airport}." as CucumberExpression) { match, _ in 
    XCTAssertEqual(match[\.int, index: 0], 3)
    XCTAssertEqual(try match.first(\.int), 3)
    XCTAssertEqual(try match.last(\.int), 3)
    XCTAssertEqual(try match.allParameters(\.int), [3])
    XCTAssertIdentical(match[\.airport, index: 0], Airport.lax)
    XCTAssertIdentical(try match.first(\.airport), Airport.lax)
    XCTAssertIdentical(try match.last(\.airport), Airport.lax)
    XCTAssertEqual(try match.allParameters(\.airport).count, 1)
    XCTAssertIdentical(try match.allParameters(\.airport).first, Airport.lax)
}
```
}
}

`{airport}` is a custom parameter type. To create one, write a type that conforms to `Parameter`, and list it in an extension of `CucumberExpression`:

```swift
// Your model type.
class Airport {
    static let lax = Airport()
}

// Lists every custom parameter type that you use.
extension CucumberExpression: CustomParameters {
    public static var additionalParameters: [CucumberSwiftExpressions.AnyParameter] {
        [
            AirportParameter().eraseToAnyParameter()
        ]
    }
}

// The airport parameter
struct AirportParameter: Parameter {
    enum ParameterError: Error {
        case airportNotFound
    }

    // A unique name for this parameter
    static let name = "airport"

    // The regular expression that matches this parameter.
    let regexMatch = #"[A-Z]{3}"#

    // Converts the matched text to your type.
    func convert(input: String) throws -> Airport {
        switch input.lowercased() {
            case "lax": return Airport.lax
            default:
                throw ParameterError.airportNotFound
        }
    }
}

// Lets you read the parameter as `\.airport`, as in the example above.
extension Match {
    var airport: AirportParameter {
        AirportParameter()
    }
}
```

## Matching with regular expressions

Regular expressions can match what a Cucumber expression can't, but they're harder to read and their arguments aren't typed (see <doc:Matching-Steps#Choose-a-pattern>). If your tests run on iOS 16, macOS 13 or tvOS 16 or later, prefer a regex literal to a regular expression in a string, because the compiler checks it.

This step definition matches regardless of case, with `ignoresCase()`. A step definition macro takes the regex literal itself, so it can't take `ignoresCase()`. Use the function style here, and the macros for step definitions that don't need it:

<!-- swift-example: steps bare-slash-regex -->
```swift
When(/^some (\w+) by the actor$/.ignoresCase()) { match, _ in
    XCTAssertEqual(match.1, "action")
}
```

> Note: You can also use Swift's regex builders to convert matches to concrete types. They're more verbose, and CucumberSwift supports them.

This is the same step definition with an extended delimiter. It compiles in any test target:

<!-- swift-example: steps -->
```swift
When(#/^some (\w+) by the actor$/#.ignoresCase()) { match, _ in
    XCTAssertEqual(match.1, "action")
}
```

> Important: Regex literals need iOS 16, macOS 13 or tvOS 16. The `/…/` form also needs the Swift 6 language mode or the `BareSlashRegexLiterals` feature. Xcode turns that feature on by default ("Enable Bare Slash Regex Literals"). A Swift package's target in the Swift 5 language mode needs it set, as <doc:Running-Tests-With-Swift-Package-Manager> describes. `#/…/#` works without either. On earlier deployment targets, use a string pattern that starts with `^` instead, as described in <doc:Matching-Steps#How-a-string-pattern-is-read>.

## Step definitions for undefined steps

For each step that no step definition matches, CucumberSwift reports a failure with the Swift code for a step definition that you can paste in. It also attaches all of them to the test `GenerateStepsStubsIfNecessary`. The code uses a Cucumber expression, and Cucumber expressions work on every deployment target. It's a step definition macro when your tests link the step definition macros, and a function otherwise, such as with Carthage (see <doc:Matching-Steps#Step-definition-macros>). Whole numbers become `{int}`, decimals `{float}`, and text in double quotes `{string}`. Text in single quotes stays as written:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#Then("the display shows {string}") { (string: String) in
    XCTFail("Step not implemented: replace this line with your test code")
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Then("the display shows {string}") { match, _ in
    let string = try match.first(\.string)
    XCTFail("Step not implemented: replace this line with your test code")
}
```
}
}

A parameter type that a step uses more than once is read by position, such as `match[\.int, index: 1]`. The generated code escapes the characters that mean something in a Cucumber expression, such as `\`, `(`, `{` and `/`, and a `^` at the start of the step. A step that ends in `$` gets a regular expression instead, such as `Then("^I owe (\\d+)\\$$")`, because a pattern that ends in `$` is always read as one (see <doc:Matching-Steps#How-a-string-pattern-is-read>). Its parameters are text, read with `match[\.anonymous, index: 0]`.

### Generate regex literals instead

To generate regex literals, as earlier versions did, set `Cucumber.generateRegexLiterals = true` in your `StepImplementation`'s `setupSteps()`. Or set the environment variable `CUCUMBER_GENERATE_REGEX_LITERALS` to `YES` in a scheme or test plan. If both are set, the static variable wins (see <doc:Settings>). The Swift Testing runner reads the same two settings.

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#Then(#/^the display shows \"(.*?)\"$/#) { (string: Substring) in
    XCTFail("Step not implemented: replace this line with your test code")
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Then(#/^the display shows \"(.*?)\"$/#) { matches, _ in
    let string = matches.1
    XCTFail("Step not implemented: replace this line with your test code")
}
```
}
}

The generated regex literals are written as `#/…/#`, a form that compiles in any test target. To get `/…/` instead, return ``RegexLiteralStyle/bareSlash`` from your `StepImplementation`'s `regexLiteralStyle`. It has no effect unless `generateRegexLiterals` is on. Whether your target accepts `/…/` is a setting of your target that CucumberSwift can't read. So check it in your own code, as <doc:Running-Tests-With-Swift-Package-Manager#Paste-generated-step-definitions> shows. Regex literals need iOS 16, macOS 13 or tvOS 16.

### Step definition macros

If your tests use the recommended step definition macros (see <doc:Using-Step-Definition-Macros>), CucumberSwift suggests macros, as Convert to Gherkin Macros writes them and as the Swift Package Manager tabs above show.

CucumberSwift suggests macros when the test target links the macros built with the `Macros` trait: `CucumberSwiftMacros`, or `CucumberSwiftTestingMacros` with the Swift Testing runner. Otherwise, such as with Carthage, it suggests functions. To choose yourself, set `Cucumber.generateMacros` in `setupSteps()` to `true` for macros or `false` for functions. Or set the environment variable `CUCUMBER_GENERATE_MACROS` to `YES` or `NO`. If both are set, the static variable wins. The Swift Testing runner reads the same two settings.

The suggested closure takes one typed argument for each parameter: `Int` for `{int}`, `Float` for `{float}` and `String` for `{string}`. A step with a data table or a doc string adds `step: Step` as the last argument, to read it. A step that starts with `^` gets a regular expression, such as `#Then("^\\^a caret$")`. That's because the macro checks the Cucumber expression when it compiles, and a Cucumber expression can't escape a `^`. With `generateRegexLiterals` on as well, the macros take regex literals in the style that `regexLiteralStyle` sets, with a `Substring` for each capture group, such as `#Then(#/^the display shows \"(.*?)\"$/#) { (string: Substring) in`.

## When more than one step definition matches a step

Each step should match exactly one step definition. If more than one step definition matches a step, the step is *ambiguous*, as in other Cucumber implementations. CucumberSwift then runs none of them, fails the step, and reports it as `ambiguous`. The failure is at the step in the `.feature` file, and it names the file and line of each matching step definition.

A step definition matches a step only if its keyword fits the step. ``Given`` fits a `Given` step, and any `And` or `But` step that follows one. ``MatchAll`` fits every step. For example:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#Given("some precondition") { }
#When("some precondition") { }      // not ambiguous for "Given some precondition": When never fits a Given step
#MatchAll("^some (.*)$") { (text: String) in }   // ambiguous with the Given above: both fit "Given some precondition"
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
Given("some precondition") { _, _ in }
When("some precondition") { _, _ in }      // not ambiguous for "Given some precondition": When never fits a Given step
MatchAll("^some (.*)$") { _, _ in }        // ambiguous with the Given above: both fit "Given some precondition"
```
}
}

Two step definitions with the *same* pattern are a mistake even when no step uses them, as in Cucumber for Java. If their keywords can match the same steps, the test run fails at the second one, and the failure names both. Two keywords can match the same steps when they're the same keyword, when one is ``MatchAll``, or when one is ``And`` or ``But`` and the other is ``Given``, ``When`` or ``Then``. So `Given("x")` and `When("x")` aren't duplicates. Two patterns count as the same when they're the same regular expression, or the same Cucumber expression. Regex literals, such as `Given(/x/)`, can't be compared, so only the ambiguity check applies to them.

To fix an ambiguous step or a duplicate, remove all but one of the step definitions, or make their patterns more specific so that each step matches only one. Earlier versions reported neither, and the step definition registered last silently replaced the others.
