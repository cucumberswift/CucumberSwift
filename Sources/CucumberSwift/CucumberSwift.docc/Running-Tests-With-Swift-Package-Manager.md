# Running tests with Swift Package Manager

Run your features with `swift test`, from a test target in a `Package.swift`.

## Overview

You can run CucumberSwift from a test target in a Swift package, not only from the Xcode project that the tutorials set up. Swift Package Manager builds and loads tests differently from Xcode, so a setup copied from an Xcode project needs the changes below.

### Declare the Features folder as a resource

Declare your `Features` folder as a resource with `.copy`, so that it keeps its subfolders:

<!-- swift-example: package-target -->
```swift
.testTarget(
    name: "MyAppFeatureTests",
    dependencies: ["CucumberSwift"],
    resources: [
        .copy("Features")
    ],
    // Checks the feature files on every build: see "Checking feature files while you build".
    plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
```

SwiftPM copies only the files you declare into the test bundle.

The `CucumberSwiftLint` plugin checks your feature files and step definitions each time the target builds, and reports each problem as a warning. See <doc:Checking-Feature-Files>.

The folder must be named `Features`, with that capitalisation. SwiftPM generates the test bundle's `Info.plist` itself, so you can't use the `FeaturesPath` and `FeatureScenarioDelimiter` keys that an Xcode test target can set. See <doc:Settings>.

### Return Bundle.module from your StepImplementation

Return `Bundle.module`, the resource bundle that SwiftPM generates for the target:

<!-- swift-example: file features -->
```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        class ThisBundle {}
        return Bundle(for: ThisBundle.self)
        #endif
    }

    public func setupSteps() {
        // Your steps
    }
}
```

SwiftPM puts resources in a bundle of their own, not in the test bundle, so `Bundle(for:)` doesn't find them. `SWIFT_PACKAGE` is defined only when SwiftPM builds the code. The `#if` lets the same file build in an Xcode test target too. `Bundle.module` exists only for a target that declares resources.

If CucumberSwift finds no features, the run reports one failing test, `FoundNoFeatures`. Its message names the bundle that it searched, and what to change. The other tests in the bundle still run.

### Use one StepImplementation per package

Put all of a package's step definitions behind one `StepImplementation`. SwiftPM links all of a package's test targets into one test bundle, and a bundle can use only one `extension Cucumber: StepImplementation`. With two, only one takes effect, and the other target's features never run, even though `swift test` passes.

If you need separate step implementations, for example for two apps, give each one its own package. That is a folder with a `Package.swift` whose test target depends on your main package by path.

### Don't run in parallel

Run CucumberSwift tests without `--parallel`. `swift test --parallel` runs each test that `swift test list` shows in a process of its own. Scenarios aren't in that list, so none of them run, and the run still passes.

### Choose scenarios with tags

To run some of your scenarios, tag them and set `CUCUMBER_TAGS`:

```bash
CUCUMBER_TAGS=smoke swift test
```

CucumberSwift creates a test for each scenario when the suite runs, so `swift test list` doesn't show them. `swift test --filter` with a scenario's name runs no tests, and still passes.

To see which steps ran and how each scenario ended, turn on verbose output with `CUCUMBER_VERBOSE=1 swift test`. See <doc:Verbose-Output>.

### Know what swift test covers

`swift test` has these limits:

- `swift test` builds and runs your tests on macOS. To test on iOS or tvOS, use Xcode or `xcodebuild` with a destination.
- CucumberSwift uses the Objective-C runtime, so it runs on Apple platforms only.
- Regex literals need macOS 13 or later at runtime, and the `/…/` form needs a compiler setting in the Swift 5 language mode. See <doc:Matching-Steps>.

### Paste generated step definitions

For each step that has no step definition, CucumberSwift reports a failure with the Swift code for one. The code uses a Cucumber expression that compiles in any test target (see <doc:Matching-Steps#Step-definitions-for-undefined-steps>). With `Cucumber.generateRegexLiterals` on, the code uses a regex literal instead, written as `#/^…$/#`, a form that also compiles in any test target.

To get the regex literal written as `/^…$/`, your test target needs bare slash regex literals. The Swift 6 language mode has them. In the Swift 5 language mode, with tools version 5.8 or later, add this setting:

<!-- swift-example: target-arguments -->
```swift
swiftSettings: [
    .enableUpcomingFeature("BareSlashRegexLiterals")
]
```

Then return ``RegexLiteralStyle/bareSlash`` from your `StepImplementation`. To follow the target's setting automatically, check the setting in your own code, where the compiler knows it:

<!-- swift-example: members -->
```swift
public var regexLiteralStyle: RegexLiteralStyle {
    #if compiler(>=5.8) && hasFeature(BareSlashRegexLiterals)
    return .bareSlash
    #else
    return .extendedDelimiter
    #endif
}
```

CucumberSwift can't make this check itself. It's compiled with its own settings, not your target's, and a built test bundle doesn't record its target's language mode or features.
