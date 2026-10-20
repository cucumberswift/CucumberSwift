# CucumberSwift+UIUTest

A colleague of mine wrote UIUTest which allows for UI testing in a unit testing bundle. It drastically speeds up UI tests but gives a lot of the same functionality, like making sure elements are not covered, able to be tapped etc...

So in many of our projects that have to function at a large scale and have quite a bit of gherkin we combined CucumberSwift and [UIUTest](https://github.com/nallick/UIUTest) for some really cool results!

### SETUP:

#### Packages:
Add [CucumberSwift](https://github.com/cucumberswift/CucumberSwift) and [UIUTest](https://github.com/nallick/UIUTest) to your `AppCucumberTests` target with Swift Package Manager. In Xcode, choose **File > Add Package Dependencies...** and add both to that target only.

#### XCode Setup
When adding your `AppCucumberTests` target make sure to add it as a `Unit Testing Bundle`

There's always a weird tendency for people to lowercase the name of their features folder so the Info.plist should contain `FeaturesPath` with the path to the folder, relative to the test bundle (e.g. `specs/features`). See <doc:Settings#Where-the-feature-files-are>.

#### Magic Happens Here
The `AppCucumberTests.swift` file looks something like this. The Swift Package Manager tab uses the step definition and hook macros, which are the recommended style, and the Carthage tab uses functions, because Carthage can't deliver macros (see <doc:Using-Step-Definition-Macros>):
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
        setupEnrollmentTests() //this is a method that lives in a different file with the Given(regex, closure) syntax. These setup methods usually contain all the implementation needed for a .feature file
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
        setupEnrollmentTests() //this is a method that lives in a different file with the Given(regex, closure) syntax. These setup methods usually contain all the implementation needed for a .feature file
    }
}
```
}
}

#### What was the result?
We saw a huge performance increase using this over XCUITest but got the same value for those tests. At the time we went from about 20 minutes of UI test execution time to about 2 minutes. We chose not to mock our network calls which is why these tests didn't run in a matter of seconds.
