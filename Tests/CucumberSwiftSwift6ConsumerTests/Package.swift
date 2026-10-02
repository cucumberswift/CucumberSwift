// swift-tools-version:6.0
// 6.0 so the test target builds in the Swift 6 language mode. Only contributors build this
// package, so its tools version doesn't change what projects that use CucumberSwift need.
// Uses CucumberSwift from a test target in the Swift 6 language mode, as a consumer would, to
// check that the documented Swift 6 setup compiles and runs (#243). It is a separate package for
// the same reason as the other consumer test packages: each declares its own
// `extension Cucumber: StepImplementation`, so each needs its own test bundle.

import PackageDescription

let package = Package(
    name: "CucumberSwiftSwift6ConsumerTests",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder,
        // which is not "CucumberSwift" in a worktree or a renamed clone, and the
        // "CucumberSwift" dependency below would no longer resolve.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        .testTarget(
            name: "CucumberSwiftSwift6ConsumerTests",
            dependencies: ["CucumberSwift"],
            path: ".",
            exclude: ["Package.swift"],
            resources: [
                .copy("Features")
            ],
            // Checks the feature files on every build, as a consumer would.
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
    ]
)
