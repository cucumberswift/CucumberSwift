# CucumberSwift+UIUTest

Run UI tests as unit tests, with CucumberSwift and UIUTest.

## Overview

[UIUTest](https://github.com/nallick/UIUTest) runs UI tests in a unit test bundle, without XCUITest. It still checks what a UI test checks, such as whether an element is covered or can be tapped. Combined with CucumberSwift, it runs your Gherkin scenarios as fast unit tests.

On 1 large project, UI tests that took about 20 minutes with XCUITest took about 2 minutes with UIUTest. That project didn't mock its network calls, so the tests took minutes and not seconds.

### Add the packages

With Swift Package Manager, choose **File > Add Package Dependencies...** in Xcode, and add [CucumberSwift](https://github.com/cucumberswift/CucumberSwift) and [UIUTest](https://github.com/nallick/UIUTest) to your `AppCucumberTests` target only.

With Carthage, add CucumberSwift as <doc:Carthage-Step-By-Step> describes, so that you don't add it twice. Then add UIUTest to the `AppCucumberTests` target with **File > Add Package Dependencies...**.

### Create the test target

Create the `AppCucumberTests` target as a **Unit Testing Bundle**.

Add `FeaturesPath` to the target's Info.plist if your features folder isn't named `Features`, for example `specs/features`. Its value is the path to the folder, relative to the test bundle. See <doc:Settings#Where-the-feature-files-are>.

### Write the step implementation

`AppCucumberTests.swift` sets up UIUTest in hooks around each scenario. The Swift Package Manager tab uses the step definition and hook macros, the recommended style. The Carthage tab uses functions, because Carthage can't deliver macros (see <doc:Using-Step-Definition-Macros>).

@TabNavigator {
@Tab("Swift Package Manager") {
<!-- swift-example: fragment: needs the UIUTest package and your app, and UIKit, which a macOS build doesn't have -->
```swift
import XCTest
import UIUTest
import CucumberSwiftMacros

@testable import App

extension Cucumber : StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        #BeforeScenario {
            UIViewController.initializeTestable()
        }
        #AfterScenario {
            UIViewController.flushPendingTestArtifacts()
        }
        setupEnrollmentTests() // Defined in another file, with the step definitions for one feature file
    }
}
```
}
@Tab("Carthage") {
<!-- swift-example: fragment: needs the UIUTest package and your app, and UIKit, which a macOS build doesn't have -->
```swift
import XCTest
import UIUTest
import CucumberSwift

@testable import App

extension Cucumber : StepImplementation {
    public var bundle: Bundle {
        class ThisBundle { }
        return Bundle(for: ThisBundle.self)
    }

    public func setupSteps() {
        BeforeScenario { _ in
            UIViewController.initializeTestable()
        }
        AfterScenario { _ in
            UIViewController.flushPendingTestArtifacts()
        }
        setupEnrollmentTests() // Defined in another file, with the step definitions for one feature file
    }
}
```
}
}
