//
//  TestBundle.swift
//  CucumberSwiftTesting
//
// The test bundle the generated tests are in. CucumberSwift reads its feature files from the test bundle and
// names them after their copies there in the JSON report, and copies the report when the bundle finishes. This
// runner reads the feature files when the tests build, and does the rest the same way, with the same code
// (Reporter/Core/TestBundleFiles.swift).

import Foundation

struct TestBundle {
    let url: URL
    /// The bundle's folder of feature files, as CucumberSwift finds it.
    let featuresFolder: URL
    let featureFiles: [URL]

    init?(url: URL) {
        guard let bundle = Bundle(url: url) else { return nil }
        self.url = bundle.bundleURL
        featuresFolder = TestBundleFiles.featuresFolder(in: bundle)
        featureFiles = TestBundleFiles.featureFiles(at: featuresFolder)
    }

    /// A feature file's URI in the report, as CucumberSwift writes it: the `file://` URL of its copy in the
    /// test bundle, or of where its copy would be.
    func reportURI(ofFeatureFileAt path: String) -> String {
        TestBundleFiles.bundledFeatureFile(forSourcePath: path, in: featuresFolder, files: featureFiles).absoluteString
    }

    /// Copies the report to `CucumberTestResultsFor<bundle>.json` in `folder`, the documents folder unless
    /// given, as CucumberSwift does when the test bundle finishes.
    func copyReport(into folder: URL? = nil) {
        let report = CucumberSettings.reportPath.map { URL(fileURLWithPath: $0) } ?? CucumberJSONReport.defaultURL
        TestBundleFiles.copyReport(at: report, forBundleAt: url, into: folder)
    }
}
