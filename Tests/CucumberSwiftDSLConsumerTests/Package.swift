// swift-tools-version:5.5
// Runs CucumberSwiftDSLConsumerTests with `swift test`, as a consumer of CucumberSwift would.
// It is a separate package because SwiftPM links every test target of a package
// into one test bundle, and each consumer test target declares its own
// `extension Cucumber: StepImplementation`. Only one of those can take effect at
// runtime, so the targets need separate bundles, as Xcode gives them.

import PackageDescription

let package = Package(
    name: "CucumberSwiftDSLConsumerTests",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder,
        // which is not "CucumberSwift" in a worktree or a renamed clone, and the
        // "CucumberSwift" dependency below would no longer resolve.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        .testTarget(
            name: "CucumberSwiftDSLConsumerTests",
            dependencies: ["CucumberSwift"],
            path: ".",
            exclude: ["Info.plist", "Package.swift"])
    ]
)
