import ProjectDescription

// A macOS framework tested with CucumberSwift and XCTest, and with Swift Testing, for mutation testing on an Xcode
// project. Its features leave 3 changes to its code that no scenario notices. See README.md.
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
        ),
        // The same framework tested with Swift Testing, through CucumberSwiftTesting. The plugin finds the feature files
        // among the target's files and generates a test for each scenario.
        .target(
            name: "VotingSwiftTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "org.cucumberswift.fixtures.VotingSwiftTests",
            deploymentTargets: .macOS("14.0"),
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
        // from a CucumberSwift checkout: CUCUMBERSWIFT_CHECKOUT is the checkout's folder and MUTATION_REPORTS the folder
        // for the reports. With MUTATION_TOOL set, the phase runs that built tool instead of building one with `swift run`.
        // The build's variables would reach the command's own `xcodebuild`, so the phase clears them.
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
                    if [ -n "${MUTATION_TOOL:-}" ]; then
                        set -- "$MUTATION_TOOL" mutation-test
                    else
                        set -- /usr/bin/swift run --package-path "$CUCUMBERSWIFT_CHECKOUT" --traits Macros cucumberswift mutation-test
                    fi
                    env -i HOME="$HOME" DEVELOPER_DIR="$DEVELOPER_DIR" TMPDIR="$TMPDIR" PATH=/usr/bin:/bin:/usr/sbin:/sbin "$@" \\
                        --root "$SRCROOT" --project MutationTestingTuist.xcodeproj --scheme MutationTestingTuist \\
                        --destination 'platform=macOS' --test-target VotingTests --test-target VotingSwiftTests \\
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
