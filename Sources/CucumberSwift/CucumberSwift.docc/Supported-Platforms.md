# Supported platforms

What CucumberSwift supports, sorted by what its CI checks.

## Overview

CucumberSwift supports what its continuous integration (CI) checks. Each claim falls into one of three tiers:

| Tier | What it means | Today |
|---|---|---|
| **Tested** | CI builds it and runs the tests on it | CI uses the oldest Xcode it runs and newer ones up to Xcode 26, on macOS 15 and macOS 26 build machines. The tests run on the iOS Simulator, on Mac Catalyst, and on macOS through Swift Package Manager, on the runtimes each Xcode comes with. |
| **Built, not run** | The compiler checks every API against the deployment target, but no test runs there | Every pull request builds at the deployment targets iOS 13 and macOS 10.15. tvOS 13 joins this tier once CI builds it. |
| **Not supported** | Nothing builds or tests it | This tier covers Xcode versions older than the oldest CI runs, older deployment targets, and anything not listed here. |

### The Xcode you build with

The oldest supported Xcode is the oldest one CI runs. When GitHub's runner image drops that Xcode, the next CucumberSwift release raises its oldest supported Xcode, and its release notes say so.

Apple's requirements for each Xcode decide which macOS you need, so this article names only the Xcode. CI uses macOS 15 and macOS 26 build machines.

### The OS your tests run on

You can add CucumberSwift to the test target of an app that targets iOS 13. Your tests run on every OS version that your Xcode can run tests on. CucumberSwift's own tests don't run on iOS 13 or macOS 10.15, but the compiler checks every CucumberSwift API against those deployment targets. So nothing in a test target needs a newer OS, unless this documentation says so, as it does for regex literals below.

We fix a bug on a "built, not run" OS when we can reproduce it.

### Features that need more than the minimum

Some features need a newer Xcode or Swift than the oldest supported one. CI checks each at exactly the version given:

| Feature | Requires | Checked at |
|---|---|---|
| <doc:Running-Feature-Files-With-Swift-Testing>, and <doc:Using-Step-Definition-Macros> in a Swift package | Xcode 16.3 (Swift 6.1) | Xcode 16.3 |
| <doc:Using-Step-Definition-Macros> in an Xcode or Tuist project | Xcode 26.4 | Xcode 26.4 |
| <doc:Running-Tests-In-Xcode#Convert-to-Gherkin-Macros> in a Swift package | Xcode 16.3 (Swift 6.1) | Xcode 16.3 |
| <doc:Running-Scenarios-In-Parallel> (experimental) | The article lists what has been tried on each platform | The versions its CI jobs run |
| Regex literals in step definitions (<doc:Matching-Steps#Matching-with-Regular-Expressions>) | iOS 16, macOS 13, tvOS 16 at run time | Swift's `@available` on the API |

The article for each of these features shows its requirement as a badge at the top of the page, such as Xcode 16.3, and explains it in a "Requirements" section. A setting that needs more than the oldest supported Xcode says so in its documentation and in the "Requires" column of <doc:Settings>. An OS requirement shows as Swift's `@available` on the API.

### Keeping this current

The tiers match CI at the commit a release is built from. If a claim doesn't match, please [open an issue](https://github.com/cucumberswift/CucumberSwift/issues).
