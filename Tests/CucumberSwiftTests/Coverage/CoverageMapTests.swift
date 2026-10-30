//
//  CoverageMapTests.swift
//  CucumberSwiftTests
//
//  CucumberSwift decodes the coverage map that the compiler writes, version 7 of LLVM's format, and
//  computes each code region's count from the counters (#502). These tests build the sections by hand,
//  with every kind of region and the malformed cases, so they run without a coverage build.
//

import Compression
import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageMapTests: XCTestCase {
    /// A region as a mapping encodes it: its header, its extra counters, if any, and whether it is a gap.
    private struct Region {
        let header: UInt64
        var extra = [UInt64]()
        var isGap = false
    }

    /// Bytes as the coverage sections lay them out.
    private struct Bytes {
        var bytes = [UInt8]()

        mutating func uleb(_ value: UInt64) {
            var value = value
            repeat {
                var byte = UInt8(value & 0x7F)
                value >>= 7
                if value != 0 { byte |= 0x80 }
                bytes.append(byte)
            } while value != 0
        }

        mutating func u32(_ value: UInt32) {
            withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
        }

        mutating func u64(_ value: UInt64) {
            withUnsafeBytes(of: value.littleEndian) { bytes.append(contentsOf: $0) }
        }

        mutating func align8() {
            while bytes.count % 8 != 0 { bytes.append(0) }
        }
    }

    /// The compilation folder that the file names are relative to.
    private static let project = FileManager.default.temporaryDirectory.appendingPathComponent("project")

    /// The counters of one function, `run`: 5 and 2.
    private static let counts: [UInt64] = [5, 2]
    private static let run = NameHash.of(Array("$s4Calc3runyyF".utf8))
    private static let hash: UInt64 = 0xABCD

    /// A list of names, as `__llvm_prf_names` and the file lists store them: compressed with zlib, or not.
    private static func blob(_ names: [UInt8], compressed: Bool) -> [UInt8] {
        var blob = Bytes()
        blob.uleb(UInt64(names.count))
        guard compressed else {
            blob.uleb(0)
            return blob.bytes + names
        }
        var deflated = [UInt8](repeating: 0, count: names.count + 64)
        let size = compression_encode_buffer(&deflated, deflated.count, names, names.count, nil, COMPRESSION_ZLIB)
        // zlib's format: a 2-byte header, then raw deflate.
        let zlib = [0x78, 0x9C] + deflated.prefix(size)
        blob.uleb(UInt64(zlib.count))
        return blob.bytes + zlib
    }

    /// `__llvm_covmap`: one translation unit with its compilation folder and one file, relative to it.
    private static func covmap(version: UInt32 = 6) -> (bytes: [UInt8], filesRef: UInt64) {
        var list = Bytes()
        for name in [project.path, "Sources/Calc.swift"] {
            list.uleb(UInt64(name.utf8.count))
            list.bytes += Array(name.utf8)
        }
        var files = Bytes()
        files.uleb(2)
        files.bytes += blob(list.bytes, compressed: false)
        var covmap = Bytes()
        covmap.u32(0)
        covmap.u32(UInt32(files.bytes.count))
        covmap.u32(0)
        covmap.u32(version)
        covmap.bytes += files.bytes
        covmap.align8()
        return (covmap.bytes, NameHash.of(files.bytes))
    }

    /// A `__llvm_covfun` record for a function whose mapping is `mapping`.
    private static func record(nameRef: UInt64, hash: UInt64, filesRef: UInt64, mapping: [UInt8]) -> [UInt8] {
        var record = Bytes()
        record.u64(nameRef)
        record.u32(UInt32(mapping.count))
        record.u64(hash)
        record.u64(filesRef)
        record.bytes += mapping
        record.align8()
        return record.bytes
    }

    /// A function's mapping: one file, two expressions over counters 0 and 1, and `regions`, each a
    /// region's encoded header and its extra counters, if any.
    private static func mapping(_ regions: [Region]) -> [UInt8] {
        var mapping = Bytes()
        mapping.uleb(1)
        mapping.uleb(1) // The second name of the unit's list, the source file.
        mapping.uleb(2)
        for _ in 0..<2 {
            mapping.uleb(0 << 2 | 1) // Counter 0.
            mapping.uleb(1 << 2 | 1) // Counter 1.
        }
        mapping.uleb(UInt64(regions.count))
        for region in regions {
            mapping.uleb(region.header)
            region.extra.forEach { mapping.uleb($0) }
            mapping.uleb(2) // 2 lines after the previous region.
            mapping.uleb(1)
            mapping.uleb(1)
            mapping.uleb(region.isGap ? 1 << 31 | 4 : 4)
        }
        return mapping.bytes
    }

    /// Decodes a map from `covfun`, with the one data record and counters of `run`.
    private func decode(covfun: [UInt8], covmap: [UInt8] = covmap().bytes, names: [UInt8]? = nil) throws -> CoverageMap {
        let counters = UnsafeMutableRawBufferPointer.allocate(byteCount: Self.counts.count * 8, alignment: 8)
        let data = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
        defer {
            counters.deallocate()
            data.deallocate()
        }
        Self.counts.withUnsafeBytes { counters.copyMemory(from: $0) }
        data.initializeMemory(as: UInt8.self, repeating: 0)
        // The first record is `run`'s, and the second's counters are outside the section.
        guard let dataStart = data.baseAddress, let countersStart = counters.baseAddress else { throw CoverageMap.DecodeError.truncated }
        for (index, start) in [countersStart, countersStart + 4_096].enumerated() {
            let record = index * 64
            data.storeBytes(of: Self.run, toByteOffset: record, as: UInt64.self)
            data.storeBytes(of: Self.hash + UInt64(index), toByteOffset: record + 8, as: UInt64.self)
            let relative = Int(bitPattern: start) - Int(bitPattern: dataStart + record)
            data.storeBytes(of: relative, toByteOffset: record + 16, as: Int.self)
        }
        let nameBytes = names ?? Self.blob(Array("$s4Calc3runyyF".utf8) + [1] + Array("main".utf8), compressed: true)
        return try covmap.withUnsafeBytes { covmap in
            try covfun.withUnsafeBytes { covfun in
                try nameBytes.withUnsafeBytes { names in
                    try CoverageMap(covmap: covmap,
                                    covfun: covfun,
                                    data: UnsafeRawBufferPointer(data),
                                    counters: UnsafeRawBufferPointer(counters),
                                    names: names)
                }
            }
        }
    }

    private func values(of function: CoverageMap.Function) -> [UInt64] {
        Self.counts.withUnsafeBytes { counts in function.regions.map { function.value($0.counter, counts: counts) } }
    }

    func testTheCodeRegionsAndTheirCountsAreDecoded() throws {
        let filesRef = Self.covmap().filesRef
        let regions = [
            Region(header: 0 << 2 | 1), // Counter 0.
            Region(header: 0 << 2 | 3), // Expression 0, added: 5 + 2.
            Region(header: 1 << 2 | 2), // Expression 1, subtracted: 5 - 2.
            Region(header: 0), // A code region that never runs.
            Region(header: 9 << 2 | 1), // A counter past the function's counters.
            Region(header: 7 << 2 | 3), // An expression the function doesn't have.
            Region(header: 1 << 2 | 1, isGap: true), // A gap region.
            Region(header: 2 << 3), // A skipped region.
            Region(header: 4 << 3, extra: [1, 5]), // A branch region, with its two counters.
            Region(header: 1 << 3 | 4) // An expansion region.
        ]
        let covfun = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: Self.mapping(regions))
            // An empty record, which the compiler writes for a function it didn't keep.
            + Self.record(nameRef: 1, hash: 1, filesRef: filesRef, mapping: [])
            // The same function again, as when it is inlined into several translation units.
            + Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: Self.mapping(regions))
            // A function with no counters, and one whose counters are outside the section.
            + Self.record(nameRef: NameHash.of(Array("main".utf8)), hash: 7, filesRef: filesRef, mapping: Self.mapping([Region(header: 1)]))
            + Self.record(nameRef: Self.run, hash: Self.hash + 1, filesRef: filesRef, mapping: Self.mapping([Region(header: 1)]))
        let map = try decode(covfun: covfun)

        XCTAssertEqual(map.functions.count, 3)
        let run = map.functions[0]
        XCTAssertEqual(run.name, "$s4Calc3runyyF")
        XCTAssertEqual(run.file, Self.project.appendingPathComponent("Sources").appendingPathComponent("Calc.swift").path)
        XCTAssertEqual(run.firstCounter, 0)
        XCTAssertEqual(run.line, 2)
        XCTAssertEqual(run.regions.map(\.lineStart), [2, 4, 6, 8, 10, 12])
        XCTAssertEqual(run.regions.map(\.lineEnd), [3, 5, 7, 9, 11, 13])
        XCTAssertEqual(values(of: run), [5, 7, 3, 0, 0, 0])

        XCTAssertEqual(map.functions[1].name, "main")
        XCTAssertNil(map.functions[1].firstCounter)
        XCTAssertEqual(values(of: map.functions[1]), [0])
        XCTAssertNil(map.functions[2].firstCounter)
    }

    func testNamesThatArentCompressedAreRead() throws {
        let filesRef = Self.covmap().filesRef
        let covfun = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: Self.mapping([Region(header: 1)]))
        let map = try decode(covfun: covfun, names: Self.blob(Array("$s4Calc3runyyF".utf8), compressed: false) + [0, 0])
        XCTAssertEqual(map.functions.first?.name, "$s4Calc3runyyF")
    }

    func testNamesThatDontInflateAreLeftOut() throws {
        let filesRef = Self.covmap().filesRef
        let covfun = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: Self.mapping([Region(header: 1)]))
        var names = Bytes()
        names.uleb(14)
        names.uleb(4)
        names.bytes += [0x78, 0x9C, 0xFF, 0xFF]
        let map = try decode(covfun: covfun, names: names.bytes)
        XCTAssertEqual(map.functions.first?.name, "")
    }

    func testAnotherVersionOfTheFormatIsRefused() {
        XCTAssertThrowsError(try decode(covfun: [], covmap: Self.covmap(version: 5).bytes)) { error in
            XCTAssertEqual(error as? CoverageMap.DecodeError, .unsupportedVersion(6))
            XCTAssertEqual("\(error)", "the binary's coverage map is version 6, and CucumberSwift reads version 7, the one of Xcode 26")
        }
    }

    func testAKindOfRegionItDoesntReadIsRefused() {
        let covfun = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: Self.covmap().filesRef, mapping: Self.mapping([Region(header: 5 << 3)]))
        XCTAssertThrowsError(try decode(covfun: covfun)) { error in
            XCTAssertEqual(error as? CoverageMap.DecodeError, .unsupportedRegion(5))
            XCTAssertEqual("\(error)", "the binary's coverage map has a kind of region CucumberSwift doesn't read (5)")
        }
    }

    func testAMapThatEndsEarlyIsRefused() {
        let filesRef = Self.covmap().filesRef
        // A record whose mapping is cut short, and a number longer than 64 bits.
        let cut = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: [1, 1, 2])
        let long = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: [UInt8](repeating: 0xFF, count: 11))
        let huge = Self.record(nameRef: Self.run, hash: Self.hash, filesRef: filesRef, mapping: [0xFF, 0xFF, 0xFF, 0xFF, 0x7F])
        for covfun in [cut, long, huge] {
            XCTAssertThrowsError(try decode(covfun: covfun)) { error in
                XCTAssertEqual(error as? CoverageMap.DecodeError, .truncated)
                XCTAssertEqual("\(error)", "the binary's coverage map ends early")
            }
        }
    }
}
