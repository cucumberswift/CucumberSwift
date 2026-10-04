// swift-tools-version:6.1
// Turns on CucumberSwift's Macros trait for the Xcode project around it. Before Xcode 26.4, an Xcode
// project can't turn on a package's traits itself, but a package that it depends on can, in its own
// manifest. Each product re-exports one runner's step definition macros. See ../README.md.

import PackageDescription

let package = Package(
    name: "StepDefinitionMacros",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // For the UI tests, which run with CucumberSwift and XCTest.
        .library(name: "UIStepDefinitionMacros", targets: ["UIStepDefinitionMacros"]),
        // For the unit tests, which run with Swift Testing.
        .library(name: "UnitStepDefinitionMacros", targets: ["UnitStepDefinitionMacros"])
    ],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../../..", traits: ["Macros"])
    ],
    targets: [
        .target(
            name: "UIStepDefinitionMacros",
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")]),
        .target(
            name: "UnitStepDefinitionMacros",
            dependencies: [.product(name: "CucumberSwiftTestingMacros", package: "CucumberSwift")])
    ]
)
