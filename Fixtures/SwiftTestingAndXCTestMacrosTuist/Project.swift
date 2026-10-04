import ProjectDescription

// SwiftTestingAndXCTestTuist with step definitions written as macros: the UI tests use CucumberSwiftMacros
// with CucumberSwift and XCTest, and the unit tests use CucumberSwiftTestingMacros with Swift Testing. They
// come through StepDefinitionMacros, a local package that turns on CucumberSwift's Macros trait in its own
// manifest, which works with any Xcode that has Swift 6.1. See README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

let project = Project(
    name: "SwiftTestingAndXCTestMacrosTuist",
    packages: [
        // For the CucumberSwiftTestingPlugin build tool plugin.
        .package(path: "../.."),
        // For the macros, with the Macros trait on.
        .package(path: "StepDefinitionMacros")
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
                .package(product: "UnitStepDefinitionMacros"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin)
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
                .package(product: "UIStepDefinitionMacros")
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
