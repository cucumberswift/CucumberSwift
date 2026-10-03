// swift-tools-version:5.8
// 5.8 for enableUpcomingFeature below. Only contributors build this package, so its tools
// version doesn't change what projects that use CucumberSwift need.
// Runs CucumberSwiftConsumerTests with `swift test`, as a consumer of CucumberSwift would.
// It is a separate package because SwiftPM links every test target of a package
// into one test bundle, and each consumer test target declares its own
// `extension Cucumber: StepImplementation`. Only one of those can take effect at
// runtime, so the targets need separate bundles, as Xcode gives them.

import PackageDescription

let package = Package(
    name: "CucumberSwiftConsumerTests",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder,
        // which is not "CucumberSwift" in a worktree or a renamed clone, and the
        // "CucumberSwift" dependency below would no longer resolve.
        .package(name: "CucumberSwift", path: "../..")
    ],
    targets: [
        .testTarget(
            name: "CucumberSwiftConsumerTests",
            dependencies: ["CucumberSwift"],
            path: ".",
            exclude: ["Info.plist", "Package.swift"],
            resources: [
                .copy("Features")
            ],
            // Xcode turns bare slash regex literals on by default, so the Xcode target compiles
            // GeneratedBareSlashStepDefinitions.swift without this.
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ],
            // Checks the feature files on every build, as a consumer would.
            plugins: [.plugin(name: "CucumberSwiftLint", package: "CucumberSwift")])
    ]
)
