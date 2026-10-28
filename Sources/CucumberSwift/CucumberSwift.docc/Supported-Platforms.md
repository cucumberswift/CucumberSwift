# Supported platforms

What CucumberSwift supports, sorted by what our GitHub Actions CI workflow checks.

## Overview

CucumberSwift supports what our CI checks. Each claim falls into one of 3 tiers:

| Tier | What it means | Today |
|---|---|---|
| **Tested** | Our CI builds it and runs the tests on it | iOS Simulator, tvOS Simulator, Mac Catalyst and macOS, with Xcode 16.0 to 26. watchOS Simulator, with Xcode 26. |
| **Built, not run** | The compiler checks every API against the deployment target, but no test runs there | iOS 13, macOS 10.15, tvOS 13 and watchOS 7.4. |
| **Not supported** | Not built or tested | Older Xcode versions and deployment targets, and anything not listed here. |

### The Xcode you build with

The oldest supported Xcode is 16.0, the oldest Xcode that our CI runs. When GitHub's runner image drops that Xcode, the next CucumberSwift release raises its oldest supported Xcode, and its release notes say so.

Apple's requirements for each Xcode decide which macOS you need, so this article names only the Xcode. Our CI uses macOS 15 and macOS 26 build machines.

### The OS your tests run on

You can add CucumberSwift to the test target of an app that targets iOS 13. Your tests run on every OS version that your Xcode can run tests on. CucumberSwift's own tests don't run on iOS 13, macOS 10.15, tvOS 13 or watchOS 7.4, but the compiler checks every CucumberSwift API against those deployment targets. So nothing in a test target needs a newer OS, unless this documentation says so, as it does for regex literals below.

We fix a bug on a "built, not run" OS when we can reproduce it.

### watchOS

CucumberSwift supports watchOS 7.4 and later, because watchOS 7.4 is the first version with XCTest. Add it to a watchOS test target with Swift Package Manager or Bazel. Carthage doesn't build CucumberSwift for watchOS.

With Bazel, run watchOS tests with the runner that the `cucumberswift` module provides, because rules_apple's own runner doesn't run them. See <doc:Running-Tests-With-Bazel#Run-tests-on-watchOS>.

### Features that need more than the minimum

Some features need a newer Xcode or Swift than the oldest supported one. Our CI checks each at exactly the version given:

| Feature | Requires | Checked at |
|---|---|---|
| <doc:Running-Feature-Files-With-Swift-Testing>, and <doc:Using-Step-Definition-Macros> in a Swift package | Xcode 16.3 (Swift 6.1) | Xcode 16.3 |
| <doc:Using-Step-Definition-Macros> in an Xcode or Tuist project | Xcode 26.4 | Xcode 26.4 |
| <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros> in a Swift package | Xcode 16.3 (Swift 6.1) | Xcode 16.3 |
| <doc:Running-Scenarios-In-Parallel> (experimental) | The article lists what has been tried on each platform | The versions our CI jobs run |
| Regex literals in step definitions (<doc:Matching-Steps#Matching-with-regular-expressions>) | iOS 16, macOS 13, tvOS 16, watchOS 9 at run time | Swift's `@available` on the API |

The article for each of these features shows its requirement as a badge at the top of the page, such as Xcode 16.3, and explains it in a "Requirements" section. The documentation of a setting that needs more than the oldest supported Xcode states the requirement and in the "Requires" column of <doc:Settings>. An OS requirement shows as Swift's `@available` on the API.

### Keeping this current

The tiers match our CI at the commit a release is built from. If a claim doesn't match, please [open an issue](https://github.com/cucumberswift/CucumberSwift/issues).
