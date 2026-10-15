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
        .package(name: "CucumberSwift", path: "../..", traits: ["Macros"]),
        // As the article shows: before Swift 6.4, SwiftPM needs it to resolve the Macros trait when CucumberSwift
        // comes from a URL, as it does in CI's Fixture tests. No target uses it. A version, not the article's
        // range: this package has no committed Package.resolved, and SonarCloud asks for a locked version.
        // Keep it within the range CucumberSwift accepts.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "604.0.0")
    ],
    targets: [
        .testTarget(
            name: "StepDefinitionMacrosPackageTests",
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")],
            resources: [.copy("Features")],
            // Checks the feature files and step definitions on every build.
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
    ]
)
