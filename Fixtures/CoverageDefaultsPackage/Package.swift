// swift-tools-version:6.1
// A package whose tests run feature files with each runner, XCTest and Swift Testing, with code coverage
// on and CucumberSwift's coverage levels left at their defaults. See README.md.

import PackageDescription

let package = Package(
    name: "CoverageDefaultsPackage",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        .target(name: "Grades"),
        .testTarget(
            name: "GradesXCTests",
            dependencies: ["Grades", .product(name: "CucumberSwift", package: "CucumberSwift")],
            resources: [.copy("Features")]),
        .testTarget(
            name: "GradesSwiftTests",
            dependencies: ["Grades", .product(name: "CucumberSwiftTesting", package: "CucumberSwift")],
            // The plugin reads the feature files when the tests build; the tests don't need them.
            exclude: ["Features"],
            plugins: [.plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift")])
    ]
)
