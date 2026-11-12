import ProjectDescription

// The parity suite's Xcode project leg: a framework and its tests, run with each runner, as a project that
// uses CucumberSwift as a Swift package would. Both test targets compile ../Shared/ParitySteps.swift and
// bundle ../Shared/Features, as the Swift package leg does. A step-definition file added to ../Shared joins both
// test targets with no change here. See ../README.md.

// The platform to build for, from TUIST_PARITY_PLATFORM: macOS, iOS, tvOS or Catalyst. There is no watchOS: the
// Xcode project doesn't build for it, as Carthage doesn't deliver it. .github/scripts/parity-fixture.sh sets it.
let platform = Environment.parityPlatform.getString(default: "macOS")
let destinationsByPlatform: [String: Destinations] = [
    "iOS": [.iPhone],
    "tvOS": [.appleTv],
    "Catalyst": [.macCatalyst]
]
let deploymentTargetsByPlatform: [String: DeploymentTargets] = [
    "iOS": .iOS("16.0"),
    "Catalyst": .iOS("16.0"),
    "tvOS": .tvOS("16.0")
]
let destinations: Destinations = destinationsByPlatform[platform] ?? [.mac]
let deploymentTargets: DeploymentTargets = deploymentTargetsByPlatform[platform] ?? .macOS("13.0")

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
            destinations: destinations,
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.parity.ParityShop",
            deploymentTargets: deploymentTargets,
            sources: ["../Shop/**"],
            settings: settings
        ),
        // Run with CucumberSwift and XCTest. CucumberSwift reads the feature files from the "Features"
        // folder in the test bundle.
        .target(
            name: "ParityXCTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.parity.ParityXCTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["../Shared/*.swift"],
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
            destinations: destinations,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.parity.ParitySwiftTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["../Shared/*.swift"],
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
