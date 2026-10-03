// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
// 5.7 (Xcode 14) for the CucumberSwiftLint build tool plugin, and for applying it in Xcode projects.

import PackageDescription

let package = Package(
    name: "CucumberSwift",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CucumberSwift",
            targets: ["CucumberSwift"]),
        // Checks feature files on every build, and shows each problem as a warning in Xcode.
        .plugin(
            name: "CucumberSwiftLint",
            targets: ["CucumberSwiftLintPlugin"]),
        // Fixes the misspelt keywords that CucumberSwiftLint reports: `swift package fix-feature-files`,
        // or Fix Feature Files on the project's or package's menu in Xcode.
        .plugin(
            name: "FixFeatureFiles",
            targets: ["Fix Feature Files"])
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
        // Test-only: used by CucumberSwiftTests, not by the CucumberSwift library.
        .package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        // The classes of the generated tests: the superclass of the tests made for each step, and the
        // class of the tests made for each scenario. Objective-C, so Xcode names them as written,
        // without the "()" of a Swift test.
        .target(
            name: "CucumberSwiftObjC",
            path: "Sources/CucumberSwiftObjC"),
        .target(
            name: "CucumberSwift",
            dependencies: [
                "CucumberSwiftExpressions",
                "CucumberSwiftObjC"
            ],
            path: "Sources/CucumberSwift",
            exclude: ["Info.plist"]),
        // CucumberSwift's Gherkin parser for build tools: Sources/CucumberSwift/Gherkin/Core, through the
        // Core symlink, compiled a second time without XCTest. Not a product.
        .target(
            name: "CucumberSwiftGherkin",
            path: "Sources/CucumberSwiftGherkin"),
        // The tool the CucumberSwiftLint plugin runs. It builds for the Mac that builds the tests.
        .executableTarget(
            name: "CucumberSwiftLintTool",
            dependencies: ["CucumberSwiftExpressions"],
            path: "Sources/CucumberSwiftLintTool"),
        .plugin(
            name: "CucumberSwiftLintPlugin",
            capability: .buildTool(),
            dependencies: ["CucumberSwiftLintTool"],
            path: "Plugins/CucumberSwiftLintPlugin"),
        // Named as Xcode shows it on the project's or package's menu.
        .plugin(
            name: "Fix Feature Files",
            capability: .command(
                intent: .custom(
                    verb: "fix-feature-files",
                    description: "Fixes the misspelt Gherkin keywords that CucumberSwiftLint reports in feature files"),
                permissions: [
                    .writeToPackageDirectory(reason: "Fixes misspelt Gherkin keywords in your feature files")
                ]),
            dependencies: ["CucumberSwiftLintTool"],
            path: "Plugins/FixFeatureFilesPlugin"),
        .testTarget(
            name: "CucumberSwiftGherkinTests",
            // CucumberSwift too, to check that both read feature files alike.
            dependencies: ["CucumberSwiftGherkin", "CucumberSwift"]),
        .testTarget(
            name: "CucumberSwiftLintToolTests",
            dependencies: ["CucumberSwiftLintTool"]),
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
