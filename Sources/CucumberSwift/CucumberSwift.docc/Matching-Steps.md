# Matching Steps

Gherkin defined in `.feature` files can be matched in several ways. All matching is done using global functions that align with gherkin keywords. For example, ``Given``, ``When``, and ``Then`` functions. These functions are also localized, so if you'd rather use spanish you can use ``ES_Dado``. 

## How a string pattern is read
When you pass a string to ``Given``, ``When`` or ``Then``, CucumberSwift decides from its shape whether it is a regular expression or a Cucumber expression, the same way other Cucumber implementations do:

| The string | Is read as | Example |
|---|---|---|
| starts with `^` or ends with `$` | a regular expression | `Given("^the app is at the Main Menu$")` |
| starts and ends with `/` | a regular expression, without the slashes | `Given("/the app is at the Main Menu/")` |
| anything else | a Cucumber expression | `Given("the app is at the {word} Menu")` |

A step definition whose closure takes `[String]`, such as `{ matches, _ in … matches[1] … }`, uses the older regular expression API instead: its string is always a regular expression, and Xcode shows a deprecation warning.

### Upgrading to 6.0.0
Before 6.0.0, a string that started with `^` or ended with `$` was read as a Cucumber expression, which treated `^` and `$` as literal characters. A step definition such as `Given("^the app is at the Main Menu$") { _, _ in }` therefore matched nothing, and its step was reported as unimplemented. From 6.0.0 it is a regular expression and matches as written.

Most step definitions need no change. Step definitions whose closure takes `[String]` are not affected at all: they already read the string as a regular expression. For the rest, check any pattern that starts with `^` or ends with `$` but was meant *literally*, such as a price written as `"I owe 5$"`:

- If it is a valid regular expression, it silently stops matching. `Given("I owe 5$")` no longer matches the step `I owe 5$`, because `$` now means "end of text".
- If it is not a valid regular expression, such as `"I owe {int}$"`, the test run stops with an error that names the pattern.

To match a literal `$` or `^`, write the whole pattern as a regular expression and escape the character. This works on every platform and deployment target:

```swift
Given("^I owe 5\\$$") { _, _ in }   // matches the step "I owe 5$"
```

## Async steps
A step definition can be `async` and `throws`. Write `await` in its closure and CucumberSwift runs it as an async step:

```swift
Given("the user has signed in") { _, _ in
    try await session.signIn(as: .testUser)
}
```

A closure without `await` is an ordinary synchronous step definition, exactly as before. This works with Cucumber expressions, string patterns and regex literals alike.

Steps still run one at a time, in the order the feature file declares them. An async step runs on the main actor, and the next step starts only once it has finished, so nothing in a scenario ever runs in parallel. Awaiting work on other threads or actors is fine: the step resumes on the main actor afterwards.

- **Failures and errors.** An assertion that fails inside an async step fails that step, and a thrown error fails it too. As for any failed step, the rest of the scenario is skipped. With `continueTestingAfterFailure` off (the default), CucumberSwift cancels the step's task when it fails, then waits for it to finish before going on.
- **Timeout.** An async step fails if it has not finished within 60 seconds, and is cancelled. To change this, set `asyncStepTimeout` (in seconds) in your `StepImplementation`:

  ```swift
  extension Cucumber: StepImplementation {
      public var asyncStepTimeout: TimeInterval { 120 }
      // ...
  }
  ```

  Cancellation is cooperative. CucumberSwift waits for a cancelled step to finish before starting the next one, so a step that ignores cancellation holds up the run rather than overlap the step after it.
- **Running another step.** From inside an async step, use `await ExecuteFirstStep(matching:)`. The synchronous `ExecuteFirstStep(matching:)` works from synchronous steps, including when the step it runs is async.

With the Swift DSL, pass an async function or closure rather than a call:

```swift
Feature("Sign in") {
    Scenario("A returning user") {
        Given(I: signIn)                                  // an async function
        When(I: { try await open(.settings) })            // a closure
        Then(the: settingsAreShown())                     // a synchronous call, as before
    }
}
```

## Matching with Cucumber Expressions
Cucumber has [its own expressions](https://github.com/cucumber/cucumber-expressions#readme) that CucumberSwift supports. These are an alternative to regular expressions that are a little more readable. They aren't nearly as powerful when it comes to precise matching, but they can be extended with regular expressions and can very likely meet the majority of use-cases. A string pattern is read as a Cucumber expression unless it starts with `^`, ends with `$` or is written between slashes, as described above.

Imagine the following step:
```gherkin
Given there are 3 flights from lax.
```

We could match it in CucumberSwift like this:
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
Regular expressions are a very powerful tool. If you can support regex literals in your tests, they are by far the preferable method to match with.

Here's a trivial example:
```swift
When(/^some (\w+) by the actor$/.ignoresCase()) { match, _ in
    XCTAssertEqual(match.1, "action")
}
```

> NOTE: You can use regex builders in Swift to transform into concrete types. It's a little verbose, but is supported by CucumberSwift.

> Important: Regex literals need Xcode 14 (Swift 5.7) or later, and iOS 16, macOS 13 or tvOS 16. The `/…/` form above also needs Swift 6 language mode or the `BareSlashRegexLiterals` upcoming feature; `#/…/#` works without either. On earlier deployment targets, use a string pattern that starts with `^` instead, as described in <doc:Matching-Steps#How-a-string-pattern-is-read>.
