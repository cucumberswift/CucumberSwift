# UI tests with XCTest, unit tests with Swift Testing, written as macros

`SwiftTestingAndXCTestTuist` with its step definitions written as macros, checked when they compile:

- `BasketUITests`, a UI test target, runs `UITests/Features` with CucumberSwift and XCUITest, and writes its
  step definitions with `CucumberSwiftMacros`.
- `BasketUnitTests`, a unit test target hosted in the app, runs `UnitTests/Features` with Swift Testing,
  through the `CucumberSwiftTestingPlugin` build tool plugin, and writes its step definitions with
  `CucumberSwiftTestingMacros`.

The macros need CucumberSwift's `Macros` package trait. An Xcode project can turn on a package's traits
itself only from Xcode 26.4, so this one also depends on `MacrosTrait`, a local Swift package that turns
the trait on in its own `Package.swift` and does nothing else. That works with any Xcode that has Swift
6.1. The test targets link and import `CucumberSwiftMacros` and `CucumberSwiftTestingMacros` from
CucumberSwift itself, as they would with Xcode 26.4 and the trait set in the project, so moving to that
needs no change to the step definitions.

Each test target links one runner and has its own feature files and step definitions. One scheme tests
both. If the macros stop compiling for either runner, or the trait stops reaching CucumberSwift through
the local package, or either runner stops working beside the other, this fixture fails.

Runs on the iOS simulator in `xcodebuild-destination`, with the Tuist version pinned in `.mise.toml`. Run
every fixture with `mise run test-fixtures`.
