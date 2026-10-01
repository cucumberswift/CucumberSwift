# Hooks

Hooks are used to tie into CucumberSwift's runtime. They are great for setting up preconditions before a feature, or cleaning up after it is completed.

## Types of Hooks
CucumberSwift comes with 6 hooks, Before/After Feature Before/After Scenario and Before/After step, use them like so

NOTE: Hooks can be setup in more than 1 place however each hook will only be called once
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
            //called once before the feature, but can be setup in more than 1 file.
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

### Async hooks
A hook can be `async` and `throws`. Write `await` in its closure:

```swift
BeforeScenario { scenario in
    try await server.reset()
}
```

An async hook's closure runs on the main actor, at the same point as a synchronous hook would. CucumberSwift waits for each one to finish before going on, so hooks and steps never run in parallel. A thrown error fails the test at the hook, and the `asyncStepTimeout` described in <doc:Matching-Steps#Async-steps> applies to hooks too. Priorities work the same for async and synchronous hooks.

### Attachments
Hooks and steps are not `XCTestCase` methods, so there is no `add(_:)` to attach a screenshot, a log or a file with. Call `Attach(_:)` instead. It works in any hook and in any step, and takes any `XCTAttachment`.

Set `lifetime` to `.keepAlways`, because Xcode deletes an attachment when the test passes unless you do. Set `name` to label it.

**In a UI test target**, attach a screenshot of the screen:

```swift
AfterScenario { scenario in
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = scenario.title
    screenshot.lifetime = .keepAlways
    Attach(screenshot)
}
```

`XCUIScreen` only works in a UI test target. In a unit test bundle, `screenshot()` fails the test with "Not authorized for performing UI testing actions".

**In a unit test bundle** (for example with UIUTest), attach a view you render yourself, or text or data:

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

#### Where to find an attachment
An attachment is added to the test that is running. CucumberSwift generates one test per step, and `AfterScenario` runs at the end of the scenario's last step, so its attachment is on that last step's test. An `AfterStep` attachment is on its own step.

In Xcode, open the **Report navigator**, choose the test run, expand the scenario and select the step's test. The attachment is listed under an **Attachment** activity, named after the attachment's `name`.

### Execution Order
If you never specify anything hooks will just execute in whatever order they appear in the code. However if you need specific control you can add a `priority` to hooks. The lower the priority, the earlier it executes. So a priority 1 executes before a priority 2.

Other cucumber engines might have different behaviour for hooks order. For example cucumber-jvm reverses order for `@After` hooks. I.e. the earlier the priority the later `@After` hook is executed. Also `@After` hooks are executed in reverse order of registering.
Option `reverseOrderForAfterHooks` can be overriden for `StepImplementation` and set to true to make similar behaviour.

NOTE: If you do *not* specify an order hooks with no priority will execute *after* hooks with a priority

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
            //called once before the feature, but can be setup in more than 1 file.
        }
        
        // This hook executes first, even though it is declared second
        BeforeFeature(priority: 1) { feature in
            //called once before the feature, but can be setup in more than 1 file.
        }
    }
}
```
