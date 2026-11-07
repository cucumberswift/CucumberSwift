//
//  FeatureSourceFilesTests.swift
//  CucumberSwiftTests
//
//  The XCTest runner reports issues at the project's feature file, not its copy in the test bundle, as the
//  Swift Testing runner does (#535).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class FeatureSourceFilesTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("FeatureSourceFilesTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { [folder] in folder.map { try? FileManager.default.removeItem(at: $0) } }
    }

    /// Writes a file at `path` in the temporary folder, making its folders, and returns its URL.
    @discardableResult
    private func write(_ path: String, _ contents: String = "Feature: Checkout\n") throws -> URL {
        let url = folder.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// The copies in a test bundle's Features folder at `path`, as the runner reads them.
    private func copies(inBundleAt path: String, _ features: [String]) throws -> (folder: URL, copies: [URL]) {
        for feature in features {
            try write("\(path)/Features/\(feature)")
        }
        let featuresFolder = folder.appendingPathComponent(path).appendingPathComponent("Features")
        return (featuresFolder, TestBundleFiles.featureFiles(at: featuresFolder))
    }

    private func projectFile(of copy: URL, in projectFiles: [String: URL]) -> String? {
        projectFiles[copy.standardizedFileURL.path]?.resolvingSymlinksInPath().path
    }

    private func path(_ path: String) -> String {
        folder.appendingPathComponent(path).resolvingSymlinksInPath().path
    }

    /// With the CucumberSwiftLint plugin, each copy's project file is the recorded path whose copy it is.
    func testEachCopyIsPairedWithItsRecordedPath() throws {
        let bundle = try copies(inBundleAt: "Build/Tests.xctest", ["Checkout.feature", "Shop/Checkout.feature"])
        let recorded = ["App/Tests/Features/Checkout.feature", "App/Tests/Features/Shop/Checkout.feature"].map(path)

        let projectFiles = FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: recorded, stepDefinitionFiles: [])

        XCTAssertEqual(bundle.copies.map { projectFile(of: $0, in: projectFiles) }, recorded)
    }

    /// The recorded paths are the only target's, else those of the target the test bundle is named after.
    func testTheRecordedPathsAreTheTestBundlesTargets() {
        let shop = FeatureSourceFiles.RecordedPaths(target: "ShopTests", paths: ["/App/Shop.feature"])
        let other = FeatureSourceFiles.RecordedPaths(target: "Other Tests", paths: ["/App/Other.feature"])
        func paths(_ folder: String, _ recorded: [FeatureSourceFiles.RecordedPaths]) -> [String]? {
            FeatureSourceFiles.recordedPaths(for: URL(fileURLWithPath: folder), among: recorded)
        }

        XCTAssertEqual(paths("/Build/Any.xctest/Features", [shop]), ["/App/Shop.feature"])
        XCTAssertEqual(paths("/Build/App_ShopTests.bundle/Features", [shop, other]), ["/App/Shop.feature"])
        XCTAssertEqual(paths("/Build/Other Tests.xctest/Contents/Resources/Features", [shop, other]), ["/App/Other.feature"])
        XCTAssertNil(paths("/Build/Any.xctest/Features", [shop, other]))
        XCTAssertNil(paths("/Build/Any.xctest/Features", []))
    }

    /// A copy that two recorded paths pair with equally keeps the copy.
    func testACopyWithTwoRecordedPathsKeepsTheCopy() throws {
        let bundle = try copies(inBundleAt: "Build/Tests.xctest", ["Checkout.feature"])
        let recorded = ["App/Checkout.feature", "Other/Checkout.feature"].map(path)

        let projectFiles = FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: recorded, stepDefinitionFiles: [])

        XCTAssertEqual(projectFiles, [:])
    }

    /// Without the plugin, the project's file is the one whose path ends with the copy's path in the Features
    /// folder, in the nearest folder above a step definition that has one. Copies in build products don't count.
    func testWithoutThePluginTheNearestFeatureFileAboveTheStepDefinitionsIsFound() throws {
        try write("App/Package.swift", "// swift-tools-version:6.0\n")
        let steps = try write("App/Tests/ShopTests/StepDefinitions.swift", "")
        try write("App/Tests/ShopTests/Features/Shop/Checkout.feature")
        try write("App/Tests/OtherTests/Features/Shop/Checkout.feature")
        try write("App/Derived/Build/Other.xctest/Features/Shop/Checkout.feature")
        try write("App/.build/Other.bundle/Features/Shop/Checkout.feature")
        let bundle = try copies(inBundleAt: "App/Derived/Build/ShopTests.xctest", ["Shop/Checkout.feature"])

        let projectFiles = FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: nil, stepDefinitionFiles: [steps.path])

        XCTAssertEqual(bundle.copies.map { projectFile(of: $0, in: projectFiles) }, [path("App/Tests/ShopTests/Features/Shop/Checkout.feature")])
    }

    /// Without the plugin, a copy keeps itself when the nearest folder with a match has two, or there's none.
    func testWithoutThePluginACopyWithoutExactlyOneMatchKeepsTheCopy() throws {
        try write("App/App.xcodeproj/project.pbxproj", "")
        let steps = try write("App/Tests/Shared/StepDefinitions.swift", "")
        try write("App/Tests/ShopTests/Features/Checkout.feature")
        try write("App/Tests/OtherTests/Features/Checkout.feature")
        let bundle = try copies(inBundleAt: "Build/ShopTests.xctest", ["Checkout.feature", "Basket.feature"])

        let projectFiles = FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: nil, stepDefinitionFiles: [steps.path])

        XCTAssertEqual(projectFiles, [:])
    }

    /// Without the plugin, nothing is searched above a step definition that is in no project, or without any
    /// step definitions.
    func testWithoutAProjectOrStepDefinitionsEachCopyKeepsTheCopy() throws {
        let steps = try write("Loose/StepDefinitions.swift", "")
        try write("Loose/Features/Checkout.feature")
        let bundle = try copies(inBundleAt: "Build/Tests.xctest", ["Checkout.feature"])

        XCTAssertEqual(FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: nil, stepDefinitionFiles: [steps.path]), [:])
        XCTAssertEqual(FeatureSourceFiles.find(copies: bundle.copies, in: bundle.folder, recordedPaths: nil, stepDefinitionFiles: []), [:])
    }

    /// An issue about a feature file whose project file isn't known stays at the file it names.
    func testAnIssueAboutAnUnknownFeatureFileStaysThere() throws {
        let url = folder.appendingPathComponent("Elsewhere.feature")
        XCTAssertEqual(FeatureSourceFiles.issueFile(for: url), url)
        let web = try XCTUnwrap(URL(string: "https://example.com/Checkout.feature"))
        XCTAssertEqual(FeatureSourceFiles.issueFile(for: web), web)
    }
}
