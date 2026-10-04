import ProjectDescription

// An iOS test target that uses CucumberSwift as a Carthage consumer does: it links and embeds
// Carthage/Build/CucumberSwift.xcframework, built by `carthage build` in this checkout, and
// nothing else. See README.md.
let project = Project(
    name: "CarthageXCFramework",
    targets: [
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
            // Linked.
            dependencies: [.xcframework(path: "../../Carthage/Build/CucumberSwift.xcframework")],
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
            buildAction: .buildAction(targets: ["CarthageXCFrameworkTests"]),
            testAction: .targets(["CarthageXCFrameworkTests"])
        )
    ]
)
