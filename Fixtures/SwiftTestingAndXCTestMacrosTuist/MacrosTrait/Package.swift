// swift-tools-version:6.1
// Turns on CucumberSwift's Macros trait for the Xcode project around it, and does nothing else. Before
// Xcode 26.4, an Xcode project can't turn on a package's traits itself, but a package that it depends on
// can, in its own manifest, and SwiftPM then builds CucumberSwift with the trait for the whole project.
// The project links CucumberSwift's macro products directly, so with Xcode 26.4 or later this package
// can go, and the trait is set on CucumberSwift in the project instead. See ../README.md.

import PackageDescription

let package = Package(
    name: "MacrosTrait",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MacrosTrait", targets: ["MacrosTrait"])
    ],
    dependencies: [
        // Keep `name:`. Without it, SwiftPM names a path dependency after its folder, which is not
        // "CucumberSwift" in a worktree or a renamed clone.
        .package(name: "CucumberSwift", path: "../../..", traits: ["Macros"])
    ],
    targets: [
        // Depends on a CucumberSwift product, so that SwiftPM counts the dependency, and its trait, as used.
        .target(
            name: "MacrosTrait",
            dependencies: [.product(name: "CucumberSwiftMacros", package: "CucumberSwift")])
    ]
)
