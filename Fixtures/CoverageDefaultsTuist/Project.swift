import ProjectDescription

// A framework tested with Code Coverage on and CucumberSwift's coverage levels left at their defaults, by
// each runner: CucumberSwift with XCTest, and CucumberSwiftTesting with Swift Testing. Each runs a feature
// that covers less than half of the code it enters, which only warns. See README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

let project = Project(
    name: "CoverageDefaultsTuist",
    packages: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "Grades",
            destinations: .macOS,
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.Grades",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            settings: settings
        ),
        .target(
            name: "GradesXCTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.GradesXCTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["XCTests/**/*.swift"],
            // CucumberSwift reads the feature files from the "Features" folder in the test bundle.
            resources: [.folderReference(path: "XCTests/Features")],
            dependencies: [
                .target(name: "Grades"),
                .package(product: "CucumberSwift"),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
            ],
            settings: settings
        ),
        // The plugin finds the feature files among the target's files and generates a test for each scenario.
        .target(
            name: "GradesSwiftTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.GradesSwiftTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["SwiftTests/**/*.swift"],
            resources: [.folderReference(path: "SwiftTests/Features")],
            dependencies: [
                .target(name: "Grades"),
                .package(product: "CucumberSwiftTesting"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin)
            ],
            settings: settings
        )
    ],
    schemes: [
        .scheme(
            name: "CoverageDefaultsTuist",
            buildAction: .buildAction(targets: ["Grades", "GradesXCTests", "GradesSwiftTests"]),
            // Code Coverage on, for the framework, as a project turns it on in its scheme or test plan.
            // CucumberSwift never measures the files in its own package folder, which holds this fixture, so
            // CUCUMBER_COVERAGE_SOURCES names the framework's folder. It sets which files count, not the levels.
            testAction: .targets(
                ["GradesXCTests", "GradesSwiftTests"],
                arguments: .arguments(environmentVariables: [
                    "CUCUMBER_COVERAGE_SOURCES": .environmentVariable(value: "CoverageDefaultsTuist/Sources", isEnabled: true)
                ]),
                options: .options(coverage: true, codeCoverageTargets: ["Grades"])
            )
        )
    ]
)
