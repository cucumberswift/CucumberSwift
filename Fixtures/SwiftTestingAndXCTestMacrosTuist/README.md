# UI tests with XCTest, unit tests with Swift Testing, written as macros

`SwiftTestingAndXCTestTuist` with its step definitions written as macros, checked when they compile:

- `BasketUITests`, a UI test target, runs `UITests/Features` with CucumberSwift and XCUITest, and writes its
  step definitions with `CucumberSwiftMacros`.
- `BasketUnitTests`, a unit test target hosted in the app, runs `UnitTests/Features` with Swift Testing,
  through the `CucumberSwiftTestingPlugin` build tool plugin, and writes its step definitions with
  `CucumberSwiftTestingMacros`.

CucumberSwift is added with the `Macros` package trait turned on. Each test target links one runner and
has its own feature files and step definitions. One scheme tests both. If the macros stop compiling for
either runner, or either runner stops working beside the other, this fixture fails.

Needs Xcode 26.4 or later: an earlier Xcode doesn't apply a package's traits in an Xcode project, and each
macro then reports that the `Macros` trait has to be turned on. Runs on the iOS simulator in
`xcodebuild-destination`, with the Tuist version pinned in `.mise.toml`. Run every fixture with
`mise run test-fixtures`.
