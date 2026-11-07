// swift-tools-version:6.1
// 6.1 for package traits, the oldest tools version that can turn on CucumberSwift's Macros trait, which the
// mutation testing tool needs. A Swift package with an XCTest target and a Swift Testing target, for
// `swift run cucumberswift-mutation-test`. See README.md.

import PackageDescription

// The mutation testing tool copies this package to a temporary folder, where "../.." doesn't reach
// CucumberSwift. .github/scripts/mutation-package-fixture.sh sets CUCUMBER_SWIFT_PATH to the checkout's
// absolute path, which the copy reaches too.
let cucumberSwiftPath = Context.environment["CUCUMBER_SWIFT_PATH"].flatMap { $0.isEmpty ? nil : $0 } ?? "../.."

let package = Package(
    name: "MutationTestingPackage",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: cucumberSwiftPath, traits: ["Macros"])
    ],
    targets: [
        // The code that mutation testing changes.
        .target(name: "Voting"),
        // Runs the Voting and Driving features with XCTest.
        .testTarget(
            name: "VotingTests",
            dependencies: ["Voting", .product(name: "CucumberSwift", package: "CucumberSwift")],
            resources: [.copy("Features")]),
        // Runs the Retiring feature with Swift Testing.
        .testTarget(
            name: "VotingSwiftTests",
            dependencies: ["Voting", .product(name: "CucumberSwiftTesting", package: "CucumberSwift")],
            exclude: ["Features"],
            plugins: [.plugin(name: "CucumberSwiftTestingPlugin", package: "CucumberSwift")])
    ]
)
