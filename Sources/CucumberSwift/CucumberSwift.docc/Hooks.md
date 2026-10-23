# Hooks

Run your own code before and after each feature, scenario and step, for example to set up preconditions or to clean up.

## Overview

Each example on this page has two tabs. The **Swift Package Manager** tab uses the hook macros, and the **Carthage** tab uses the hook functions. <doc:Hooks#Hook-macros> explains the difference.

## Types of hooks

CucumberSwift has six hooks: `BeforeFeature`, `AfterFeature`, `BeforeScenario`, `AfterScenario`, `BeforeStep` and `AfterStep`. Register them in `setupSteps()`:

@TabNavigator {
@Tab("Swift Package Manager") {
```swift
import Foundation
import XCTest
import CucumberSwiftMacros

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        #BeforeFeature { feature in
            // Called once before the feature. You can register it in more than one file.
        }
        
        #AfterFeature { feature in
            
        }
        
        #BeforeScenario { scenario in
            
        }

        #AfterScenario { scenario in
            
        }

        #BeforeStep { step in
            
        }

        #AfterStep { step in
            
        }
    }
}
```
}

@Tab("Carthage") {
```swift
import Foundation
import XCTest
import CucumberSwift

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        BeforeFeature { feature in
            // Called once before the feature. You can register it in more than one file.
        }
        
        AfterFeature { feature in
            
        }
        
        BeforeScenario { scenario in
            
        }

        AfterScenario { scenario in
            
        }

        BeforeStep { step in
            
        }

        AfterStep { step in
            
        }
    }
}
```
}
}

You can register hooks in more than one place. CucumberSwift still calls each hook once.

### Hook macros

The hook macros, `#BeforeFeature`, `#AfterFeature`, `#BeforeScenario`, `#AfterScenario`, `#BeforeStep` and `#AfterStep`, are the preferred way to write hooks. The compiler checks each closure where you write it. The closure takes the hook's `Feature`, `Scenario` or `Step`, or no argument. Anything else is an error that says what the hook passes, and offers a fix. The macros also keep a step definitions file in one style, next to `#Given` and the other step definition macros. A macro expands to the hook function of the same name, with the same `priority:` and closure, so it runs exactly as the function does.

The hook functions keep working, so existing hooks need no change. Use them where the macros aren't available. The macros need CucumberSwift's `Macros` package trait, and the trait downloads swift-syntax (see <doc:Using-Step-Definition-Macros>). **Convert to Gherkin Macros** rewrites hook functions as macros, together with your step definitions. Tagged hooks have no macro.

### Async hooks

A hook can be `async` and `throws`. Write `await` in its closure:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#BeforeScenario { (scenario: Scenario) in
    try await server.reset()
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
BeforeScenario { scenario in
    try await server.reset()
}
```
}
}

An async hook's closure runs on the main actor, at the same point as a synchronous hook. CucumberSwift waits for each one to finish before it goes on, so hooks and steps never run in parallel. A thrown error fails the test at the hook. The `asyncStepTimeout` described in <doc:Matching-Steps#Async-steps> applies to hooks too. Priorities work the same way for async and synchronous hooks.

### Feature hooks in a parallel run

When scenarios run in parallel, each worker runs `BeforeFeature` and `AfterFeature` for the features it runs. When `AfterFeature` runs depends on what Xcode hands out. See <doc:Running-Scenarios-In-Parallel#Feature-hooks>.

### Attachments

Call `Attach(_:)` to attach a screenshot, a log or a file to the running test. It works in any hook and in any step, and takes any `XCTAttachment`. Hooks and steps aren't `XCTestCase` methods, so they have no `add(_:)`.

Set the attachment's `lifetime` to `.keepAlways`. Otherwise Xcode deletes the attachment when the test passes. Set its `name` to label it.

In a UI test target, attach a screenshot of the screen:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: steps -->
```swift
#AfterScenario { (scenario: Scenario) in
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = scenario.title
    screenshot.lifetime = .keepAlways
    Attach(screenshot)
}
```
}
@Tab("Carthage") {
<!-- swift-example: steps -->
```swift
AfterScenario { scenario in
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = scenario.title
    screenshot.lifetime = .keepAlways
    Attach(screenshot)
}
```
}
}

`XCUIScreen` works only in a UI test target. In a unit test bundle, `screenshot()` fails the test with "Not authorized for performing UI testing actions".

In a unit test bundle, for example with UIUTest, attach a view that you render yourself, or text or data:

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: fragment: uses UIKit, which a macOS build doesn't have -->
```swift
#AfterScenario { (scenario: Scenario) in
    let image = UIGraphicsImageRenderer(bounds: view.bounds).image { context in
        view.layer.render(in: context.cgContext)
    }
    let snapshot = XCTAttachment(image: image)
    snapshot.name = scenario.title
    snapshot.lifetime = .keepAlways
    Attach(snapshot)
}

#AfterStep { (step: Step) in
    Attach(XCTAttachment(string: "Ran: \(step.match)"))
}
```
}
@Tab("Carthage") {
<!-- swift-example: fragment: uses UIKit, which a macOS build doesn't have -->
```swift
AfterScenario { scenario in
    let image = UIGraphicsImageRenderer(bounds: view.bounds).image { context in
        view.layer.render(in: context.cgContext)
    }
    let snapshot = XCTAttachment(image: image)
    snapshot.name = scenario.title
    snapshot.lifetime = .keepAlways
    Attach(snapshot)
}

AfterStep { step in
    Attach(XCTAttachment(string: "Ran: \(step.match)"))
}
```
}
}

#### Where to find an attachment

`Attach(_:)` adds the attachment to the test that is running. CucumberSwift generates one test per step, and `AfterScenario` runs at the end of the scenario's last step. So an `AfterScenario` attachment is on the last step's test. An `AfterStep` attachment is on its own step's test. With one test per scenario, every attachment is on the scenario's test.

In Xcode, open the **Report navigator**, choose the test run, expand the scenario and select the step's test. The attachment is listed under an **Attachment** activity, named after the attachment's `name`.

### Hook order

Give a hook a `priority` to control when it runs. A lower priority runs earlier, so priority 1 runs before priority 2. Hooks without a priority run after the hooks with one, in the order they appear in your code.

To run after hooks in reverse order, as cucumber-jvm does, return `true` from `reverseOrderForAfterHooks` in your `StepImplementation`. A hook with an earlier priority then runs later, and hooks with the same priority run in the reverse of the order you registered them. The Swift Testing runner does the same for `AfterScenario` and `AfterStep` hooks.

@TabNavigator {
@Tab("Swift Package Manager") {
```swift
import Foundation
import XCTest
import CucumberSwiftMacros

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    // Uncomment if you want reverse order of 'after' hooks execution
    // public var reverseOrderForAfterHooks: Bool { true }

    public func setupSteps() {
        // This hook will execute last, because it uses UInt.max as a priority
        #BeforeFeature(priority: .max) { (feature: Feature) in
            // Called once before the feature. You can register it in more than one file.
        }
        
        // This hook executes first, even though it is declared second
        #BeforeFeature(priority: 1) { (feature: Feature) in
            // Called once before the feature. You can register it in more than one file.
        }
    }
}
```
}
@Tab("Carthage") {
```swift
import Foundation
import XCTest
import CucumberSwift

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    // Uncomment if you want reverse order of 'after' hooks execution
    // public var reverseOrderForAfterHooks: Bool { true }

    public func setupSteps() {
        // This hook will execute last, because it uses UInt.max as a priority
        BeforeFeature(priority: .max) { feature in
            // Called once before the feature. You can register it in more than one file.
        }
        
        // This hook executes first, even though it is declared second
        BeforeFeature(priority: 1) { feature in
            // Called once before the feature. You can register it in more than one file.
        }
    }
}
```
}
}
