# ``CucumberSwift``

Run Gherkin feature files as tests on iOS, tvOS and macOS.

## Overview

CucumberSwift is a lightweight Cucumber implementation for iOS, tvOS and macOS. You describe behaviour in Gherkin feature files, and match their steps with step definitions written in Swift. CucumberSwift aims to be easy to install and easy to use, and your feedback is welcome.

### Get started

To add CucumberSwift to a test target, follow the step-by-step tutorials in <doc:Tutorial-Table-of-Contents>, with Swift Package Manager or Carthage. The [sample projects](https://cucumberswift.org/CucumberSwiftSample/documentation/cucumberswiftsample/) are working projects, tested every night against the latest CucumberSwift release. Their documentation says what each one shows. The [GettingStarted](https://github.com/cucumberswift/CucumberSwiftSample/tree/main/Tuist/GettingStarted) sample is the setup that the tutorials lead to.

CucumberSwift needs Xcode 16.0 or later, the oldest Xcode that its CI tests with. CI runs on macOS 15 and macOS 26. Your tests can run on iOS 13, macOS 10.15 and tvOS 13 or later. Some features need a newer Xcode, and their articles say which.

### Community and support

Ask questions, get help and discuss CucumberSwift on [Slack](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw), in **#help**. Report bugs and request features in [GitHub issues](https://github.com/cucumberswift/CucumberSwift/issues). Slack keeps only 90 days of history, so anything that settles a bug or a design decision should end up in an issue.

## Topics

### Getting started

- <doc:Tutorial-Table-of-Contents>
- <doc:Running-Tests-In-Xcode>
- <doc:Supported-Platforms>
- <doc:Settings>

### Running tests

- <doc:Running-Tests-With-Swift-Package-Manager>
- <doc:Running-Tests-With-Bazel>
- <doc:Running-Feature-Files-With-Swift-Testing>
- <doc:Running-Scenarios-In-Parallel>

### Writing step definitions

- <doc:Matching-Steps>
- <doc:Using-Step-Definition-Macros>
- <doc:Checking-Step-Definitions>
- <doc:Hooks>

### Checking and reporting

- <doc:Checking-Feature-Files>
- <doc:Generating-Reports>
- <doc:Verbose-Output>

### UI testing

- <doc:CucumberSwift+UIUTest>
