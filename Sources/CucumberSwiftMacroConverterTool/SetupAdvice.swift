//
//  SetupAdvice.swift
//  CucumberSwiftMacroConverterTool
//

import Foundation

/// What to tell a user whose project can't run the command yet: the exact change for the setup the project
/// has, or all of them when it can't tell. The command changes nothing until the project is set up.
enum SetupAdvice {
    /// The ways a project builds with CucumberSwift.
    enum Setup: CaseIterable {
        case swiftPackage
        case xcodeProject
        case tuist
    }

    /// The oldest swift-tools-version that can turn a package trait on.
    private static let traitsToolsVersion = (major: 6, minor: 1)

    /// The files that tell the setup, in the nearest folder at or above `root` that has any of them.
    private static let searchDepth = 8

    /// The setups the project at `root` is: one, when its folder has only that setup's files, or none.
    static func detect(root: String?, fileManager: FileManager = .default) -> [Setup] {
        guard let root else { return [] }
        var folder = URL(fileURLWithPath: root)
        for _ in 0..<searchDepth {
            let names = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
            var found = [Setup]()
            if names.contains("Project.swift") { found.append(.tuist) }
            if names.contains("Package.swift") { found.append(.swiftPackage) }
            if names.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }), !found.contains(.tuist) {
                found.append(.xcodeProject)
            }
            if !found.isEmpty { return found }
            let parent = folder.deletingLastPathComponent()
            if parent == folder { break }
            folder = parent
        }
        return []
    }

    /// The package manifest's swift-tools-version, and whether it already mentions the trait.
    private static func manifest(root: String?) -> (tools: (Int, Int)?, mentionsTrait: Bool)? {
        guard let root else { return nil }
        var folder = URL(fileURLWithPath: root)
        for _ in 0..<searchDepth {
            let manifest = folder.appendingPathComponent("Package.swift")
            if let text = try? String(contentsOf: manifest, encoding: .utf8) {
                let firstLine = text.components(separatedBy: "\n").first ?? ""
                let version = firstLine.split(separator: ":").last.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
                let parts = version.split(separator: ".").compactMap { Int($0) }
                let tools = parts.count >= 2 ? (parts[0], parts[1]) : parts.first.map { ($0, 0) }
                return (tools, text.contains("\"Macros\""))
            }
            let parent = folder.deletingLastPathComponent()
            if parent == folder { break }
            folder = parent
        }
        return nil
    }

    /// What the command says when CucumberSwift's Macros trait is off, so the tool can't read Swift code.
    static func traitOffMessage(root: String?) -> String {
        let setups = detect(root: root)
        let known = setups.count == 1 ? setups : Setup.allCases
        var lines = ["Convert to Gherkin Macros needs CucumberSwift's Macros package trait, which brings in swift-syntax, and changed nothing."]
        if setups.count != 1 {
            lines.append("It can't tell how this project builds with CucumberSwift, so here is the change for each way:")
        }
        for setup in known {
            lines.append("")
            lines += traitOffSteps(for: setup, root: root)
        }
        lines += ["", "Then run the command again. \"Checking Step Definitions When They Compile\" in the documentation has the details.", ""]
        return lines.joined(separator: "\n")
    }

    private static func traitOffSteps(for setup: Setup, root: String?) -> [String] {
        switch setup {
            case .swiftPackage:
                var lines = [
                    "In a Swift package, in Package.swift, turn the trait on for the CucumberSwift dependency:",
                    "    .package(url: \"https://github.com/cucumberswift/CucumberSwift.git\", from: \"6.4.0\", traits: [\"Macros\"])"
                ]
                if let manifest = manifest(root: root) {
                    if let tools = manifest.tools, tools < traitsToolsVersion {
                        lines.append("Its swift-tools-version is \(tools.0).\(tools.1), and traits need 6.1 or later: raise it to `// swift-tools-version:6.1`.")
                    }
                    if manifest.mentionsTrait {
                        lines.append("Package.swift already mentions \"Macros\": check that it is on the CucumberSwift dependency, and run `swift package resolve`.")
                    }
                }
                lines.append("Your test target also needs the macros product: `.product(name: \"CucumberSwiftMacros\", package: \"CucumberSwift\")`.")
                return lines
            case .xcodeProject:
                return [
                    "In an Xcode project, with Xcode 26.4 or later: in the CucumberSwift package dependency's settings, turn on the Macros trait,",
                    "and add the CucumberSwiftMacros product to your test target.",
                    "With an earlier Xcode, a project can't turn a trait on: add the local MacrosTrait package that "
                        + "\"Use the macros in an Xcode project before Xcode 26.4\" describes."
                ]
            case .tuist:
                return [
                    "In a Tuist project, in Project.swift, turn the trait on where the project lists its packages, and depend on the macros product:",
                    "    .package(url: \"https://github.com/cucumberswift/CucumberSwift\", from: \"6.4.0\", traits: [\"Macros\"])",
                    "    .package(product: \"CucumberSwiftMacros\")    // in your test target's dependencies",
                    "Tuist writes the trait into the Xcode project it generates, so that needs Xcode 26.4 or later."
                ]
        }
    }

    /// What the command says when a target uses CucumberSwift but doesn't depend on the macros product, so
    /// the step definitions it converted wouldn't compile.
    static func missingProductsMessage(_ gaps: [(target: String, product: String)], root: String?) -> String {
        let setups = detect(root: root)
        let known = setups.count == 1 ? setups : Setup.allCases
        var lines = ["Convert to Gherkin Macros changed nothing: a target doesn't depend on the product that the converted step definitions need."]
        lines += gaps.map { "    \($0.target) depends on the CucumberSwift runner, but not on \($0.product)" }
        if setups.count != 1 {
            lines.append("It can't tell how this project builds with CucumberSwift, so here is the change for each way:")
        }
        for setup in known {
            let product = gaps.first?.product ?? "CucumberSwiftMacros"
            switch setup {
                case .swiftPackage:
                    lines.append("In Package.swift, add `.product(name: \"\(product)\", package: \"CucumberSwift\")` to the target's dependencies.")
                case .xcodeProject:
                    lines.append("In Xcode, add \(product) to the target's \"Frameworks, Libraries, and Embedded Content\", from the CucumberSwift package.")
                case .tuist:
                    lines.append("In Project.swift, add `.package(product: \"\(product)\")` to the target's dependencies.")
            }
        }
        lines += ["Then run the command again.", ""]
        return lines.joined(separator: "\n")
    }
}
