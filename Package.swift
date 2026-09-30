// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CucumberSwift",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CucumberSwift",
            targets: ["CucumberSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
        // Test-only: used by CucumberSwiftTests, not by the CucumberSwift library.
        .package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CucumberSwift",
            dependencies: [
                "CucumberSwiftExpressions"
            ],
            path: "Sources/CucumberSwift",
            exclude: ["Info.plist"]),
        .testTarget(
            name: "CucumberSwiftTests",
            dependencies: [
                "CucumberSwift",
                .product(name: "JSONSchema", package: "JSONSchema.swift")
            ],
            exclude: ["Info.plist", "CucumberTests/CucumberSwift.xctestplan"],
            resources: [
                .copy("testdata"),
                .copy("Features")
            ])
    ]
)
