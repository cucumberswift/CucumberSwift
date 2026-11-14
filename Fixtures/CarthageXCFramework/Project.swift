import ProjectDescription

// An iOS test target that uses CucumberSwift as a Carthage consumer does: it links and embeds
// Carthage/Build/CucumberSwift.xcframework, built by `carthage build` in this checkout, and
// nothing else. See README.md.
let project = Project(
    name: "CarthageXCFramework",
    targets: [
        // The code under test, built from source with code coverage, as an app's own code is.
        .target(
            name: "Cukes",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.Cukes",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            settings: .settings(base: ["SWIFT_VERSION": "5.0", "CODE_SIGN_IDENTITY": "-"])
        ),
        .target(
            name: "CarthageXCFrameworkTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.CarthageXCFrameworkTests",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .default,
            sources: ["Tests/**/*.swift"],
            // A folder reference keeps the feature files in a "Features" folder inside the test
            // bundle, where CucumberSwift looks for them.
            resources: [.folderReference(path: "Tests/Features")],
            // Copied into the test bundle's Frameworks folder by a Copy Files phase, as the
            // Carthage setup tutorial does. Tuist doesn't embed a dependency in a test bundle.
            copyFiles: [
                .frameworks(
                    name: "Embed CucumberSwift",
                    files: [.folderReference(path: "../../Carthage/Build/CucumberSwift.xcframework", codeSignOnCopy: true)]
                )
            ],
            // Checks the feature files before the build with the lint command, as a Carthage project's Run Script
            // phase does: the plugins run only in Swift packages and Xcode projects that use SwiftPM.
            scripts: [
                .pre(
                    script: """
                    export CUCUMBERSWIFT_CHECKOUT="$SRCROOT/../.."
                    "$SRCROOT/cucumberswift.sh" lint --features "$SRCROOT"/Tests/Features/*.feature --step-definitions "$SRCROOT"/Tests/*.swift
                    """,
                    name: "Check feature files with cucumberswift",
                    basedOnDependencyAnalysis: false
                )
            ],
            // Linked.
            dependencies: [
                .target(name: "Cukes"),
                .xcframework(path: "../../Carthage/Build/CucumberSwift.xcframework")
            ],
            settings: .settings(base: [
                // Where the CucumberSwiftExpressions module is, inside the framework.
                "SWIFT_INCLUDE_PATHS": "$(BUILT_PRODUCTS_DIR)/CucumberSwift.framework/Modules",
                // As in a test target from Xcode 26's app template.
                "SWIFT_VERSION": "5.0",
                "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
                // Builds and runs without a signing team.
                "CODE_SIGN_IDENTITY": "-"
            ])
        )
    ],
    schemes: [
        .scheme(
            name: "CarthageXCFramework",
            buildAction: .buildAction(targets: ["Cukes", "CarthageXCFrameworkTests"]),
            // Code Coverage on for the framework. CucumberSwift never measures the files in its own package
            // folder, which holds this fixture, so CUCUMBER_COVERAGE_SOURCES names the framework's folder.
            testAction: .targets(
                ["CarthageXCFrameworkTests"],
                arguments: .arguments(environmentVariables: [
                    "CUCUMBER_COVERAGE_SOURCES": .environmentVariable(value: "CarthageXCFramework/Sources", isEnabled: true)
                ]),
                options: .options(coverage: true, codeCoverageTargets: ["Cukes"])
            )
        )
    ]
)
