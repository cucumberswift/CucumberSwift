# Sample Projects

Start from a working project that uses CucumberSwift, and see what each part of a setup does.

## Overview

[CucumberSwiftSample](https://github.com/cucumberswift/CucumberSwiftSample) has working projects, each a starting point for one way of using CucumberSwift. They are built and tested on every change and every night, against the latest CucumberSwift release and against CucumberSwift's `main`, so they keep working as CucumberSwift changes.

[Tuist](https://tuist.dev) generates each sample's Xcode project from its `Project.swift`, and [mise](https://mise.jdx.dev) installs the Tuist version the repository pins.

### Run a sample

You need the Xcode that the sample's README names, and mise. Clone the repository, generate the projects, and open one:

```bash
git clone https://github.com/cucumberswift/CucumberSwiftSample.git
cd CucumberSwiftSample
mise install
mise run generate
open Tuist/GettingStarted/GettingStarted.xcodeproj
```

Press ⌘U to run its tests. Xcode's test navigator shows the scenarios after the first run, because CucumberSwift creates the tests when the test bundle starts.

From the command line, `mise run test` builds and tests every sample, and `mise run test GettingStarted` tests one.

To build the samples against a local CucumberSwift checkout instead of the release, set `CUCUMBER_SWIFT_PATH` to its absolute path when you generate the projects:

```bash
CUCUMBER_SWIFT_PATH=~/src/CucumberSwift mise run generate
```

### The samples

| Sample | Shows | Platform | Needs | README |
|---|---|---|---|---|
| [GettingStarted](https://github.com/cucumberswift/CucumberSwiftSample/tree/main/Tuist/GettingStarted) | The smallest working setup: one test target, one feature file, its step definitions | macOS unit test bundle | Xcode 16 or later, CucumberSwift 6.3.0 or later | [README](https://github.com/cucumberswift/CucumberSwiftSample/blob/main/Tuist/GettingStarted/README.md) |
| [TestNavigator](https://github.com/cucumberswift/CucumberSwiftSample/tree/main/Tuist/TestNavigator) | How scenarios read in Xcode's test navigator: readable names, failures at the feature file's line, Scenario Outline examples, skipped scenarios, a test plan per tag | macOS unit test bundle | Xcode 16 or later, CucumberSwift 6.3.0 or later | [README](https://github.com/cucumberswift/CucumberSwiftSample/blob/main/Tuist/TestNavigator/README.md) |

Each sample's README says how to copy it into a project of your own, and its `Project.swift` shows how the test target is set up.

#### GettingStarted

The setup the step-by-step tutorials lead to, in one test target: a feature file, the step definitions that match its steps, and a `Project.swift` that adds CucumberSwift and copies the feature files into the test bundle. Compare your own setup with it, or copy it to start a new project. See <doc:Tutorial-Table-of-Contents> to add CucumberSwift to a project you already have.

#### TestNavigator

Feature files about a shop, run so you can see what Xcode shows for them: a scenario per test class, a numbered test per step, a failing scenario that Xcode reports at the step's line in the feature file, a skipped scenario, a Scenario Outline with each example named after its values, and a test plan for each tag. It fails one scenario on purpose, so the default test plan ends with one failure. See <doc:Running-Tests-In-Xcode> for the same features in words.
