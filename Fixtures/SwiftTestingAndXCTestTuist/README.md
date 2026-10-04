# UI tests with XCTest, unit tests with Swift Testing, in one Tuist project

An iOS app tested both ways, as a project that moves its unit tests to Swift Testing while its UI tests
stay on XCTest:

- `BasketUITests`, a UI test target, runs `UITests/Features` with CucumberSwift and XCUITest. Xcode doesn't
  allow Swift Testing in UI test targets.
- `BasketUnitTests`, a unit test target hosted in the app, runs `UnitTests/Features` with Swift Testing:
  the `CucumberSwiftTesting` product, and the `CucumberSwiftTestingPlugin` build tool plugin, which Xcode
  runs through its Xcode project support.

Each test target links one runner and has its own feature files and step definitions. One scheme tests
both. If either runner stops working beside the other, this fixture fails.

Runs on the iOS simulator in `xcodebuild-destination`. Needs the Tuist version pinned in `.mise.toml`.
Run every fixture with `mise run test-fixtures`.
