![Build Status](https://github.com/cucumberswift/CucumberSwift/actions/workflows/CI.yml/badge.svg?branch=main)
[![Latest version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcucumberswift.org%2FCucumberSwift%2Fversions.json&query=%24.version&label=latest%20version&color=brightgreen)](https://github.com/cucumberswift/CucumberSwift/releases/latest)
[![codecov](https://codecov.io/gh/cucumberswift/CucumberSwift/graph/badge.svg?token=ARIPC8Q7H1)](https://codecov.io/gh/cucumberswift/CucumberSwift)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=cucumberswift_CucumberSwift&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=cucumberswift_CucumberSwift)

### Welcome to CucumberSwift
CucumberSwift is a lightweight Cucumber implementation for iOS, tvOS and macOS, written only in Swift. You describe behaviour in Gherkin feature files, and match their steps with step definitions written in Swift. CucumberSwift aims to be easy to install and easy to use, and your feedback is welcome.

watchOS support is coming soon.

CucumberSwift isn't published to CocoaPods from 6.0.0 on. The last version on CocoaPods is 5.0.3. It still resolves, but no newer version will be published there. Install CucumberSwift with Swift Package Manager or Carthage instead.

CucumberSwift needs Xcode 16.0 or later, the oldest Xcode that its CI tests with. CI runs on macOS 15 and macOS 26. Your tests can run on iOS 13, macOS 10.15 and tvOS 13 or later. Some features need a newer Xcode, and the docs say which. Start with these links:

* [Docs](https://cucumberswift.github.io/CucumberSwift/documentation/cucumberswift/)
* [Getting started](https://cucumberswift.github.io/CucumberSwift/tutorials/tutorial-table-of-contents/)
* [Sample projects](https://cucumberswift.org/CucumberSwiftSample/documentation/cucumberswiftsample/)
* [XCTest integration](https://github.com/cucumberswift/CucumberSwift/wiki/xctest-integration)

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
- The language localization JSON file comes from [the official Cucumber repository](https://github.com/Cucumber/Cucumber/)
- The AST test JSON file comes from [the official Cucumber repository](https://github.com/Cucumber/Cucumber/)
