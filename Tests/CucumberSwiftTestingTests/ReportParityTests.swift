@testable import CucumberSwiftTesting
import Foundation
import JSONSchema
import Testing

// CucumberSwift and CucumberSwiftTesting write one Cucumber JSON report for the same feature files (#420),
// with the same `uri`, the feature file's URL in the test bundle, and copy it to the same file when the
// tests finish (#463). CucumberSwift's side is CucumberSwiftTests/Reporter/ReportParityTests.swift: both
// compare their report with ParityReport.json.
extension CucumberTests {
    /// The report's text with each duration replaced by 0, and the folder that holds the test bundle left
    /// out of each `uri`, which differ from one run to the next. CucumberSwift's ReportParityTests does the same.
    func withoutDurations(_ data: Data) throws -> String {
        let text = try #require(String(data: data, encoding: .utf8))
        return text.replacingOccurrences(of: #""duration" : [0-9.e+-]+"#, with: #""duration" : 0"#, options: .regularExpression)
            .replacingOccurrences(of: #""uri" : "file:[^"]*?\\/Tests\.bundle\\/"#, with: #""uri" : "file:\\/\\/\\/Tests.bundle\\/"#, options: .regularExpression)
    }

    /// A test bundle, `Tests.bundle`, in a folder of its own, with a feature file at each of `features`, a
    /// path in its Features folder. Not `.xctest`, which tests that look for their own test bundle among
    /// `Bundle.allBundles` would find instead.
    func testBundle(with features: [String] = []) throws -> URL {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CucumberSwiftTestingBundles-\(UUID().uuidString)")
            .appendingPathComponent("Tests.bundle")
        let folder = bundleURL.appendingPathComponent("Features")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for path in features {
            let url = folder.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "Feature: Checkout\n".write(to: url, atomically: true, encoding: .utf8)
        }
        return bundleURL
    }

    private func directoryOfCucumberSwiftTests(file: String = #filePath) -> URL {
        URL(fileURLWithPath: file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CucumberSwiftTests/Reporter")
    }

    @Test func theReportIsTheOneCucumberSwiftWritesForTheSameFeatureFile() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        let reporter = try #require(CucumberJSONReporter())
        Cucumber.shared.reporters = [reporter]
        registerParityStepDefinitions()

        // The feature file's copy in the test bundle is what the report names, as with CucumberSwift.
        let bundleURL = try testBundle(with: ["Checkout.feature"])
        defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }
        Cucumber.shared.resultsFolder = url.deletingLastPathComponent()

        // In an order of their own: Swift Testing doesn't promise the order of the tests in a suite.
        let scenarios = parityScenarios()
        Cucumber.shared.beginSuite(testBundleURL: bundleURL)
        for scenario in [scenarios[2], scenarios[0], scenarios[1]] {
            await Cucumber.shared.run(scenario)
        }
        await Cucumber.shared.endFeature(file: "/Features/Checkout.feature", title: "Checkout", line: 1)
        await Cucumber.shared.endSuite()

        let written = try Data(contentsOf: url)
        let expected = try Data(contentsOf: directoryOfCucumberSwiftTests().appendingPathComponent("ParityReport.json"))
        #expect(try withoutDurations(written) == withoutDurations(expected))

        let schemaData = try Data(contentsOf: directoryOfCucumberSwiftTests().appendingPathComponent("Schema.json"))
        let schema = try #require(JSONSerialization.jsonObject(with: schemaData) as? [String: Any])
        let result = try JSONSchema.validate(JSONSerialization.jsonObject(with: written), schema: schema)
        #expect(result.errors?.count ?? 0 == 0, "\(String(describing: result.errors))")
    }

    /// As CucumberSwift copies the report when the test bundle finishes, to `CucumberTestResultsFor<bundle>.json`
    /// in the documents folder.
    @Test func theReportIsCopiedAfterTheSuiteNamedAfterTheTestBundle() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let bundleURL = try testBundle()
        defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }
        let documents = bundleURL.deletingLastPathComponent()
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        Cucumber.shared.resultsFolder = documents
        registerParityStepDefinitions()
        let copy = documents.appendingPathComponent("CucumberTestResultsForTests.json")

        Cucumber.shared.beginSuite(testBundleURL: bundleURL)
        await Cucumber.shared.run(parityScenarios()[0])
        #expect(!FileManager.default.fileExists(atPath: copy.path))
        await Cucumber.shared.endSuite()

        #expect(try Data(contentsOf: copy) == Data(contentsOf: url))
    }

    @Test func withoutATestBundleTheReportIsNotCopiedAndNamesTheFeatureFilesPath() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        Cucumber.shared.resultsFolder = url.deletingLastPathComponent()
        registerParityStepDefinitions()

        Cucumber.shared.beginSuite()
        await Cucumber.shared.run(parityScenarios()[0])
        await Cucumber.shared.endSuite()

        #expect(try readReport(url).first?["uri"] as? String == "file:///Features/Checkout.feature")
        #expect(try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path) == ["report.json"])
    }

    /// The feature file's copy in the test bundle, matched on as much of its path as it shares; where it would
    /// be in the Features folder when the bundle has none, as a Swift package that excludes the feature files.
    @Test func aFeatureFilesURIIsItsCopyInTheTestBundle() throws {
        let bundleURL = try testBundle(with: ["Checkout.feature", "Shop/Checkout.feature", "Shop/Basket.feature"])
        defer { try? FileManager.default.removeItem(at: bundleURL.deletingLastPathComponent()) }
        let bundle = try #require(Bundle(url: bundleURL))
        let folder = TestBundleFiles.featuresFolder(in: bundle)
        let files = TestBundleFiles.featureFiles(at: folder)
        // As paths with symbolic links resolved: the files' URLs name the temporary folder as /private/var.
        func uri(_ path: String) -> String {
            TestBundleFiles.bundledFeatureFile(forSourcePath: path, in: folder, files: files).resolvingSymlinksInPath().path
        }
        func inFeatures(_ path: String) -> String { folder.appendingPathComponent(path).resolvingSymlinksInPath().path }

        #expect(files.map(\.lastPathComponent) == ["Checkout.feature", "Basket.feature", "Checkout.feature"])
        #expect(uri("/Users/me/MyApp/Tests/Features/Checkout.feature") == inFeatures("Checkout.feature"))
        #expect(uri("/Users/me/MyApp/Tests/Features/Shop/Checkout.feature") == inFeatures("Shop/Checkout.feature"))
        #expect(uri("/Users/me/MyApp/Tests/Specs/Shop/Basket.feature") == inFeatures("Shop/Basket.feature"))
        #expect(uri("/Users/me/MyApp/Tests/Features/Shop/Pay.feature") == inFeatures("Shop/Pay.feature"))
        #expect(uri("/Users/me/MyApp/Tests/Specs/Pay.feature") == inFeatures("Pay.feature"))
        #expect(TestBundleFiles.resultsFileName(forBundleAt: bundleURL) == "CucumberTestResultsForTests.json")
    }
}
