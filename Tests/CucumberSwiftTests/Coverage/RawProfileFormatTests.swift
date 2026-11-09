//
//  RawProfileFormatTests.swift
//  CucumberSwiftTests
//
//  CucumberSwift writes each scenario's profile in the raw profile version of the binary it measures:
//  version 8 for Xcode 16.0 to 16.2, and version 10 for Xcode 16.3 and later (#552). The layout tests build
//  the sections by hand, so they run without a coverage build. The merge test needs this bundle built with
//  code coverage, and macOS, and is skipped otherwise.
//

import Foundation
import XCTest
@testable import CucumberSwift

final class RawProfileFormatTests: XCTestCase {
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("RawProfileFormatTests-\(UUID().uuidString)")
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    private func counts(_ values: [UInt64]) -> [UInt8] {
        values.withUnsafeBytes { Array($0) }
    }

    /// A copy of `bytes` in memory that outlives the call, as a binary's sections do.
    private func section(_ bytes: [UInt8]) -> UnsafeRawBufferPointer {
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: max(bytes.count, 1), alignment: 8)
        buffer.copyBytes(from: bytes)
        addTeardownBlock { buffer.deallocate() }
        return UnsafeRawBufferPointer(rebasing: buffer[..<bytes.count])
    }

    /// The raw profile that `format` writes for 2 data records of 0xAA bytes, 3 counters, a bitmap and names,
    /// with flags in its version.
    private func profile(_ format: RawProfileFormat, bitmap: [UInt8], names: [UInt8]) -> Data {
        format.rawProfile(
            version: format.version | (1 << 56),
            data: section([UInt8](repeating: 0xAA, count: 2 * format.recordSize)),
            countersSection: section([UInt8](repeating: 0, count: 24)),
            counters: counts([3, 0, 1]),
            bitmap: section(bitmap),
            names: section(names)
        )
    }

    func testEachSupportedVersionHasItsFormatWhateverItsFlags() {
        XCTAssertEqual(RawProfileFormat.all.map(\.version), [8, 10])
        XCTAssertEqual(RawProfileFormat(version: 8 | (1 << 56)), .version8)
        XCTAssertEqual(RawProfileFormat(version: 10), .version10)
        XCTAssertNil(RawProfileFormat(version: 9))
        XCTAssertNil(RawProfileFormat(version: 11))
    }

    // A profile has its binary's version's layout, as LLVM's InstrProfData.inc gives it: the header's words,
    // the data records with their counts of value sites set to 0, the counters, the bitmap from version 9 on,
    // and the names, each padded to 8 bytes. Nil stands for a word that is an address.
    func testAProfileHasTheLayoutOfItsBinarysVersion() throws {
        let flags: UInt64 = 1 << 56
        let cases: [(RawProfileFormat, [UInt64?])] = [
            (.version8, [0xFF6C_7072_6F66_7281, 8 | flags, 0, 2, 0, 3, 0, 5, nil, nil, 1]),
            (.version10, [0xFF6C_7072_6F66_7281, 10 | flags, 0, 2, 0, 3, 0, 3, 5, 5, nil, nil, nil, 0, 0, 2])
        ]
        let bitmap: [UInt8] = [1, 2, 3]
        let names: [UInt8] = [4, 5, 6, 7, 8]
        for (format, expectedHeader) in cases {
            let profile = profile(format, bitmap: bitmap, names: names)
            let headerSize = expectedHeader.count * 8
            let header = profile.prefix(headerSize).withUnsafeBytes { Array($0.bindMemory(to: UInt64.self)) }
            for (word, expected) in zip(header, expectedHeader) where expected != nil {
                XCTAssertEqual(word, expected, "version \(format.version)")
            }
            var body = [UInt8](profile.dropFirst(headerSize))
            for record in 0..<2 {
                let bytes = body[(record * format.recordSize)..<((record + 1) * format.recordSize)]
                for (offset, byte) in bytes.enumerated() {
                    XCTAssertEqual(byte, format.valueSites.contains(offset) ? 0 : 0xAA, "version \(format.version), byte \(offset)")
                }
            }
            body.removeFirst(2 * format.recordSize)
            var rest = counts([3, 0, 1])
            if format.hasBitmap { rest += bitmap + [0, 0, 0, 0, 0] }
            rest += names + [0, 0, 0]
            XCTAssertEqual(body, rest, "version \(format.version)")
        }
    }

    // The article tells you to merge a scenario's files with the `llvm-profdata` of the Xcode that built the
    // tests, which reads only its own version of the raw profile. So a profile must merge with it, with each
    // Xcode.
    func testAProfileMergesWithTheLLVMProfdataOfTheXcodeThatBuiltTheTests() throws {
        #if os(macOS)
        let counters = ProfileCounters.loaded()
        try XCTSkipIf(counters.binaries.isEmpty, "This bundle wasn't built with code coverage.")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in try counters.writeProfiles(named: "merge", in: folder, since: counters.snapshot()) {
            let process = Process()
            process.executableURL = ["usr", "bin", "xcrun"].reduce(URL(fileURLWithPath: "/")) { $0.appendingPathComponent($1) }
            process.arguments = [
                "llvm-profdata",
                "merge",
                "-o",
                folder.appendingPathComponent("\(file).profdata").path,
                folder.appendingPathComponent(file).path
            ]
            let errors = Pipe()
            process.standardError = errors
            try process.run()
            let message = String(bytes: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0, "\(file): \(message)")
        }
        #else
        throw XCTSkip("Only macOS can run llvm-profdata from a test.")
        #endif
    }
}
