// swift-tools-version:6.1
// Scores the same feature files run one at a time, in parallel and in shards, with each runner, and checks
// that cucumberswift-coverage-merge gives every way the same scores. See README.md.

import PackageDescription

let package = Package(
    name: "CoverageMergePackage",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        .target(name: "Calculator"),
        .testTarget(
            name: "CalculatorXCTests",
            dependencies: ["Calculator", .product(name: "CucumberSwift", package: "CucumberSwift")],
            resources: [.copy("Features")]),
        .testTarget(
            name: "CalculatorSwiftTests",
            dependencies: ["Calculator", .product(name: "CucumberSwiftTesting", package: "CucumberSwift")],
            // The plugin reads the feature files when the tests build; the tests don't need them.
            exclude: ["Features"],
            plugins: [.plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift")])
    ]
)
