# Running Tests with Swift Package Manager

Run your features with `swift test`, from a test target in a `Package.swift`.

## Overview

The tutorials set CucumberSwift up in an Xcode project. A test target in a Swift package works too, but Swift Package Manager builds and loads tests differently from Xcode, so a setup copied from an Xcode project needs these changes.

### Declare the Features folder as a resource

SwiftPM copies only the files you declare into the test bundle. Declare your `Features` folder with `.copy`, which keeps its subfolders:

```swift
.testTarget(
    name: "MyAppFeatureTests",
    dependencies: ["CucumberSwift"],
    resources: [
        .copy("Features")
    ])
```

The folder must be named `Features`, with that capitalisation. SwiftPM generates the test bundle's `Info.plist` itself, so the `FeaturesPath` and `FeatureScenarioDelimiter` keys that an Xcode test target can set are not available.

### Return Bundle.module from your StepImplementation

SwiftPM puts resources in a bundle of their own, not in the test bundle, so `Bundle(for:)` does not find them. Return `Bundle.module`, the resource bundle SwiftPM generates for the target:

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        class TestExplorer: CucumberTest { }
        return Bundle(for: TestExplorer.self)
        #endif
    }

    public func setupSteps() {
        // Your steps
    }
}
```

`SWIFT_PACKAGE` is defined only when SwiftPM builds the code. The `#if` lets the same file build in an Xcode test target too. `Bundle.module` exists only for a target that declares resources.

If CucumberSwift finds no features, the run reports one failing test, `FoundNoFeatures`. Its message names the bundle that was searched and what to change. The other tests in the bundle still run.

### Use one StepImplementation per package

SwiftPM links all of a package's test targets into one test bundle, and a bundle can use only one `extension Cucumber: StepImplementation`. With two, one of them takes effect and the other target's features never run, even though `swift test` passes.

Put all of a package's step definitions behind one `StepImplementation`. If you need separate ones, for example for two apps, give each its own package: a folder with a `Package.swift` whose test target depends on your main package by path.

### Don't run in parallel

`swift test --parallel` runs each test that `swift test list` shows in a process of its own. Scenarios are not in that list, so none of them run, and the run still passes. Run CucumberSwift tests without `--parallel`.

### Choose scenarios with tags

CucumberSwift creates a test for each scenario when the suite runs. `swift test list` does not show them, and `swift test --filter` with a scenario's name runs no tests and still passes. To run some scenarios, tag them and set `CUCUMBER_TAGS`:

```bash
CUCUMBER_TAGS=smoke swift test
```

To see which steps ran and how each scenario ended, turn on verbose output: `CUCUMBER_VERBOSE=1 swift test`. See <doc:Verbose-Output>.

### Know what swift test covers

- `swift test` builds and runs your tests on macOS. To test on iOS or tvOS, use Xcode or `xcodebuild` with a destination.
- CucumberSwift uses the Objective-C runtime, so it runs on Apple platforms only.
- Regex literals need macOS 13 or later at runtime, and the `/…/` form needs a compiler setting in the Swift 5 language mode. See <doc:Matching-Steps>.

### Paste generated step definitions

For each step with no step definition, CucumberSwift reports a failure with the Swift code for one, a Cucumber expression that compiles in any test target (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>). With `Cucumber.generateRegexLiterals` on, that code is a regex literal instead, written as `#/^…$/#`, which also compiles in any test target. To have it written as `/^…$/`, your test target needs bare slash regex literals: the Swift 6 language mode, or this setting in the Swift 5 language mode (tools version 5.8 or later):

```swift
swiftSettings: [
    .enableUpcomingFeature("BareSlashRegexLiterals")
]
```

Then return ``RegexLiteralStyle/bareSlash`` from your `StepImplementation`. To follow the target's setting automatically, check it in your own code, where the compiler knows it:

```swift
public var regexLiteralStyle: RegexLiteralStyle {
    #if compiler(>=5.8) && hasFeature(BareSlashRegexLiterals)
    return .bareSlash
    #else
    return .extendedDelimiter
    #endif
}
```

CucumberSwift can't make this check itself: it's compiled with its own settings, not your target's, and a built test bundle doesn't record its target's language mode or features.
