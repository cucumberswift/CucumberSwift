//
//  TestBundle.swift
//  CucumberSwiftTesting
//
// The test bundle the generated tests are in. CucumberSwift reads its feature files from the test bundle and
// names them after their copies there in the JSON report, and copies the report when the bundle finishes. This
// runner reads the feature files when the tests build, and does the rest the same way, with the same code
// (Reporter/Core/TestBundleFiles.swift).

import Foundation

/// The test bundle that `type` is compiled into. The generated tests name theirs with it, so that the
/// generated file needs no `import Foundation`. Public only so that the generated code can use it.
public func cucumberTestBundle(of type: AnyClass) -> URL {
    Bundle(for: type).bundleURL
}

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

    /// A feature file's URI, in the report and for hooks and observers, as CucumberSwift gives it: the `file://` URL of its copy in the
    /// test bundle, or of where its copy would be.
    func uri(ofFeatureFileAt path: String) -> String {
        TestBundleFiles.bundledFeatureFile(forSourcePath: path, in: featuresFolder, files: featureFiles).absoluteString
    }

    /// Copies the report to `CucumberTestResultsFor<bundle>.json` in `folder`, the documents folder unless
    /// given, as CucumberSwift does when the test bundle finishes.
    func copyReport(into folder: URL? = nil) {
        let report = CucumberSettings.reportPath.map { URL(fileURLWithPath: $0) } ?? CucumberJSONReport.defaultURL
        TestBundleFiles.copyReport(at: report, forBundleAt: url, into: folder)
    }
}

extension Cucumber {
    /// A scenario's feature, named after its feature file's copy in the scenario's test bundle, as
    /// CucumberSwift names it.
    func feature(of scenario: GherkinScenario) -> Feature {
        let bundle = testBundle(of: scenario)
        // A feature of the Swift DSL has no feature file: CucumberSwift names it by its Swift file's path.
        guard scenario.dslID == nil else { return Feature(scenario, uri: scenario.file) }
        return Feature(scenario, uri: bundle?.uri(ofFeatureFileAt: scenario.file))
    }

    /// The scenario's test bundle, read once, which is then the one whose report `endSuite()` copies.
    private func testBundle(of scenario: GherkinScenario) -> TestBundle? {
        guard let url = scenario.testBundle, let bundle = testBundles[url] ?? TestBundle(url: url) else { return nil }
        testBundles[url] = bundle
        testBundle = bundle
        return bundle
    }
}
