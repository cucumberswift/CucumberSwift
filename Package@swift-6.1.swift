// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 6.1 and later read this manifest instead of Package.swift. It adds the CucumberSwiftMacros
// product, which needs swift-syntax, behind the Macros trait, so a package that does not turn the
// trait on never resolves or downloads swift-syntax. Keep everything else the same as Package.swift.

import CompilerPluginSupport
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
            targets: ["Fix Feature Files"]),
        // Step definition macros, checked at compile time. Needs the Macros trait.
        .library(
            name: "CucumberSwiftMacros",
            targets: ["CucumberSwiftMacros"])
    ],
    traits: [
        .trait(name: "Macros", description: "Builds the CucumberSwiftMacros product, which depends on swift-syntax.")
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git", from: "1.4.1"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
        // Test-only: used by CucumberSwiftTests, not by the CucumberSwift library.
        .package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0"),
        // Only resolved when the Macros trait is on. 601 is the version Swift 6.1 ships with.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "601.0.0"..<"603.0.0")
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
        // The compiler plugin that expands the step definition macros. It runs on the Mac that builds.
        .macro(
            name: "CucumberSwiftMacrosPlugin",
            dependencies: [
                "CucumberSwiftExpressions",
                .product(name: "SwiftSyntax", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftDiagnostics", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax", condition: .when(traits: ["Macros"]))
            ],
            path: "Sources/CucumberSwiftMacrosPlugin"),
        .target(
            name: "CucumberSwiftMacros",
            dependencies: ["CucumberSwift", "CucumberSwiftExpressions", "CucumberSwiftMacrosPlugin"],
            path: "Sources/CucumberSwiftMacros"),
        .testTarget(
            name: "CucumberSwiftMacrosTests",
            dependencies: [
                "CucumberSwiftMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax", condition: .when(traits: ["Macros"]))
            ]),
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
    // The other targets are written for Swift 5, as Package.swift builds them.
    swiftLanguageModes: [.v5]
)
