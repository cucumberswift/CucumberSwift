// swift-tools-version:6.1
// 6.1 for package traits, the oldest tools version that can turn on CucumberSwift's Macros trait.
// A project that runs its feature files with Swift Testing, as "Running Feature Files with Swift
// Testing" describes: the CucumberSwiftTestingPlugin build tool plugin, the CucumberSwiftTestingMacros
// product with the Macros trait, and a unit test target in the Swift 6 language mode. See README.md.

import PackageDescription

let package = Package(
    name: "SwiftTestingPackage",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../..", traits: ["Macros"])
    ],
    targets: [
        .testTarget(
            name: "SwiftTestingPackageTests",
            dependencies: [.product(name: "CucumberSwiftTestingMacros", package: "CucumberSwift")],
            // The plugin reads the feature files when the tests build; the tests don't need them.
            exclude: ["Features"],
            plugins: [
                // Generates a Swift Testing test for each scenario.
                .plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift"),
                // Checks the feature files and step definitions on every build.
                .plugin(name: "CucumberSwiftLint", package: "CucumberSwift")
            ])
    ]
)
