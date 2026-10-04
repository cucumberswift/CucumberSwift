import ProjectDescription

// A Tuist project that uses the step definition macros: CucumberSwift from this checkout with
// the Macros package trait turned on, and the CucumberSwiftMacros product. The tests only compile
// when the trait reaches Xcode, which needs Xcode 26.4 or later. See README.md.
let project = Project(
    name: "StepDefinitionMacrosTuist",
    packages: [
        .package(path: "../..", traits: ["Macros"])
    ],
    targets: [
        .target(
            name: "StepDefinitionMacrosTuistTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.StepDefinitionMacrosTuistTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Tests/**/*.swift"],
            // A folder reference keeps the feature files in a "Features" folder inside the test
            // bundle, where CucumberSwift looks for them.
            resources: [.folderReference(path: "Tests/Features")],
            dependencies: [
                .package(product: "CucumberSwiftMacros"),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
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
            name: "StepDefinitionMacrosTuist",
            buildAction: .buildAction(targets: ["StepDefinitionMacrosTuistTests"]),
            testAction: .targets(["StepDefinitionMacrosTuistTests"])
        )
    ]
)
