![Build Status](https://github.com/cucumberswift/CucumberSwift/actions/workflows/CI.yml/badge.svg?branch=main)
[![Latest version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcucumberswift.org%2FCucumberSwift%2Fversions.json&query=%24.version&label=latest%20version&color=brightgreen)](https://github.com/cucumberswift/CucumberSwift/releases/latest)
[![codecov](https://codecov.io/gh/cucumberswift/CucumberSwift/graph/badge.svg?token=ARIPC8Q7H1)](https://codecov.io/gh/cucumberswift/CucumberSwift)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=cucumberswift_CucumberSwift&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=cucumberswift_CucumberSwift)

### Welcome to CucumberSwift
CucumberSwift is a lightweight Swift only Cucumber implementation for iOS, tvOS, and macOS. It was born out of frustration with current iOS Cucumber implementations. The whole goal is to make it easy to install and easy to use, so please feel free to give feedback.

NOTE: WatchOS support coming soon!

NOTE: CocoaPods is no longer supported as of 6.0.0. The last version published to CocoaPods is 5.0.3, and it keeps resolving, but there will be no newer ones. Install CucumberSwift with Swift Package Manager or Carthage instead.

CucumberSwift needs Xcode 16.0 or later, the oldest Xcode its CI tests with; CI runs on macOS 15 and macOS 26. Your tests can run on iOS 13, macOS 10.15 and tvOS 13 or later. Some features need a newer Xcode, and the docs say which.

* [Docs](https://cucumberswift.github.io/CucumberSwift/documentation/cucumberswift/)
* [Getting Started](https://cucumberswift.github.io/CucumberSwift/tutorials/tutorial-table-of-contents/)
* [Sample projects](https://cucumberswift.org/CucumberSwiftSample/documentation/cucumberswiftsample/)
* [XCTest Integration](https://github.com/cucumberswift/CucumberSwift/wiki/xctest-integration)

### Community & Support
[![Slack](https://img.shields.io/badge/Slack-join%20the%20community-4A154B?style=popout&logo=slack&logoColor=white)](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw)

Come say hi on Slack. Ask questions in **#help**, keep an eye on **#announcements** and **#activity**, and talk shop in **#contributors**, **#general**, and **#random**.

Slack is for questions, usage help, and discussion. [GitHub issues](https://github.com/cucumberswift/CucumberSwift/issues) are for bugs and feature requests. Slack only keeps 90 days of history, so if a conversation settles a bug or a design decision, please write it up as an issue before it scrolls away.

### Contributing
Contributions are very welcome, see [CONTRIBUTING.md](/CONTRIBUTING.md) for the short version of how it works.

Before opening a PR, please link an existing issue or open one describing the problem or enhancement first, so we can agree on direction before you write the code. Typos and docs fixes are exempt, just send the PR.

## Attributions:
- The localization support for the DSL is powered by: [SwiftGen](https://github.com/SwiftGen/SwiftGen/)
- The language localization JSON file is powered by: [The Official Cucumber Repo](https://github.com/Cucumber/Cucumber/)
- The AST test JSON file is supplied by: [The Official Cucumber Repo](https://github.com/Cucumber/Cucumber/)
