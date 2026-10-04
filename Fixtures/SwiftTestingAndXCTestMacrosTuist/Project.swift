import ProjectDescription

// SwiftTestingAndXCTestTuist with step definitions written as macros: the UI tests use CucumberSwiftMacros
// with CucumberSwift and XCTest, and the unit tests use CucumberSwiftTestingMacros with Swift Testing.
// MacrosTrait, a local package, turns on CucumberSwift's Macros trait in its own manifest, which works with
// any Xcode that has Swift 6.1. See README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

let project = Project(
    name: "SwiftTestingAndXCTestMacrosTuist",
    packages: [
        // For the macros, the runners and the plugins. With Xcode 26.4 or later, this could be
        // `.package(path: "../..", traits: ["Macros"])`, without MacrosTrait.
        .package(path: "../.."),
        // Only turns on CucumberSwift's Macros trait. Nothing links it.
        .package(path: "MacrosTrait")
    ],
    targets: [
        .target(
            name: "BasketApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "org.cucumberswift.fixtures.macros.BasketApp",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": .dictionary([:])]),
            sources: ["App/**"],
            settings: settings
        ),
        // Unit tests, run with Swift Testing. The plugin finds the feature files among the target's
        // files and generates a test for each scenario.
        .target(
            name: "BasketUnitTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.macros.BasketUnitTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UnitTests/**/*.swift"],
            resources: [.folderReference(path: "UnitTests/Features")],
            dependencies: [
                .target(name: "BasketApp"),
                .package(product: "CucumberSwiftTestingMacros"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
            ],
            settings: settings
        ),
        // UI tests, run with CucumberSwift and XCTest. Xcode doesn't allow Swift Testing in UI tests.
        // CucumberSwift reads the feature files from the "Features" folder in the test bundle.
        .target(
            name: "BasketUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "org.cucumberswift.fixtures.macros.BasketUITests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UITests/**/*.swift"],
            resources: [.folderReference(path: "UITests/Features")],
            dependencies: [
                .target(name: "BasketApp"),
                .package(product: "CucumberSwiftMacros"),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
            ],
            settings: settings
        )
    ],
    schemes: [
        .scheme(
            name: "SwiftTestingAndXCTestMacrosTuist",
            buildAction: .buildAction(targets: ["BasketApp", "BasketUnitTests", "BasketUITests"]),
            testAction: .targets(["BasketUnitTests", "BasketUITests"])
        )
    ]
)
