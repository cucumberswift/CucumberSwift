![Build Status](https://github.com/cucumberswift/CucumberSwift/actions/workflows/CI.yml/badge.svg?branch=main)
[![Latest version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcucumberswift.org%2FCucumberSwift%2Fversions.json&query=%24.version&label=latest%20version&color=brightgreen)](https://github.com/cucumberswift/CucumberSwift/releases/latest)
[![codecov](https://codecov.io/gh/cucumberswift/CucumberSwift/graph/badge.svg?token=ARIPC8Q7H1)](https://codecov.io/gh/cucumberswift/CucumberSwift)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=cucumberswift_CucumberSwift&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=cucumberswift_CucumberSwift)

### Welcome to CucumberSwift
CucumberSwift is a lightweight Swift only Cucumber implementation for iOS, tvOS, and macOS. It was born out of frustration with current iOS Cucumber implementations. The whole goal is to make it easy to install and easy to use, so please feel free to give feedback.

Describe behaviour in Gherkin feature files and test it with step definitions written in Swift. Works with both XCTest and Swift Testing:

```gherkin
Given I have 5 cukes in my basket
```

```swift
#Given("I have {int} cukes in my basket") { (count: Int) in
    basket.add(count)
}
```

CucumberSwift includes:

1. An XCTest runner for UI and unit tests
2. A Swift Testing runner for unit tests only
3. Step definition macros that the compiler checks, such as `#Given`, `#When` and `#Then`
4. Support for running scenarios in parallel with Xcode's parallel testing
5. Plugins that check and fix your feature files as you build, convert step definitions to macros and generate Swift Testing tests
6. A Swift DSL for writing features in Swift instead of feature files

### Install

Add CucumberSwift to your `Package.swift`. Turn on its `Macros` trait to use the step definition macros:

```swift
dependencies: [
    .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.4.0", traits: ["Macros"]),
    // Before Swift 6.4, SwiftPM needs this to resolve the Macros trait. No target uses it.
    .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
],
```

Then add the `CucumberSwiftMacros` product to your test target for XCTest, or `CucumberSwiftTestingMacros` for Swift Testing. [Using step definition macros](https://cucumberswift.org/CucumberSwift/documentation/cucumberswift/using-step-definition-macros) has the whole setup, for a Swift package and for an Xcode project.

You can also install CucumberSwift with [Carthage](https://cucumberswift.org/CucumberSwift/tutorials/cucumberswift/carthage-step-by-step) or [Bazel](https://cucumberswift.org/CucumberSwift/documentation/cucumberswift/running-tests-with-bazel). CucumberSwift isn't published to CocoaPods from 6.0.0 on. The last version on CocoaPods is 5.0.3. It still resolves, but no newer version will be published there.

CucumberSwift needs Xcode 16.0 or later, the oldest Xcode that our GitHub Actions CI workflow tests with. Our CI runs on macOS 15 and macOS 26. Your tests can run on iOS 13, macOS 10.15, tvOS 13 and watchOS 7.4 or later. The macros and Swift Testing need Xcode 16.3 or later, and the docs say what other features need. Start with these links:

* [Docs](https://cucumberswift.org/CucumberSwift/documentation/cucumberswift/)
* [Getting started](https://cucumberswift.org/CucumberSwift/tutorials/tutorial-table-of-contents/)
* [Sample projects](https://cucumberswift.org/CucumberSwiftSample/documentation/cucumberswiftsample/)

### Community and support
[![Slack](https://img.shields.io/badge/Slack-join%20the%20community-4A154B?style=popout&logo=slack&logoColor=white)](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw)

Come say hi on Slack. Ask questions in **#help**, keep an eye on **#announcements** and **#activity**, and talk shop in **#contributors**, **#general**, and **#random**.

Use Slack for questions, help with using CucumberSwift, and discussion. Use [GitHub issues](https://github.com/cucumberswift/CucumberSwift/issues) for bugs and feature requests. Slack keeps only 90 days of history. If a conversation settles a bug or a design decision, please write it up as an issue before it scrolls away.

### Contributing
Contributions are welcome. See [CONTRIBUTING.md](/CONTRIBUTING.md) for a short guide to how it works.

Before you open a PR, please link an existing issue, or open one that describes the problem or enhancement. Then we can agree on the direction before you write the code. Typo and docs fixes are exempt, so send the PR directly.

## Attributions

CucumberSwift uses work from these projects:

- The localization support for the DSL is built with [SwiftGen](https://github.com/SwiftGen/SwiftGen/)
- The Gherkin keywords for each language come from [`gherkin-languages.json`](https://github.com/cucumber/gherkin/blob/main/gherkin-languages.json) in Cucumber's Gherkin repository
- The parser's test data, the feature files and their ASTs, comes from [Cucumber's Gherkin repository](https://github.com/cucumber/gherkin/tree/main/testdata)
