// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// 6.0 (Xcode 16.0), the oldest Xcode CI builds with. Only Swift 6.0 reads this manifest: Swift 6.1 and
// later (Xcode 16.3 and later) read Package.swift. Name it @swift-6.0, not @swift-6: every Swift 6 would
// read a Package@swift-6.swift.

import PackageDescription

let package = Package(
    name: "CucumberSwift",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS("7.4")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CucumberSwift",
            targets: ["CucumberSwift"]),
        // Checks feature files on every build, and shows each problem as a warning in Xcode.
        .plugin(
            name: "CucumberSwiftLint",
            targets: ["CucumberSwiftLintPlugin"]),
        // CucumberSwift's command-line tool: `swift run cucumberswift coverage merge <folder>` scores the
        // scenarios of several runs as one run, such as a parallel run's workers or a suite's shards. It also has
        // the commands that the plugins run: generate, lint, fix-feature-files and convert-to-gherkin-macros, so
        // that Carthage and Bazel projects, which have no plugins, run them too.
        .executable(
            name: "cucumberswift",
            targets: ["CucumberSwiftCommand"]),
        // Fixes the misspelt keywords that CucumberSwiftLint reports: `swift package fix-feature-files`,
        // or Fix Feature Files on the project's or package's menu in Xcode.
        .plugin(
            name: "FixFeatureFiles",
            targets: ["Fix Feature Files"])
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
        // Test-only: used by CucumberSwiftTests and CucumberSwiftTestingTests, not by the libraries.
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
        // Merges the coverage of several runs and scores it: the coverage scores' files, through symlinks to
        // Sources/CucumberSwift/Coverage, compiled without XCTest or Swift Testing. Not a product.
        .target(
            name: "CucumberSwiftCoverageMerge",
            path: "Sources/CucumberSwiftCoverageMerge"),
        // The commands of the cucumberswift tool: one library target for each, and the line that picks one.
        .target(
            name: "CucumberSwiftCommandLine",
            dependencies: [
                "CucumberSwiftCoverageMerge",
                // The generate and convert-to-gherkin-macros commands need Swift 6.1: see Package.swift.
                "CucumberSwiftLintTool"
            ],
            path: "Sources/CucumberSwiftCommandLine"),
        // The tool behind the cucumberswift product.
        .executableTarget(
            name: "CucumberSwiftCommand",
            dependencies: ["CucumberSwiftCommandLine"],
            path: "Sources/CucumberSwiftCommand"),
        // The tool that the plugins run: the same command line. A plugin can only run an executable target that
        // has an implicit product, and CucumberSwiftCommand is in the cucumberswift product under another name.
        .executableTarget(
            name: "CucumberSwiftPluginCommand",
            dependencies: ["CucumberSwiftCommandLine"],
            path: "Sources/CucumberSwiftPluginCommand"),
        // The lint and fix-feature-files commands, which the CucumberSwiftLint and Fix Feature Files plugins run
        // through the cucumberswift tool. CucumberSwiftGherkin for the keywords of feature files in other languages.
        .target(
            name: "CucumberSwiftLintTool",
            dependencies: ["CucumberSwiftExpressions", "CucumberSwiftGherkin"],
            path: "Sources/CucumberSwiftLintTool"),
        .plugin(
            name: "CucumberSwiftLintPlugin",
            capability: .buildTool(),
            dependencies: ["CucumberSwiftPluginCommand"],
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
            dependencies: ["CucumberSwiftPluginCommand"],
            path: "Plugins/FixFeatureFilesPlugin"),
        .testTarget(
            name: "CucumberSwiftCoverageMergeTests",
            dependencies: ["CucumberSwiftCoverageMerge"]),
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
    ],
    // Written for Swift 5. Tools version 6.0 would otherwise build every target in the Swift 6 language mode.
    swiftLanguageModes: [.v5]
)
