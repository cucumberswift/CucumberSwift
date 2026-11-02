import ProjectDescription

// A framework tested by CucumberSwift and XCTest with Code Coverage on and CucumberSwift's coverage levels
// left at their defaults. Its feature covers less than half of the code it enters, which only warns, so the
// feature's Coverage test passes. See README.md.
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
        )
    ],
    schemes: [
        .scheme(
            name: "CoverageDefaultsTuist",
            buildAction: .buildAction(targets: ["Grades", "GradesXCTests"]),
            // Code Coverage on, for the framework, as a project turns it on in its scheme or test plan.
            // CucumberSwift never measures the files in its own package folder, which holds this fixture, so
            // CUCUMBER_COVERAGE_SOURCES names the framework's folder. It sets which files count, not the levels.
            testAction: .targets(
                ["GradesXCTests"],
                arguments: .arguments(environmentVariables: [
                    "CUCUMBER_COVERAGE_SOURCES": .environmentVariable(value: "CoverageDefaultsTuist/Sources", isEnabled: true)
                ]),
                options: .options(coverage: true, codeCoverageTargets: ["Grades"])
            )
        )
    ]
)
