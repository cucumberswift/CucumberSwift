import ProjectDescription

// An iOS app tested both ways, as a project part-way through moving its unit tests to Swift Testing:
// its UI tests run feature files with CucumberSwift and XCTest, as UI tests must, and its unit tests
// run theirs with Swift Testing, through CucumberSwiftTesting and the CucumberSwiftTestingPlugin build
// tool plugin. Each test target links one runner. See README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

let project = Project(
    name: "SwiftTestingAndXCTestTuist",
    packages: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "BasketApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "org.cucumberswift.fixtures.BasketApp",
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
            bundleId: "org.cucumberswift.fixtures.BasketUnitTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UnitTests/**/*.swift"],
            resources: [.folderReference(path: "UnitTests/Features")],
            dependencies: [
                .target(name: "BasketApp"),
                .package(product: "CucumberSwiftTesting"),
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
            bundleId: "org.cucumberswift.fixtures.BasketUITests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UITests/**/*.swift"],
            resources: [.folderReference(path: "UITests/Features")],
            dependencies: [
                .target(name: "BasketApp"),
                .package(product: "CucumberSwift")
            ],
            settings: settings
        )
    ],
    schemes: [
        .scheme(
            name: "SwiftTestingAndXCTestTuist",
            buildAction: .buildAction(targets: ["BasketApp", "BasketUnitTests", "BasketUITests"]),
            testAction: .targets(["BasketUnitTests", "BasketUITests"])
        )
    ]
)
