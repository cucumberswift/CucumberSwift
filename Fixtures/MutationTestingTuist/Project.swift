import ProjectDescription

// A framework tested with CucumberSwift and XCTest, and with Swift Testing, for mutation testing on an Xcode project,
// for macOS, Mac Catalyst, iOS, tvOS and watchOS: mutation testing picks the destination of the tests. Its features
// leave 3 changes to its code that no scenario notices. See README.md.
let destinations: Destinations = [.mac, .macCatalyst, .iPhone, .appleTv, .appleWatch]
let deploymentTargets: DeploymentTargets = .multiplatform(iOS: "16.0", macOS: "14.0", watchOS: "9.0", tvOS: "16.0")
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
            destinations: destinations,
            product: .framework,
            bundleId: "org.cucumberswift.fixtures.Voting",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["Sources/**"],
            settings: settings
        ),
        .target(
            name: "VotingTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.VotingTests",
            deploymentTargets: deploymentTargets,
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
        ),
        // The same framework tested with Swift Testing, through CucumberSwiftTesting. The plugin finds the feature files
        // among the target's files and generates a test for each scenario.
        .target(
            name: "VotingSwiftTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.VotingSwiftTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: ["SwiftTests/*.swift"],
            resources: [.folderReference(path: "SwiftTests/Features")],
            dependencies: [
                .target(name: "Voting"),
                .package(product: "CucumberSwiftTesting"),
                .package(product: "CucumberSwiftTestingPlugin", type: .plugin),
                // Checks the feature files and step definitions on every build.
                .package(product: "CucumberSwiftLint", type: .plugin)
            ],
            settings: settings
        ),
        // Runs mutation testing on this project from a Run Script build phase, as a project does to see the surviving
        // mutants as warnings in Xcode. `xcodebuild build -scheme Mutation` runs the phase, and the phase runs the command
        // from a CucumberSwift checkout: CUCUMBERSWIFT_CHECKOUT is the checkout's folder, MUTATION_REPORTS the folder
        // for the reports and MUTATION_DESTINATION the destination of the tests, macOS when it isn't set. The phase itself
        // always runs on the Mac, whatever that destination is. The build's variables would reach the command's own
        // `xcodebuild`, so the phase clears them.
        .target(
            name: "Mutation",
            destinations: .macOS,
            product: .bundle,
            bundleId: "org.cucumberswift.fixtures.Mutation",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            scripts: [
                .pre(
                    script: """
                    set -e
                    env -i HOME="$HOME" DEVELOPER_DIR="$DEVELOPER_DIR" TMPDIR="$TMPDIR" PATH=/usr/bin:/bin:/usr/sbin:/sbin \\
                        /usr/bin/swift run --package-path "$CUCUMBERSWIFT_CHECKOUT" --traits Macros cucumberswift-mutation-test \\
                        --root "$SRCROOT" --project MutationTestingTuist.xcodeproj --scheme MutationTestingTuist \\
                        --destination "${MUTATION_DESTINATION:-platform=macOS}" --test-target VotingTests --test-target VotingSwiftTests \\
                        --format xcode --output "$MUTATION_REPORTS" \\
                        --baseline-runs 1 --minimum-timeout 120
                    """,
                    name: "Run mutation testing",
                    basedOnDependencyAnalysis: false
                )
            ],
            settings: .settings(base: [
                "SWIFT_VERSION": "6.0",
                "CODE_SIGN_IDENTITY": "-",
                // The phase runs `swift` and `xcodebuild`, which Xcode's script sandbox blocks.
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO"
            ])
        )
    ],
    schemes: [
        .scheme(
            name: "MutationTestingTuist",
            buildAction: .buildAction(targets: ["Voting", "VotingTests", "VotingSwiftTests"]),
            testAction: .targets(["VotingTests", "VotingSwiftTests"])
        )
    ]
)
