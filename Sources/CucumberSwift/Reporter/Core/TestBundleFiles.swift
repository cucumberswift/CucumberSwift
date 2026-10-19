//
//  TestBundleFiles.swift
//  CucumberSwift
//
// Where a test bundle's feature files are, and where its report is copied when the bundle finishes. Both
// runners use it (CucumberSwiftTesting shares Reporter/Core through a symlink), so a feature's `uri` in the
// report and the copy's name are the same with either.

import Foundation

enum TestBundleFiles {
    /// The start of the copy's name, before the test bundle's name.
    static let resultsName = "CucumberTestResultsFor"

    /// The test bundle's folder of feature files: the `FeaturesPath` in its Info.plist, relative to the
    /// bundle, else its `Features` resource, else `Features` in the bundle.
    static func featuresFolder(in bundle: Bundle) -> URL {
        featuresFolder(in: bundle, featuresPath: bundle.infoDictionary?["FeaturesPath"] as? String)
    }

    /// The test bundle's folder of feature files, with `featuresPath`, its Info.plist's `FeaturesPath`, given.
    static func featuresFolder(in bundle: Bundle, featuresPath: String?) -> URL {
        if let relativePath = featuresPath {
            return bundle.bundleURL.appendingPathComponent(relativePath)
        } else if let featuresPath = bundle.url(forResource: "Features", withExtension: nil) {
            return featuresPath
        } else {
            return bundle.bundleURL.appendingPathComponent("Features")
        }
    }

    /// Every `.feature` file in `folder`, at any depth, in the order of their URLs.
    static func featureFiles(at folder: URL) -> [URL] {
        let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)
        var files = [URL]()
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "feature" {
                files.append(url)
            }
        }
        return files.sorted { $0.absoluteString < $1.absoluteString }
    }

    /// The copy in the test bundle of the feature file at `sourcePath`, among `files` in `folder`: the one
    /// whose path ends with most of `sourcePath`, at least its name. Where it would be when the bundle has
    /// none, as with a Swift package that leaves the feature files out of its resources: its path after its
    /// last `Features` folder, else its name, in `folder`.
    static func bundledFeatureFile(forSourcePath sourcePath: String, in folder: URL, files: [URL]) -> URL {
        let source = Array(URL(fileURLWithPath: sourcePath).standardizedFileURL.pathComponents.reversed())
        func matchingComponents(_ file: URL) -> Int {
            zip(source, file.standardizedFileURL.pathComponents.reversed()).prefix { $0 == $1 }.count
        }
        if let best = files.max(by: { matchingComponents($0) < matchingComponents($1) }), matchingComponents(best) > 0 {
            return best
        }
        let components = Array(source.reversed())
        let relative = components.lastIndex(of: "Features").map { components[($0 + 1)...] } ?? components.suffix(1)
        return relative.reduce(folder) { $0.appendingPathComponent($1) }
    }

    /// The copy's name for a test bundle: `CucumberTestResultsFor<bundle name>.json`, the bundle's name up
    /// to its first `.`.
    static func resultsFileName(forBundleAt bundleURL: URL, prefix: String = resultsName) -> String {
        prefix + String(bundleURL.lastPathComponent.prefix { $0 != "." }) + ".json"
    }

    /// Copies the report to `CucumberTestResultsFor<bundle name>.json` in `folder`, the documents folder
    /// unless given, when the test bundle finishes. The copy replaces the one an earlier run left.
    static func copyReport(at reportURL: URL?, forBundleAt bundleURL: URL, prefix: String = resultsName, into folder: URL? = nil) {
        guard let reportURL,
              let folder = folder ?? (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
        else { return }
        let fileURL = folder.appendingPathComponent(resultsFileName(forBundleAt: bundleURL, prefix: prefix))
        // copyItem doesn't overwrite, so without this the first run's copy would stay.
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.copyItem(at: reportURL, to: fileURL)
    }
}
