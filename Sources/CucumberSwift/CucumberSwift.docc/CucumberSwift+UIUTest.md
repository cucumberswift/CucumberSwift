# CucumberSwift+UIUTest

A colleague of mine wrote [UIUTest](https://github.com/nallick/UIUTest) which allows for UI testing in a unit testing bundle. It drastically speeds up UI tests but gives a lot of the same functionality, like making sure elements are not covered, able to be tapped etc...

So in many of our projects that have to function at a large scale and have quite a bit of gherkin we combined CucumberSwift and UIUTest for some really cool results!

### SETUP:

Add both `CucumberSwift` and `UIUTest` as dependencies via Swift Package Manager.

#### Xcode Setup
When adding your `AppCucumberTests` target make sure to add it as a `Unit Testing Bundle`

There's always a weird tendency for people to lowercase the name of their features folder so the plist should contain  `FeaturesPath` with the relative path to the folder (e.g. `specs/features`)

#### Magic Happens Here
The `AppCucumberTests.swift` file looks something like this
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

#### What was the result?
We saw a huge performance increase using this over XCUITest but got the same value for those tests. At the time we went from about 20 minutes of UI test execution time to about 2 minutes. We chose not to mock our network calls which is why these tests didn't run in a matter of seconds.
