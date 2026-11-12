// swift-tools-version:6.1
// The parity suite's Swift package leg: a library and its tests, run with each runner, as a project that
// depends on CucumberSwift would. Both test targets are symbolic links to ../Shared, so they compile the
// same step definitions and bundle the same feature files. See ../README.md.

import PackageDescription

let package = Package(
    name: "Parity",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../../..")
    ],
    targets: [
        .target(name: "ParityShop"),
        .testTarget(
            name: "ParityXCTests",
            dependencies: ["ParityShop", .product(name: "CucumberSwift", package: "CucumberSwift")],
            resources: [.copy("Features")]),
        .testTarget(
            name: "ParitySwiftTests",
            dependencies: ["ParityShop", .product(name: "CucumberSwiftTesting", package: "CucumberSwift")],
            resources: [.copy("Features")],
            swiftSettings: [.define("PARITY_SWIFT_TESTING")],
            plugins: [.plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift")])
    ]
)
