import ProjectDescription

// The parity suite's Xcode project leg: a framework and its tests, run with each runner, as a project that
// uses CucumberSwift as a Swift package would. Both test targets compile ../Shared/ParitySteps.swift and
// bundle ../Shared/Features, as the Swift package leg does. See ../README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

let project = Project(
    name: "Parity",
    packages: [
        .package(path: "../../..")
    ],
    targets: [
        .target(
            name: "ParityShop",
            destinations: [.mac],
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.parity.ParityShop",
            deploymentTargets: .macOS("13.0"),
            sources: ["../Shop/**"],
            settings: settings
        ),
        // Run with CucumberSwift and XCTest. CucumberSwift reads the feature files from the "Features"
        // folder in the test bundle.
        .target(
            name: "ParityXCTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.parity.ParityXCTests",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: ["../Shared/ParitySteps.swift"],
            resources: [.folderReference(path: "../Shared/Features")],
            dependencies: [
                .target(name: "ParityShop"),
                .package(product: "CucumberSwift")
            ],
            settings: settings
        ),
        // Run with Swift Testing. The plugin finds the feature files among the target's files and generates
        // a test for each scenario.
        .target(
            name: "ParitySwiftTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.parity.ParitySwiftTests",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: ["../Shared/ParitySteps.swift"],
            resources: [.folderReference(path: "../Shared/Features")],
            dependencies: [
                .target(name: "ParityShop"),
                .package(product: "CucumberSwiftTesting"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin)
            ],
            settings: .settings(base: settings.base.merging([
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) PARITY_SWIFT_TESTING"
            ]) { $1 })
        )
    ],
    schemes: [
        .scheme(
            name: "ParityXCTests",
            buildAction: .buildAction(targets: ["ParityXCTests"]),
            testAction: .targets(["ParityXCTests"], options: .options(coverage: true))
        ),
        .scheme(
            name: "ParitySwiftTests",
            buildAction: .buildAction(targets: ["ParitySwiftTests"]),
            testAction: .targets(["ParitySwiftTests"], options: .options(coverage: true))
        )
    ]
)
