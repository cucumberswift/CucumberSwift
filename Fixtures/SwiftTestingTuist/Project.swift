import ProjectDescription

// A Tuist project that runs its feature files with Swift Testing: CucumberSwift from this checkout,
// the CucumberSwiftTesting product, and the CucumberSwiftTestingPlugin build tool plugin, which Xcode
// runs through its Xcode project support. No package trait, so it needs no Xcode 26.4. See README.md.
let project = Project(
    name: "SwiftTestingTuist",
    packages: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "SwiftTestingTuistTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.SwiftTestingTuistTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Tests/**/*.swift"],
            // The plugin finds the feature files among the target's files. The tests don't read them.
            resources: [.folderReference(path: "Tests/Features")],
            dependencies: [
                .package(product: "CucumberSwiftTesting"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin)
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                // Builds and runs without a signing team.
                "CODE_SIGN_IDENTITY": "-"
            ])
        )
    ],
    schemes: [
        .scheme(
            name: "SwiftTestingTuist",
            buildAction: .buildAction(targets: ["SwiftTestingTuistTests"]),
            testAction: .targets(["SwiftTestingTuistTests"])
        )
    ]
)
