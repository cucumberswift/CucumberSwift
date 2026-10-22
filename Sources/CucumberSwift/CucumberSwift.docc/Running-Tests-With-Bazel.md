# Running tests with Bazel

Run your features with `bazel test`, from an `ios_unit_test` or `macos_unit_test` target.

## Overview

CucumberSwift is a Bazel module. Its library builds with [rules_swift](https://github.com/bazelbuild/rules_swift), and your tests run with the test rules of [rules_apple](https://github.com/bazelbuild/rules_apple). Bazel builds and packages tests differently from Xcode, so a setup copied from an Xcode project needs the changes below.

### Add the module

CucumberSwift is in the [Bazel Central Registry](https://registry.bazel.build/modules/cucumberswift) as a module named `cucumberswift`. Add it to your `MODULE.bazel`:

```starlark
bazel_dep(name = "cucumberswift", version = "6.7.0")
```

Bazel adds CucumberSwiftExpressions (the module `cucumberswift_expressions`) for you. The registry lists every version you can use.

If a release isn't in the registry yet, fetch it from GitHub with a `git_override` on its release tag:

```starlark
bazel_dep(name = "cucumberswift", version = "6.7.0")
git_override(module_name = "cucumberswift", remote = "https://github.com/cucumberswift/CucumberSwift.git", tag = "6.7.0")
```

Change the version and the tag together. If the release also needs a CucumberSwiftExpressions version that isn't in the registry, add `cucumberswift_expressions` the same way. Use the version that CucumberSwift's `MODULE.bazel` names:

```starlark
bazel_dep(name = "cucumberswift_expressions", version = "1.4.2")
git_override(module_name = "cucumberswift_expressions", remote = "https://github.com/cucumberswift/CucumberSwiftExpressions.git", tag = "1.4.2")
```

A `git_override` works only in the root module, which is your project's `MODULE.bazel`.

Your tests also need `rules_apple` and `rules_swift`. CI tests CucumberSwift with these versions:

```starlark
bazel_dep(name = "apple_support", version = "2.9.1")
bazel_dep(name = "rules_apple", version = "5.2.0")
bazel_dep(name = "rules_swift", version = "4.1.2")
```

The module needs Bazel 8 or later. CI tests it with the latest Bazel 8 release and with Bazel 9.2.0.

### Put the Features folder at the root of the test bundle

CucumberSwift looks for a folder named `Features` at the root of the test bundle. Add the folder to an `apple_resource_group` as `structured_resources`, which keeps its subfolders. Bazel keeps each file's path relative to the folder of your `BUILD.bazel` file, so remove any folders above `Features` with `strip_structured_resources_prefixes`:

```starlark
load("@rules_apple//apple:ios.bzl", "ios_unit_test")
load("@rules_apple//apple:resources.bzl", "apple_resource_group")
load("@rules_swift//swift:swift_library.bzl", "swift_library")

apple_resource_group(
    name = "MyAppFeatures",
    structured_resources = glob(["MyAppFeatureTests/Features/**"]),
    strip_structured_resources_prefixes = ["MyAppFeatureTests"],
)

swift_library(
    name = "MyAppFeatureTestsLib",
    testonly = True,
    srcs = glob(["MyAppFeatureTests/*.swift"]),
    data = [":MyAppFeatures"],
    deps = ["@cucumberswift//:CucumberSwift"],
)

ios_unit_test(
    name = "MyAppFeatureTests",
    minimum_os_version = "13.0",
    deps = [":MyAppFeatureTestsLib"],
)
```

For macOS, load `macos_unit_test` from `@rules_apple//apple:macos.bzl` and use it the same way, with a `minimum_os_version` of `"10.15"` or later.

If CucumberSwift finds no features, the run reports one failing test, `FoundNoFeatures`. Its message names the bundle it searched.

`CucumberSwift` links XCTest, so it's a `testonly` target. Only `testonly` targets can depend on it.

### Return the test bundle from your StepImplementation

Return the bundle of a class in your tests. Bazel puts resources in the test bundle itself, as Xcode does:

```swift
extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class TestExplorer: CucumberTest { }
        return Bundle(for: TestExplorer.self)
    }

    public func setupSteps() {
        // Your steps
    }
}
```

Only Swift Package Manager generates `Bundle.module`. Code shared with a Swift package can check `#if SWIFT_PACKAGE`, as in <doc:Running-Tests-With-Swift-Package-Manager>.

### Choose scenarios with tags

Pass `CUCUMBER_TAGS` to the test with `--test_env`. Bazel passes a test only the environment variables you name:

```bash
bazel test //MyApp:MyAppFeatureTests --test_env=CUCUMBER_TAGS=smoke
```

Pass every other environment variable in <doc:Settings>, such as `CUCUMBER_VERBOSE`, the same way.

### Paste generated step definitions

CucumberSwift generates step definitions as Cucumber expressions, which compile in any test target. To get regex literals written as `#/^…$/#` instead, turn on `Cucumber.generateRegexLiterals` in `setupSteps()`, or pass `--test_env=CUCUMBER_GENERATE_REGEX_LITERALS=YES`. See <doc:Matching-Steps#Generate-regex-literals-instead>.

To get them written as `/^…$/` in the Swift 5 language mode, turn on bare slash regex literals in your `swift_library`:

```starlark
copts = ["-enable-upcoming-feature", "BareSlashRegexLiterals"],
```

Then return ``RegexLiteralStyle/bareSlash`` from your `StepImplementation`. See <doc:Running-Tests-With-Swift-Package-Manager> for how to follow the setting automatically.
