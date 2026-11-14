// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 6.1 and later (Xcode 16.3 and later) read this manifest; Swift 6.0 reads Package@swift-6.0.swift.
// This one adds the macros and Swift Testing, which need swift-syntax, behind the Macros trait, so a
// package that does not turn the trait on never resolves or downloads swift-syntax. Keep everything else
// the same as Package@swift-6.0.swift.

import CompilerPluginSupport
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
            targets: ["Fix Feature Files"]),
        // Rewrites existing step definitions as step definition macros: `swift package convert-to-gherkin-macros`,
        // or Convert to Gherkin Macros on the project's or package's menu in Xcode. Needs the Macros trait.
        .plugin(
            name: "ConvertToGherkinMacros",
            targets: ["Convert to Gherkin Macros"]),
        // Step definition macros, checked at compile time. Needs the Macros trait.
        .library(
            name: "CucumberSwiftMacros",
            targets: ["CucumberSwiftMacros"]),
        // Runs feature files with Swift Testing, in unit test targets: the step definition API, and the
        // runner the generated tests call.
        .library(
            name: "CucumberSwiftTesting",
            targets: ["CucumberSwiftTesting"]),
        // The step definition macros for CucumberSwiftTesting. Needs the Macros trait.
        .library(
            name: "CucumberSwiftTestingMacros",
            targets: ["CucumberSwiftTestingMacros"]),
        // Generates a Swift Testing test for each scenario in a test target's feature files.
        .plugin(
            name: "CucumberSwiftTestingPlugin",
            targets: ["CucumberSwiftTestingPlugin"])
    ],
    // The Swift Package Index sets SPI_BUILD in its compatibility builds, so the trait is on there and the
    // macros get a compatibility result too. It is off for everyone else.
    traits: [
        .trait(name: "Macros", description: "Builds the CucumberSwiftMacros product, which depends on swift-syntax."),
        .default(enabledTraits: Context.environment["SPI_BUILD"] == nil ? [] : ["Macros"])
    ],
    dependencies: [
        .package(url: "https://github.com/cucumberswift/CucumberSwiftExpressions.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
        // Test-only: used by CucumberSwiftTests and CucumberSwiftTestingTests, not by the libraries.
        .package(url: "https://github.com/kylef/JSONSchema.swift", from: "0.6.0"),
        // Only resolved when the Macros trait is on. 600 is the oldest version the macros build with: they
        // read TypeEffectSpecifiersSyntax.throwsClause, which 600 added. The nightly CI run builds and tests
        // them against it. They build and pass their tests with every version up to 604; raise the upper
        // bound once they do with the next one. A wide range lets a project use them alongside another
        // macro package, whichever swift-syntax version that one needs.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0")
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
                "CucumberSwiftLintTool",
                "CucumberSwiftMacroConverterTool",
                "CucumberSwiftTestingGenerator"
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
        // The convert-to-gherkin-macros command, which the Convert to Gherkin Macros plugin runs through the
        // cucumberswift tool. It reads and writes Swift code with swift-syntax, so without the Macros trait it only
        // says what to turn on. Its tests run the tool as a program (`--stdin`), not linked in: SwiftPM links every
        // test target into one bundle, and a second target that links swift-syntax breaks the macros' tests with
        // Swift 6.2's prebuilt swift-syntax. It shares StepPattern.swift with the compiler plugin, through a symlink.
        .target(
            name: "CucumberSwiftMacroConverterTool",
            dependencies: [
                "CucumberSwiftExpressions",
                .product(name: "SwiftSyntax", package: "swift-syntax", condition: .when(traits: ["Macros"])),
                .product(name: "SwiftParser", package: "swift-syntax", condition: .when(traits: ["Macros"]))
            ],
            path: "Sources/CucumberSwiftMacroConverterTool"),
        // Named as Xcode shows it on the project's or package's menu.
        .plugin(
            name: "Convert to Gherkin Macros",
            capability: .command(
                intent: .custom(
                    verb: "convert-to-gherkin-macros",
                    description: "Rewrites step definitions as step definition macros where the macro expands to the same step definition"),
                permissions: [
                    .writeToPackageDirectory(reason: "Rewrites step definitions as step definition macros in your Swift files")
                ]),
            dependencies: ["CucumberSwiftPluginCommand"],
            path: "Plugins/ConvertToGherkinMacrosPlugin"),
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
        // The Swift Testing runner. No XCTest, and none of CucumberSwift: a test target uses one runner or
        // the other.
        .target(
            name: "CucumberSwiftTesting",
            dependencies: ["CucumberSwiftExpressions"],
            path: "Sources/CucumberSwiftTesting"),
        // StepDefinitionMacros.swift and HookMacros.swift are symlinks to CucumberSwiftMacros' declarations.
        .target(
            name: "CucumberSwiftTestingMacros",
            dependencies: ["CucumberSwiftTesting", "CucumberSwiftExpressions", "CucumberSwiftMacrosPlugin"],
            path: "Sources/CucumberSwiftTestingMacros"),
        // The generate command, which CucumberSwiftTestingPlugin runs through the cucumberswift tool.
        .target(
            name: "CucumberSwiftTestingGenerator",
            dependencies: ["CucumberSwiftGherkin"],
            path: "Sources/CucumberSwiftTestingGenerator"),
        .plugin(
            name: "CucumberSwiftTestingPlugin",
            capability: .buildTool(),
            dependencies: ["CucumberSwiftPluginCommand"],
            path: "Plugins/CucumberSwiftTestingPlugin"),
        .testTarget(
            name: "CucumberSwiftCoverageMergeTests",
            dependencies: ["CucumberSwiftCoverageMerge"]),
        .testTarget(
            name: "CucumberSwiftTestingGeneratorTests",
            dependencies: ["CucumberSwiftTestingGenerator"]),
        .testTarget(
            name: "CucumberSwiftTestingTests",
            // JSONSchema, to check the report against Cucumber's schema, as CucumberSwiftTests does.
            dependencies: [
                "CucumberSwiftTesting",
                .product(name: "JSONSchema", package: "JSONSchema.swift")
            ]),
        .testTarget(
            name: "CucumberSwiftMacrosTests",
            dependencies: [
                "CucumberSwiftMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax", condition: .when(traits: ["Macros"]))
            ]),
        .testTarget(
            name: "CucumberSwiftMacroConverterTests",
            // The macros, to check that what the converter writes expands to the step definition it replaced,
            // and the expressions, to check that a regex literal's string regular expression matches alike.
            // Not the converter: see the tool's comment.
            dependencies: [
                "CucumberSwiftMacrosPlugin",
                "CucumberSwiftExpressions",
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
    // The other targets are written for Swift 5, as Package@swift-6.0.swift builds them.
    swiftLanguageModes: [.v5]
)
