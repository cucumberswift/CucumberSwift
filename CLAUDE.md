# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is CucumberSwift?

A lightweight, Swift-only Cucumber (BDD/Gherkin) implementation for iOS, tvOS, and macOS. It parses `.feature` files, matches steps to Swift closures, and integrates with XCTest for test execution.

## Build & Test Commands

**Run unit tests** (primary CI command — uses Xcode via Fastlane):
```
fastlane unit_test
```

**Build with SwiftPM:**
```
swift build -c release --build-path ./build
# or via fastlane:
fastlane build_swiftpm
```

**Run tests with SwiftPM:**
```
swift test
```

**Run a single test:**
```
swift test --filter CucumberSwiftTests.ParserTests/testSpecificMethod
```

**SwiftLint** is configured (`.swiftlint.yml`) — CI does not run it as a separate step but rules are enforced. Key settings: line length warning at 191/error at 220, type contents order enforced (cases → typeAliases → subtypes → properties → methods → initializers).

## Architecture

### Gherkin Parsing Pipeline
`Feature file → Lexer (tokenization) → AST (rule-based parsing) → Feature/Scenario/Step model objects`

- **Lexer** (`Sources/CucumberSwift/Gherkin/Lexer/`) — converts `.feature` file text into tokens
- **AST** (`Sources/CucumberSwift/Gherkin/AST/`) — rule-based parser that consumes tokens and produces the model hierarchy
- **Parser** (`Sources/CucumberSwift/Gherkin/Parser/`) — individual parsers for Feature, Scenario, Step, ScenarioOutline, Rule, DataTable, DocString

### Execution
- **`Cucumber.shared`** — singleton that manages features, hooks, and step definitions
- **`CucumberTest`** — XCTest subclass; override `setupSteps()` to define Given/When/Then
- **`XCTestCaseGenerator`** — dynamically creates XCTestCase classes at runtime via method swizzling on XCTestSuite
- **Hooks** (`Runner/Hooks/`) — before/after lifecycle hooks at Feature, Scenario, and Step levels

### DSL
An alternative to `.feature` files — define features programmatically in Swift. Uses `#file`, `#line`, `#column` to extract step text from source code at the call site.

### Step Matching
Steps are matched against definitions using three strategies (via `CucumberSwiftExpressions` dependency):
- Regex strings: `Given("^I have (\\d+) cukes$")`
- Swift Regex (iOS 16+): `When(/I have (\d+) cukes/)`
- Cucumber Expressions: `Then("I have {int} cukes")`

## Test Structure

- **`CucumberSwiftTests/`** — unit tests for parser, lexer, extensions, hooks, reporter
- **`CucumberSwiftConsumerTests/`** — integration tests consuming the library via feature files
- **`CucumberSwiftDSLConsumerTests/`** — integration tests for the DSL API
- **`testdata/`** — fixture directories with good and bad `.feature` files (copied as test resources)

## Key Files

- `Sources/CucumberSwift/Gherkin/Languages.swift` — large generated file (~87KB) with i18n keyword data for all Gherkin languages. Do not edit manually.
- `Sources/CucumberSwift/Generated/` — auto-generated i18n code (via SwiftGen). Do not edit manually.

## Package Management

Distributed via **Swift Package Manager** (Package.swift). CocoaPods support was dropped in v5.1.0 (March 2026). Version bumps are handled by fastlane lanes (`patch`, `minor`, `major`) which update the Info.plist.
