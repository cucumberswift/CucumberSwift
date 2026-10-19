//
//  TestBundleFilesTests.swift
//  CucumberSwiftTests
//
//  Where both runners find a test bundle's feature files, name them in the report, and copy the report
//  (Reporter/Core/TestBundleFiles.swift, which CucumberSwiftTesting shares) (#463).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class TestBundleFilesTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("TestBundleFilesTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { [folder] in folder.map { try? FileManager.default.removeItem(at: $0) } }
    }

    /// A test bundle, `Tests.bundle`, with a feature file at each of `features`, a path in its Features folder.
    /// Not `.xctest`, which tests that look for their own test bundle among `Bundle.allBundles` would find.
    private func makeTestBundle(with features: [String]) throws -> URL {
        let bundleURL = folder.appendingPathComponent("Tests.bundle")
        for path in features {
            let url = bundleURL.appendingPathComponent("Features").appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "Feature: Checkout\n".write(to: url, atomically: true, encoding: .utf8)
        }
        return bundleURL
    }

    /// The feature file's copy in the test bundle, matched on as much of its path as it shares; where it would
    /// be in the Features folder when the bundle has none, as a Swift package that excludes the feature files.
    func testAFeatureFilesURIIsItsCopyInTheTestBundle() throws {
        let bundleURL = try makeTestBundle(with: ["Checkout.feature", "Shop/Checkout.feature", "Shop/Basket.feature"])
        let featuresFolder = TestBundleFiles.featuresFolder(in: try XCTUnwrap(Bundle(url: bundleURL)))
        let files = TestBundleFiles.featureFiles(at: featuresFolder)
        // A feature file in the source tree, at a path relative to its project's Tests folder. Compared as paths
        // with symbolic links resolved: the files' URLs name the temporary folder as /private/var.
        let tests = folder.appendingPathComponent("MyApp").appendingPathComponent("Tests")
        func uri(_ path: String) -> String {
            let source = tests.appendingPathComponent(path).path
            return TestBundleFiles.bundledFeatureFile(forSourcePath: source, in: featuresFolder, files: files).resolvingSymlinksInPath().path
        }
        func inFeatures(_ path: String) -> String { featuresFolder.appendingPathComponent(path).resolvingSymlinksInPath().path }

        XCTAssertEqual(files.map(\.lastPathComponent), ["Checkout.feature", "Basket.feature", "Checkout.feature"])
        XCTAssertEqual(uri("Features/Checkout.feature"), inFeatures("Checkout.feature"))
        XCTAssertEqual(uri("Features/Shop/Checkout.feature"), inFeatures("Shop/Checkout.feature"))
        XCTAssertEqual(uri("Specs/Shop/Basket.feature"), inFeatures("Shop/Basket.feature"))
        XCTAssertEqual(uri("Features/Shop/Pay.feature"), inFeatures("Shop/Pay.feature"))
        XCTAssertEqual(uri("Specs/Pay.feature"), inFeatures("Pay.feature"))
        XCTAssertEqual(TestBundleFiles.resultsFileName(forBundleAt: bundleURL), "CucumberTestResultsForTests.json")
    }

    /// `FeaturesPath` in the test bundle's Info.plist names its folder of feature files, relative to the bundle.
    func testFeaturesPathNamesTheFeaturesFolder() throws {
        let bundleURL = try makeTestBundle(with: ["Checkout.feature"])
        let bundle = try XCTUnwrap(Bundle(url: bundleURL))

        XCTAssertEqual(TestBundleFiles.featuresFolder(in: bundle, featuresPath: "specs/features"),
                       bundle.bundleURL.appendingPathComponent("specs/features"))
    }

    /// The copy of the report that testBundleDidFinish makes replaces the one an earlier run left (#463).
    func testTheCopyOfTheReportReplacesAnEarlierOne() throws {
        let report = folder.appendingPathComponent("report.json")
        let copy = folder.appendingPathComponent("CucumberTestResultsForTests.json")
        try Data("[{}]".utf8).write(to: report)
        try Data("[]".utf8).write(to: copy)

        TestBundleFiles.copyReport(at: report, forBundleAt: folder.appendingPathComponent("Tests.xctest"), into: folder)

        XCTAssertEqual(try Data(contentsOf: copy), Data("[{}]".utf8))
    }

    /// A report written where the copy goes, as when `reportPath` names it, stays.
    func testAReportThatIsAlreadyTheCopyStays() throws {
        let copy = folder.appendingPathComponent("CucumberTestResultsForTests.json")
        try Data("[{}]".utf8).write(to: copy)

        TestBundleFiles.copyReport(at: copy, forBundleAt: folder.appendingPathComponent("Tests.xctest"), into: folder)

        XCTAssertEqual(try Data(contentsOf: copy), Data("[{}]".utf8))
    }

    /// Without a report, an earlier run's copy stays rather than leaving nothing.
    func testAnEarlierCopyStaysWhenThereIsNoReport() throws {
        let copy = folder.appendingPathComponent("CucumberTestResultsForTests.json")
        try Data("[]".utf8).write(to: copy)

        TestBundleFiles.copyReport(at: folder.appendingPathComponent("missing.json"), forBundleAt: folder.appendingPathComponent("Tests.xctest"), into: folder)

        XCTAssertEqual(try Data(contentsOf: copy), Data("[]".utf8))
    }
}
