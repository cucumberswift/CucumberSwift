import ProjectDescription

// A macOS framework tested with CucumberSwift and XCTest, for mutation testing on an Xcode project. Its features
// leave 2 changes to its code that no scenario notices. See README.md.
let settings: Settings = .settings(base: [
    "SWIFT_VERSION": "6.0",
    // Builds and runs without a signing team.
    "CODE_SIGN_IDENTITY": "-"
])

// CucumberSwift from this checkout, two folders up. Mutation testing runs on a copy of this folder, where that path no
// longer reaches the checkout, so CI's run sets TUIST_CUCUMBERSWIFT to a git URL, as a project would depend on it.
let cucumberSwiftURL = Environment.cucumberswift.getString(default: "")
let cucumberSwift: Package = cucumberSwiftURL.isEmpty ? .package(path: "../..") : .package(url: cucumberSwiftURL, from: "999.0.0")

let project = Project(
    name: "MutationTestingTuist",
    packages: [cucumberSwift],
    targets: [
        .target(
            name: "Voting",
            destinations: .macOS,
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.Voting",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            settings: settings
        ),
        .target(
            name: "VotingTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.VotingTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Tests/*.swift"],
            // CucumberSwift reads the feature files from the "Features" folder in the test bundle.
            resources: [.folderReference(path: "Tests/Features")],
            dependencies: [
                .target(name: "Voting"),
                .package(product: "CucumberSwift"),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
            ],
            settings: settings
        )
    ],
    schemes: [
        .scheme(
            name: "MutationTestingTuist",
            buildAction: .buildAction(targets: ["Voting", "VotingTests"]),
            testAction: .targets(["VotingTests"])
        )
    ]
)
