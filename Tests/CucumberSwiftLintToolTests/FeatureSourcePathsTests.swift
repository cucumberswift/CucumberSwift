@testable import CucumberSwiftLintTool
import XCTest

/// The Swift file with each feature file's path that the CucumberSwiftLint plugin adds to the target, for
/// CucumberSwift's XCTest runner to report issues at (#535).
final class FeatureSourcePathsTests: XCTestCase {
    func testFeaturePathsNamesTheSwiftFile() {
        let arguments = Arguments([
            "--stamp", "lint-stamp", "--target", "ShopTests", "--feature-paths", "Paths.swift", "--features", "a.feature",
            "--step-definitions", "Steps.swift"
        ])
        XCTAssertEqual(arguments.target, "ShopTests")
        XCTAssertEqual(arguments.featurePaths, "Paths.swift")
        XCTAssertEqual(arguments.features, ["a.feature"])
        XCTAssertEqual(arguments.swiftFiles, ["Steps.swift"])
        XCTAssertNil(Arguments(["--features", "a.feature"]).featurePaths)
    }

    func testTheSwiftFileHasAClassForTheTargetWithEachPath() {
        let source = FeatureSourcePaths.source(target: "ShopTests",
                                               features: ["/App/Tests/Features/Checkout.feature", "/App/Tests/Features/Basket.feature"])
        XCTAssertTrue(source.contains("""
        @objc(CucumberSwiftFeatureSourcePaths_ShopTests)
        final class CucumberSwiftFeatureSourcePaths_ShopTests: NSObject {
            @objc static let target = "ShopTests"
            @objc static let paths: [String] = [
                "/App/Tests/Features/Checkout.feature",
                "/App/Tests/Features/Basket.feature",
            ]
        }
        """), source)
    }

    /// Each target's class has a name of its own, which is a Swift identifier.
    func testTheClassIsNamedAfterTheTarget() {
        XCTAssertEqual(FeatureSourcePaths.className(target: "ShopTests"), "CucumberSwiftFeatureSourcePaths_ShopTests")
        XCTAssertEqual(FeatureSourcePaths.className(target: "Shop UI-Tests é"), "CucumberSwiftFeatureSourcePaths_Shop_UI_Tests__")
    }

    func testAPathIsEscapedAsASwiftStringLiteral() {
        XCTAssertEqual(FeatureSourcePaths.literal(#"/a "quoted" \ path/é.feature"#), #""/a \"quoted\" \\ path/é.feature""#)
        XCTAssertEqual(FeatureSourcePaths.literal("/a\nb\tc\u{1}.feature"), #""/a\nb\tc\u{1}.feature""#)
    }

    func testWriteWritesTheSwiftFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FeatureSourcePathsTests-\(UUID().uuidString).swift")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        try FeatureSourcePaths.write(target: "ShopTests", features: ["/App/Checkout.feature"], to: url.path)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8),
                       FeatureSourcePaths.source(target: "ShopTests", features: ["/App/Checkout.feature"]))
    }
}
