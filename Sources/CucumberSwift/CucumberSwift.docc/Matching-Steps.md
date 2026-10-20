# Matching Steps

Gherkin defined in `.feature` files can be matched in several ways. All matching is done using global functions that align with gherkin keywords. For example, ``Given``, ``When``, and ``Then`` functions. These functions are also localized, so if you'd rather use spanish you can use ``ES_Dado``. 

To have the compiler check each step definition's pattern and closure, write it as a macro such as `#Given` instead: see <doc:Using-Step-Definition-Macros>.

## Choose a pattern

A step definition's pattern can be a Cucumber expression, a regular expression written as a string, or a regex literal. **Use a Cucumber expression unless you need something only a regular expression can do.** It is the Cucumber way to write a step definition, the same in every Cucumber implementation. It reads like the step it matches, and it gives each argument its type.

| | Cucumber expression | Regular expression in a string | Regex literal |
|---|---|---|---|
| Example | `"I have {int} cukes"` | `"^I have (\\d+) cukes$"` | `#/^I have (\d+) cukes$/#` |
| Arguments | Typed: `Int` for `{int}`, `Double` for `{double}`, `String` for `{string}`, and any type of your own with a custom parameter type | `String`, one per top-level capture group | `Substring`, or `Substring?` for a group that may not match, one per capture group, nested ones included |
| Converting the text | Done for you; a value that can't be converted fails the step | Yours to do, in the closure | Yours to do, in the closure |
| Checked when it compiles, with the step definition macros | The syntax, the number of arguments and each one's type | The syntax, the number of arguments, and that each is a `String` | The syntax, the number of arguments and each one's type, against the regex's output |
| Two step definitions with the same pattern | Reported | Reported | Not detected |
| Runs on | iOS 13, macOS 10.15, tvOS 13 and later | iOS 13, macOS 10.15, tvOS 13 and later | iOS 16, macOS 13, tvOS 16 and later |

A regular expression is the right choice when the step needs what a Cucumber expression can't say, such as alternatives that are more than one word, lookarounds or a case-insensitive match. Of the two, a regex literal is the safer: Swift checks its syntax when it compiles, with or without the macros, while a regular expression in a string is checked only with the macros, and otherwise only when the tests run. If what you need is a typed value from text a built-in parameter doesn't match, such as a date or an airport code, write a custom parameter type instead: it keeps the Cucumber expression, and every step definition reuses it (see <doc:Matching-Steps#Matching-with-Cucumber-Expressions>).

CucumberSwift suggests Cucumber expressions for undefined steps, too: see <doc:Matching-Steps#Step-definitions-for-undefined-steps>.

## How a string pattern is read
When you pass a string to ``Given``, ``When`` or ``Then``, CucumberSwift decides from its shape whether it is a regular expression or a Cucumber expression, the same way other Cucumber implementations do:

| The string | Is read as | Example |
|---|---|---|
| starts with `^` or ends with `$` | a regular expression | `Given("^the app is at the Main Menu$")` |
| starts and ends with `/` | a regular expression, without the slashes | `Given("/the app is at the Main Menu/")` |
| anything else | a Cucumber expression | `Given("the app is at the {word} Menu")` |

A step definition whose closure takes `[String]`, such as `{ matches, _ in … matches[1] … }`, uses the older regular expression API instead: its string is always a regular expression, and Xcode shows a deprecation warning.

### Upgrading to 6.0.0
Before 6.0.0, a string that started with `^` or ended with `$` was read as a Cucumber expression, which treated `^` and `$` as literal characters. A step definition that anchored its pattern therefore matched nothing, and its step was reported as unimplemented. From 6.0.0 it is a regular expression and matches as written.

Most step definitions need no change. Step definitions whose closure takes `[String]` are not affected at all: they already read the string as a regular expression. For the rest, check any pattern that starts with `^` or ends with `$` but was meant *literally*, such as a price written as `"I owe 5$"`.

#### Anchored patterns
These step definitions all match the step `the app is at the Main Menu`. From 6.0.0 the second one, which the older versions read as a Cucumber expression and so never matched, is a regular expression and matches as written. They are alternatives: use one, because registering more than one for the same step makes the step ambiguous (see <doc:Matching-Steps#When-more-than-one-step-definition-matches-a-step>):

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

A regex literal without the `#` delimiters, `/^…$/`, is one more alternative for the same step. It needs iOS 16, macOS 13 or tvOS 16 at run time, and your target must allow bare regex literals: the Swift 6 language mode does, as does the `BareSlashRegexLiterals` feature (see <doc:Matching-Steps#Matching-with-Regular-Expressions>):

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
If a pattern ends with `$` or starts with `^` but you meant the character itself, the step definition changes meaning:

- If it is a valid regular expression, it silently stops matching. `"I owe 5$"` no longer matches the step `I owe 5$`, because `$` now means "end of text":

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

- If it is not a valid regular expression, such as `"I owe {int}$"`, the test run stops with an error that names the pattern.

To match a literal `$` or `^`, write the whole pattern as a regular expression and escape the character. These are alternatives for the step `I owe 5$`: use one, because several for the same step make it ambiguous. The regular expression in a string runs on every deployment target, and a regex literal needs iOS 16, macOS 13 or tvOS 16:

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

Both regex literals need iOS 16, macOS 13 or tvOS 16. The bare form, `/^I owe 5\$$/`, also needs a target that allows bare regex literals, as above:

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

To read the amount instead of matching one price, capture it, again as alternatives to choose from. A regular expression gives the closure text, which it converts itself: a `String` for a regular expression in a string, a `Substring` for a regex literal.

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

A closure without `await` is an ordinary synchronous step definition, exactly as before. This works with Cucumber expressions, string patterns and regex literals alike.

Steps still run one at a time, in the order the feature file declares them. The next step starts only once an async step has finished, so nothing in a scenario ever runs in parallel. A step definition's closure runs on the main actor. Awaiting work on other threads or actors is fine: the step resumes on the main actor afterwards.

**Failures and errors.** An assertion that fails inside an async step fails that step, and a thrown error fails it too. As for any failed step, the rest of the scenario is skipped. By default a failed assertion doesn't stop its step, and CucumberSwift doesn't cancel the step's task. With `continueTestingAfterFailure` turned off, which you do by returning `false` from your `StepImplementation` (see <doc:Settings#Continue-after-a-failed-assertion>), CucumberSwift cancels the step's task when it fails, then waits for it to finish before going on.

**Timeout.** An async step fails if it has not finished within 60 seconds, and is cancelled. The timeout applies only to async steps and async hooks: a synchronous step or hook has none. To change it, set `asyncStepTimeout` (in seconds) in your `StepImplementation`:

```swift
extension Cucumber: StepImplementation {
    public var asyncStepTimeout: TimeInterval { 120 }
    // ...
}
```

Cancellation is cooperative. CucumberSwift waits for a cancelled step to finish before starting the next one, so a step that ignores cancellation holds up the run rather than overlap the step after it.

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

XCUI's own waits, such as `waitForExistence(timeout:)`, count toward the step's `asyncStepTimeout`, together with everything else the step does, so set it longer than the whole step: all of its XCUI waits added up, plus its other work. When the timeout passes while an XCUI call is still waiting, XCTest interrupts that call ("Interrupted by waiter"), and the step fails with the timeout.

**Passing a function instead of a closure.** An async function keeps its own isolation. Mark it `@MainActor` if it needs the main actor, for example to touch UI state; a plain `async` function runs on a background thread. Either way, the next step waits for it.

**Running another step.** Put the code both step definitions need in a function, and call it from each, as in <doc:Running-Feature-Files-With-Swift-Testing#Run-another-step>. A synchronous helper works from any step. An `async` helper needs `await`, so only an async step or hook can call it, and a step that calls one has to be async itself.

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
> Cucumber's own guidance recommends against one step definition running another: share the code through a helper function instead. See [Cucumber anti-patterns](https://cucumber.io/docs/guides/anti-patterns/) and [step organization](https://cucumber.io/docs/gherkin/step-organization/).

With the Swift DSL, pass an async function or closure rather than a call. With the Macros trait, write each step with a DSL step macro, such as `#Given(I: signIn)`, which captures the step's text when the tests compile. Without it, as with Carthage, the step functions read the text from the Swift file when the tests run:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
@MainActor func signIn() async throws { /* ... */ }

Feature("Sign in") {
    Scenario("A returning user") {
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
In a test target that builds in Swift 6 language mode, mark the conformance `@retroactive`, because both `Cucumber` and `StepImplementation` come from CucumberSwift:

<!-- swift-example: file swift6 -->
```swift
extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle(for: MyFeatureTests.self) }
    public func setupSteps() { /* ... */ }
}
```

The same goes for `extension Cucumber: @retroactive CucumberTestObservable` when you add a reporter (see <doc:Generating-Reports>).

`StepImplementation` and `CucumberTestObserver` are main-actor protocols, so `setupSteps()`, the steps, hooks and DSL steps declared in it, and a custom reporter's methods can all use main-actor code, such as `XCUIApplication`. An async step can also change a variable it shares with other steps, such as a `var` declared in `setupSteps()`. CucumberSwift calls all of them on the main thread.

In Swift 5 language mode nothing changes: the protocols are marked `@preconcurrency`, so code written for earlier versions of CucumberSwift compiles as before.

## Matching with Cucumber Expressions
[Cucumber expressions](https://github.com/cucumber/cucumber-expressions#readme) are the pattern Cucumber recommends, and the one to reach for first (see <doc:Matching-Steps#Choose-a-pattern>). A parameter such as `{int}` matches text and converts it to its type, and a custom parameter type, with its own regular expression, does the same for a type of your own. A string pattern is read as a Cucumber expression unless it starts with `^`, ends with `$` or is written between slashes, as described above.

Imagine the following step:
```gherkin
Given there are 3 flights from lax.
```

We could match it in CucumberSwift like this. The macro's closure takes each parameter as an argument, already converted to its type. Written as a function, you read each one from `match`:
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

Notice that `{airport}` is a custom parameter. It's type-safe which is great, but how do we create our own custom parameters?

```swift
// Just an example of airports, this is simply your model.
class Airport {
    static let lax = Airport()
}

// This extension must contain all custom parameters you want to use.
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

    // Globally unique name for this parameter
    static let name = "airport"

    // A regular expression to use to match this parameter.
    let regexMatch = #"[A-Z]{3}"#

    // A transform from the matched string to whatever type you want
    func convert(input: String) throws -> Airport {
        switch input.lowercased() {
            case "lax": return Airport.lax
            default:
                throw ParameterError.airportNotFound
        }
    }
}

// A convenience property to use that keypath syntax you saw in the previous example.
extension Match {
    var airport: AirportParameter {
        AirportParameter()
    }
}
```

## Matching with Regular Expressions
Regular expressions can match what a Cucumber expression can't, at the cost of readability and typed arguments (see <doc:Matching-Steps#Choose-a-pattern>). When you need one and your tests run on iOS 16, macOS 13 or tvOS 16 or later, prefer a regex literal to a regular expression in a string: the compiler checks it.

Here's a trivial example. A step definition macro takes the regex literal itself, so it can't take `ignoresCase()`; the function style is the one to use here, and the macros are the recommended style for step definitions that don't need it:
<!-- swift-example: steps bare-slash-regex -->
```swift
When(/^some (\w+) by the actor$/.ignoresCase()) { match, _ in
    XCTAssertEqual(match.1, "action")
}
```

> NOTE: You can use regex builders in Swift to transform into concrete types. It's a little verbose, but is supported by CucumberSwift.

The same step definition with an extended delimiter, which compiles in any test target:
<!-- swift-example: steps -->
```swift
When(#/^some (\w+) by the actor$/#.ignoresCase()) { match, _ in
    XCTAssertEqual(match.1, "action")
}
```

> Important: Regex literals need iOS 16, macOS 13 or tvOS 16. The `/…/` form also needs the Swift 6 language mode or the `BareSlashRegexLiterals` feature. Xcode turns that feature on by default ("Enable Bare Slash Regex Literals"), but a Swift package's target in the Swift 5 language mode needs it set: see <doc:Running-Tests-With-Swift-Package-Manager>. `#/…/#` works without either. On earlier deployment targets, use a string pattern that starts with `^` instead, as described in <doc:Matching-Steps#How-a-string-pattern-is-read>.

## Step definitions for undefined steps
For each step that no step definition matches, CucumberSwift reports a failure with the Swift code for a step definition you can paste in, and attaches all of them to the test `GenerateStepsStubsIfNecessary`. The code is a Cucumber expression, which works on every deployment target, in a step definition macro when your tests link the step definition macros and in a function otherwise, such as with Carthage (see <doc:Matching-Steps#Step-definition-macros>). Whole numbers become `{int}`, decimals `{float}`, and text in double quotes `{string}`. Text in single quotes stays as written:

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

A parameter type that a step uses more than once is read by position, such as `match[\.int, index: 1]`. Characters that mean something in a Cucumber expression, such as `\`, `(`, `{` and `/`, are escaped, and so is a `^` at the start of the step. A step that ends in `$` gets a regular expression instead, such as `Then("^I owe (\\d+)\\$$")`, because a pattern that ends in `$` is always read as one (see <doc:Matching-Steps#How-a-string-pattern-is-read>). Its parameters are text, read with `match[\.anonymous, index: 0]`.

### Generate regex literals instead
Earlier versions generated regex literals. To have them again, set `Cucumber.generateRegexLiterals = true` in your `StepImplementation`'s `setupSteps()`, or set the environment variable `CUCUMBER_GENERATE_REGEX_LITERALS` to `YES` in a scheme or test plan. When both are set, the static variable wins (see <doc:Settings>). The Swift Testing runner reads the same two settings.

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

They are written as `#/…/#`, which compiles in any test target. Return ``RegexLiteralStyle/bareSlash`` from your `StepImplementation`'s `regexLiteralStyle` to get `/…/` instead; it has no effect unless `generateRegexLiterals` is on. Whether your target accepts `/…/` is a setting of your target, which CucumberSwift can't read, so check it in your own code: see <doc:Running-Tests-With-Swift-Package-Manager#Paste-generated-step-definitions>. Regex literals need iOS 16, macOS 13 or tvOS 16.

### Step definition macros
If your tests use the recommended step definition macros (see <doc:Using-Step-Definition-Macros>), CucumberSwift suggests macros instead, as Convert to Gherkin Macros writes them and as the Swift Package Manager tabs above show.

It suggests macros when the test target links `CucumberSwiftMacros`, or `CucumberSwiftTestingMacros` with the Swift Testing runner, built with the `Macros` trait, and functions otherwise, such as with Carthage. To choose for yourself, set `Cucumber.generateMacros` in `setupSteps()` to `false` for functions or `true` for macros, or set the environment variable `CUCUMBER_GENERATE_MACROS` to `NO` or `YES`. When both are set, the static variable wins. The Swift Testing runner reads the same two settings.

The closure takes one typed argument for each parameter: `Int` for `{int}`, `Float` for `{float}` and `String` for `{string}`. A step with a data table or a doc string adds `step: Step` last, to read it. A step that starts with `^` gets a regular expression, such as `#Then("^\\^a caret$")`, because the macro checks the Cucumber expression when it compiles, and a Cucumber expression can't escape a `^`. With `generateRegexLiterals` on as well, the macros take regex literals in the style that `regexLiteralStyle` says, with a `Substring` for each capture group, such as `#Then(#/^the display shows \"(.*?)\"$/#) { (string: Substring) in`.

## When more than one step definition matches a step
Each step should match exactly one step definition. A step that more than one step definition matches is *ambiguous*, as in other Cucumber implementations: CucumberSwift runs none of them, fails the step, and reports it as `ambiguous`. The failure is at the step in the `.feature` file, and it names the file and line of each matching step definition.

A step definition matches a step only if its keyword fits the step. ``Given`` fits a `Given` step and any `And` or `But` step that follows one, and ``MatchAll`` fits every step. So:

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

Two step definitions with the *same* pattern are a mistake even when no step uses them, as in Cucumber for Java. The test run fails at the second one, and the failure names both, if their keywords can match the same steps: the same keyword, ``MatchAll`` with any keyword, or ``And`` or ``But`` with ``Given``, ``When`` or ``Then``. `Given("x")` and `When("x")` are not duplicates. Two patterns count as the same when they are the same regular expression, or the same Cucumber expression. Regex literals, such as `Given(/x/)`, cannot be compared, so only the ambiguity check applies to them.

Earlier versions reported neither: the step definition registered last silently replaced the others, so a step ran whichever came last. To fix an ambiguous step or a duplicate, remove all but one of the step definitions, or make their patterns more specific so that each step matches only one.
