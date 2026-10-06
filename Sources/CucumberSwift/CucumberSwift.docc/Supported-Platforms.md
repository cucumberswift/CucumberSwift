# Supported Platforms

What CucumberSwift supports, sorted by what its CI checks.

## Overview

CucumberSwift supports what its continuous integration (CI) verifies. This article sorts each claim into a tier by what CI does, so you can tell a promise that is tested every day from one that only the compiler checks.

| Tier | What it means | Today |
|---|---|---|
| **Tested** | CI builds it and runs the tests on it | The oldest Xcode CI runs, and newer ones up to Xcode 26, on macOS 15 and macOS 26 build machines. The tests run on the iOS Simulator, on Mac Catalyst, and on macOS through Swift Package Manager, on the runtimes each Xcode comes with. |
| **Built, not run** | The compiler checks every API against the deployment target, but no test runs there | Deployment targets iOS 13 and macOS 10.15: every pull request builds at them. tvOS 13, once CI builds it. |
| **Not supported** | Not built or tested | Xcode versions older than the oldest CI runs, older deployment targets, and anything not listed here. |

### The Xcode you build with

**The oldest supported Xcode is the oldest one CI runs.** When GitHub's runner image drops it, CucumberSwift's oldest supported Xcode rises in the next release, and that release's notes say so.

This article names the Xcode, not the macOS you build on: Apple's requirements for each Xcode decide which macOS it needs. CI uses macOS 15 and macOS 26 build machines.

### The OS your tests run on

"Built, not run" says what it means for a test framework: CucumberSwift's own tests don't run on iOS 13 or macOS 10.15, but a project whose app targets iOS 13 can add CucumberSwift to its test target, and its tests run on the OS versions that the Xcode you use can run them on. The compiler checks every CucumberSwift API against the deployment target, so nothing in a test target needs a newer OS unless this documentation says so, as it does for regex literals below.

A bug you report on an OS that is "built, not run" is fixed when it can be reproduced.

### Features that need more than the floor

Some features need a newer Xcode or Swift than the oldest supported one. Each says so the same way everywhere, and CI checks each at exactly the version given:

| Feature | Requires | Checked at |
|---|---|---|
| <doc:Running-Feature-Files-With-Swift-Testing>, and <doc:Checking-Step-Definitions> in a Swift package | Xcode 16.3 (Swift 6.1) | Xcode 16.3 |
| <doc:Checking-Step-Definitions> in an Xcode or Tuist project | Xcode 26.4 | Xcode 26.4 |
| <doc:Running-Tests-In-Xcode#Parallel-testing> (experimental) | Per platform: the article lists what has been tried | The versions its CI jobs run |
| Regex literals in step definitions: <doc:Matching-Steps#Matching-with-Regular-Expressions> | iOS 16, macOS 13, tvOS 16 at run time | Swift's `@available` on the API |

An article about such a feature shows its requirement as a badge at the top of the page, such as Xcode 16.3, and has a "Requirements" section that says why. A setting that needs more than the oldest supported Xcode says so in its documentation and in the "Requires" column of <doc:Settings>. A requirement on the OS your tests run on is Swift's `@available` on the API, which this documentation shows by itself.

### Keeping this current

The tiers match CI at the commit a release is cut from. If you find a claim that doesn't, please [open an issue](https://github.com/cucumberswift/CucumberSwift/issues).
