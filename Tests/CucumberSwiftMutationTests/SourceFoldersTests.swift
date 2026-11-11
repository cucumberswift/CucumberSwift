//
//  SourceFoldersTests.swift
//  CucumberSwiftMutationTests
//
//  The command-line tool finds the folders to mutate itself, from `swift package describe`.
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class SourceFoldersTests: XCTestCase {
    /// What `swift package describe --type json` prints for a package with a library, an executable, a test target
    /// and a plugin, after a warning, as SwiftPM prints one for an unused dependency.
    private let packageJSON = Data("""
    warning: 'shop': dependency 'swift-syntax' is not used by any target
    {"name": "Shop", "targets": [
      {"name": "Shop", "type": "library", "path": "Sources/Shop"},
      {"name": "ShopTool", "type": "executable", "path": "Sources/ShopTool"},
      {"name": "ShopTests", "type": "test", "path": "Tests/ShopTests"},
      {"name": "ShopPlugin", "type": "plugin", "path": "Plugins/ShopPlugin"}
    ]}
    """.utf8)

    func testEveryTargetWithCodeWithoutNames() throws {
        XCTAssertEqual(try SourceFolders.folders(describedBy: packageJSON, named: []), ["Sources/Shop", "Sources/ShopTool"])
    }

    func testOnlyTheNamedTargetsAndNeverATestTarget() throws {
        // Xcode names every target, test targets included.
        XCTAssertEqual(try SourceFolders.folders(describedBy: packageJSON, named: ["Shop", "ShopTests"]), ["Sources/Shop"])
    }

    func testAnUnknownNameOrOnlyTestTargetsIsAnError() {
        XCTAssertThrowsError(try SourceFolders.folders(describedBy: packageJSON, named: ["Nope"])) {
            XCTAssertEqual("\($0)", "No target named Nope")
        }
        XCTAssertThrowsError(try SourceFolders.folders(describedBy: packageJSON, named: ["ShopTests"])) {
            XCTAssertEqual("\($0)", "The package has no target with code to mutate")
        }
        XCTAssertThrowsError(try SourceFolders.folders(describedBy: Data("not json".utf8), named: []))
    }

    func testAFailedDescribeIsAnError() {
        let failing = FakeRunner { _ in .finished(1, output: "error: no Package.swift") }
        XCTAssertThrowsError(try SourceFolders.find(in: URL(fileURLWithPath: "/tmp"), named: [], swift: "swift", runner: failing))
    }

    func testFindRunsSwiftPackageDescribeInThePackage() throws {
        let json = String(bytes: packageJSON, encoding: .utf8) ?? ""
        let runner = FakeRunner { _ in .finished(0, output: json) }
        XCTAssertEqual(try SourceFolders.find(in: URL(fileURLWithPath: "/tmp/shop"), named: ["Shop"], swift: "/usr/bin/swift", runner: runner),
                       ["Sources/Shop"])
        XCTAssertEqual(runner.calls.first?.arguments, ["package", "describe", "--type", "json"])
        XCTAssertEqual(runner.calls.first?.directory.path, "/tmp/shop")
    }
}
#endif
