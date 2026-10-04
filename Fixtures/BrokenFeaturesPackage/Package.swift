// swift-tools-version:6.1
// Feature files that are broken on purpose, run by both runners with the plugins on, to prove that
// CucumberSwift reports each problem. `mise run test-fixtures` expects this package's tests to fail,
// with the warnings in expected-warnings and the failures in expected-failures. See README.md.

import PackageDescription

let package = Package(
    name: "BrokenFeaturesPackage",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        // CucumberSwift's XCTest runner, which reads the feature files from the test bundle.
        .testTarget(
            name: "BrokenXCTestTests",
            dependencies: [.product(name: "CucumberSwift", package: "CucumberSwift")],
            resources: [.copy("Features")],
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")]),
        // The Swift Testing runner, whose plugin reads the feature files when the tests build.
        .testTarget(
            name: "BrokenSwiftTestingTests",
            dependencies: [.product(name: "CucumberSwiftTesting", package: "CucumberSwift")],
            exclude: ["Features"],
            plugins: [
                .plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift"),
                .plugin(name: "CucumberSwiftLint", package: "CucumberSwift")
            ])
    ]
)
