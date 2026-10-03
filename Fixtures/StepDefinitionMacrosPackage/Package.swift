// swift-tools-version:6.1
// 6.1 for package traits, the oldest tools version that can turn on CucumberSwift's Macros trait.
// A project that uses the step definition macros from a Swift package, as described in "Checking
// Step Definitions When They Compile": the Macros trait turned on, the CucumberSwiftMacros product,
// and a test target in the Swift 6 language mode. See README.md.

import PackageDescription

let package = Package(
    name: "StepDefinitionMacrosPackage",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../..", traits: ["Macros"])
    ],
    targets: [
        .testTarget(
            name: "StepDefinitionMacrosPackageTests",
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")],
            resources: [.copy("Features")])
    ]
)
