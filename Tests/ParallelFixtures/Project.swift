import ProjectDescription

// The fixtures CI runs with Xcode's parallel testing on, to check experimental parallel testing (#31) on every
// supported platform and for every kind of test target: unit tests without a host app, unit tests hosted in an
// app, and UI tests. They use CucumberSwift as a local Swift package, so CucumberSwift.xcodeproj, which
// Carthage builds, doesn't change. Generate with `mise run generate-fixtures`.
//
// Each platform family has its own targets: iOS (which also builds for Mac Catalyst), tvOS and macOS. Every
// test target runs the same features, in Features, so CI expects the same scenarios from each.

struct Family {
    let suffix: String
    let destinations: Destinations
    let deploymentTargets: DeploymentTargets
}

// SwiftUI's App needs iOS 14, tvOS 14 and macOS 11.
let families = [
    Family(suffix: "", destinations: [.iPhone, .iPad, .macCatalyst], deploymentTargets: .iOS("14.0")),
    Family(suffix: "TV", destinations: [.appleTv], deploymentTargets: .tvOS("14.0")),
    Family(suffix: "Mac", destinations: [.mac], deploymentTargets: .macOS("11.0"))
]

// Signed to run locally, so that the macOS app and its tests can launch without a team.
let settings: Settings = .settings(base: [
    "CODE_SIGN_IDENTITY": "-",
    "CODE_SIGN_STYLE": "Manual",
    "SWIFT_VERSION": "5.0"
])

func targets(for family: Family) -> [Target] {
    let app = "ParallelFixtureApp\(family.suffix)"
    func testTarget(_ name: String, product: Product, sources: SourceFilesList, hosted: Bool) -> Target {
        .target(
            name: name,
            destinations: family.destinations,
            product: product,
            bundleId: "org.cucumberswift.\(name)",
            deploymentTargets: family.deploymentTargets,
            infoPlist: .default,
            sources: sources,
            resources: [.folderReference(path: "Features")],
            dependencies: (hosted ? [.target(name: app)] : []) + [.package(product: "CucumberSwift")],
            settings: settings
        )
    }
    return [
        .target(
            name: app,
            destinations: family.destinations,
            product: .app,
            bundleId: "org.cucumberswift.\(app)",
            deploymentTargets: family.deploymentTargets,
            infoPlist: .extendingDefault(with: ["UILaunchScreen": .dictionary([:])]),
            sources: ["App/**"],
            settings: settings
        ),
        testTarget("ParallelHostlessTests\(family.suffix)", product: .unitTests,
                   sources: ["UnitTests/**", "Support/**"], hosted: false),
        testTarget("ParallelHostedTests\(family.suffix)", product: .unitTests,
                   sources: ["UnitTests/**", "Support/**"], hosted: true),
        testTarget("ParallelUITests\(family.suffix)", product: .uiTests,
                   sources: ["UITests/**", "Support/**"], hosted: true)
    ]
}

// One scheme for each kind of test target and platform family, such as ParallelUITestsTV, each with
// parallel testing on.
func schemes(for family: Family) -> [Scheme] {
    ["ParallelHostlessTests", "ParallelHostedTests", "ParallelUITests"].map { kind in
        let target = "\(kind)\(family.suffix)"
        return .scheme(
            name: target,
            shared: true,
            buildAction: .buildAction(targets: [.target(target)]),
            // The records folder reaches every kind of test runner through the scheme, filled from the
            // build setting of the same name: CI passes PARALLEL_TEST_RECORDS=<folder> to xcodebuild.
            testAction: .targets(
                [.testableTarget(target: .target(target), parallelization: .enabled)],
                arguments: .arguments(environmentVariables: ["PARALLEL_TEST_RECORDS": "$(PARALLEL_TEST_RECORDS)"]),
                configuration: .debug,
                expandVariableFromTarget: .target(target)
            )
        )
    }
}

let project = Project(
    name: "ParallelFixtures",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [.local(path: "../..")],
    targets: families.flatMap(targets(for:)),
    schemes: families.flatMap(schemes(for:))
)
