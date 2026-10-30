//
//  CoverageMap.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation
#if canImport(Compression) && canImport(CryptoKit)
import Compression
import CryptoKit

/// The coverage map that the compiler puts in a binary built with code coverage: each function's code
/// regions, the source lines they cover, and how to compute each region's count from the binary's counters.
/// CucumberSwift reads it in the test process to work out which code a scenario ran, as `llvm-cov` does
/// from a profile after the run.
///
/// It reads version 7 of the coverage mapping format, the one Xcode 26 writes. A binary with another
/// version has no map, and CucumberSwift then writes its files without scores.
struct CoverageMap {
    /// A counter, or an expression over counters, as the map encodes it.
    enum Counter: Equatable {
        case zero
        case counter(Int)
        case subtract(Int)
        case add(Int)

        init(_ encoded: UInt64) {
            let index = Int(encoded >> 2)
            switch encoded & 3 {
                case 1: self = .counter(index)
                case 2: self = .subtract(index)
                case 3: self = .add(index)
                default: self = .zero
            }
        }
    }

    /// A code region: lines of one function that run together.
    struct Region: Equatable {
        let counter: Counter
        let lineStart: Int
        let lineEnd: Int
    }

    /// A function, with the code regions in its own file.
    struct Function {
        /// The function's name, as `__llvm_prf_names` gives it, which for Swift is a mangled name.
        let name: String
        let file: String
        let line: Int
        let expressions: [(Counter, Counter)]
        let regions: [Region]
        /// Where the function's counters start, in 64-bit counts from the start of the binary's counters.
        /// Nil for a function that the binary has no counters for, such as one the linker removed, which
        /// never runs.
        let firstCounter: Int?

        /// The count of `counter`, given the binary's `counts`.
        func value(_ counter: Counter, counts: UnsafeRawBufferPointer) -> UInt64 {
            guard let firstCounter else { return 0 }
            switch counter {
                case .zero:
                    return 0
                case .counter(let index):
                    let offset = (firstCounter + index) * 8
                    guard offset + 8 <= counts.count else { return 0 }
                    return counts.loadUnaligned(fromByteOffset: offset, as: UInt64.self)
                case .add(let index):
                    guard index < expressions.count else { return 0 }
                    let (lhs, rhs) = expressions[index]
                    return value(lhs, counts: counts) &+ value(rhs, counts: counts)
                case .subtract(let index):
                    guard index < expressions.count else { return 0 }
                    let (lhs, rhs) = expressions[index]
                    let left = value(lhs, counts: counts)
                    let right = value(rhs, counts: counts)
                    return left > right ? left - right : 0
            }
        }
    }

    enum DecodeError: Error, Equatable, CustomStringConvertible {
        case unsupportedVersion(UInt32)
        case truncated
        case unsupportedRegion(UInt64)

        var description: String {
            switch self {
                case .unsupportedVersion(let version):
                    "the binary's coverage map is version \(version), and CucumberSwift reads version 7, the one of Xcode 26"
                case .truncated:
                    "the binary's coverage map ends early"
                case .unsupportedRegion(let kind):
                    "the binary's coverage map has a kind of region CucumberSwift doesn't read (\(kind))"
            }
        }
    }

    fileprivate struct Key: Hashable {
        let nameRef: UInt64
        let hash: UInt64
    }

    fileprivate struct Reader {
        let bytes: UnsafeRawBufferPointer
        var offset = 0

        var isAtEnd: Bool { offset >= bytes.count }

        mutating func uleb() throws -> UInt64 {
            var result: UInt64 = 0
            var shift: UInt64 = 0
            while true {
                guard offset < bytes.count, shift < 64 else { throw DecodeError.truncated }
                let byte = bytes[offset]
                offset += 1
                result |= UInt64(byte & 0x7F) << shift
                if byte & 0x80 == 0 { return result }
                shift += 7
            }
        }

        mutating func int(_ maximum: Int = Int(Int32.max)) throws -> Int {
            let value = try uleb()
            guard value <= UInt64(maximum) else { throw DecodeError.truncated }
            return Int(value)
        }

        mutating func u32() throws -> UInt32 {
            guard offset + 4 <= bytes.count else { throw DecodeError.truncated }
            defer { offset += 4 }
            return bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
        }

        mutating func u64() throws -> UInt64 {
            guard offset + 8 <= bytes.count else { throw DecodeError.truncated }
            defer { offset += 8 }
            return bytes.loadUnaligned(fromByteOffset: offset, as: UInt64.self)
        }

        mutating func take(_ length: Int) throws -> UnsafeRawBufferPointer {
            guard length >= 0, offset + length <= bytes.count else { throw DecodeError.truncated }
            defer { offset += length }
            return UnsafeRawBufferPointer(rebasing: bytes[offset..<offset + length])
        }

        mutating func align8() {
            offset = (offset + 7) & ~7
        }
    }

    let functions: [Function]

    /// Decodes the map from a binary's sections: `__llvm_covmap`, `__llvm_covfun`, and, to find each
    /// function's counters and name, `__llvm_prf_data`, `__llvm_prf_cnts` and `__llvm_prf_names`.
    init(covmap: UnsafeRawBufferPointer,
         covfun: UnsafeRawBufferPointer,
         data: UnsafeRawBufferPointer,
         counters: UnsafeRawBufferPointer,
         names: UnsafeRawBufferPointer) throws {
        let files = try Self.decodeFilenames(covmap)
        let firstCounters = Self.firstCounters(data: data, counters: counters)
        let functionNames = Self.decodeNames(names)
        functions = try Self.decodeFunctions(covfun, files: files) { nameRef, hash in
            (functionNames[nameRef] ?? "", firstCounters[Key(nameRef: nameRef, hash: hash)])
        }
    }

    init(functions: [Function]) {
        self.functions = functions
    }
}

extension CoverageMap {
    // MARK: - Reading

    /// Each function's first counter, by its name reference and hash, from the `__llvm_prf_data` records.
    /// A record holds its counters' address relative to itself, at byte 16.
    private static func firstCounters(data: UnsafeRawBufferPointer, counters: UnsafeRawBufferPointer) -> [Key: Int] {
        guard let dataBase = data.baseAddress, let countersBase = counters.baseAddress else { return [:] }
        let recordSize = 64
        var result = [Key: Int]()
        for offset in stride(from: 0, through: data.count - recordSize, by: recordSize) {
            let nameRef = data.loadUnaligned(fromByteOffset: offset, as: UInt64.self)
            let hash = data.loadUnaligned(fromByteOffset: offset + 8, as: UInt64.self)
            let relative = data.loadUnaligned(fromByteOffset: offset + 16, as: Int.self)
            let start = (dataBase + offset + relative) - countersBase
            guard start >= 0, start % 8 == 0, start < counters.count else { continue }
            result[Key(nameRef: nameRef, hash: hash)] = start / 8
        }
        return result
    }

    /// The bytes that `compressed` inflates to, from zlib's format, or nil if they don't inflate to `length`.
    private static func inflate(_ compressed: UnsafeRawBufferPointer, length: Int) -> [UInt8]? {
        // zlib's format is a 2-byte header, then raw deflate, which is what the Compression framework reads.
        guard compressed.count > 2, let source = compressed.baseAddress else { return nil }
        var plain = [UInt8](repeating: 0, count: length)
        let written = plain.withUnsafeMutableBufferPointer { destination in
            guard let start = destination.baseAddress else { return 0 }
            return compression_decode_buffer(
                start,
                length,
                source.assumingMemoryBound(to: UInt8.self) + 2,
                compressed.count - 2,
                nil,
                COMPRESSION_ZLIB
            )
        }
        return written == length ? plain : nil
    }

    /// A list of names as the profile and the map store them: their length before compression, their
    /// length compressed, which is 0 when they aren't, and the bytes.
    private static func decodeBlob(_ reader: inout Reader) throws -> [UInt8] {
        let length = try reader.int()
        let compressedLength = try reader.int()
        if compressedLength == 0 { return Array(try reader.take(length)) }
        guard let plain = inflate(try reader.take(compressedLength), length: length) else { throw DecodeError.truncated }
        return plain
    }

    /// Each function's name, by its name reference, the low 64 bits of the MD5 of the name. Names that
    /// can't be read are left out: they only name functions in messages.
    private static func decodeNames(_ names: UnsafeRawBufferPointer) -> [UInt64: String] {
        var reader = Reader(bytes: names)
        var result = [UInt64: String]()
        while !reader.isAtEnd {
            guard let blob = try? decodeBlob(&reader) else { break }
            for name in blob.split(separator: 1) {
                result[md5(Data(name))] = String(bytes: name, encoding: .utf8) ?? ""
            }
            // The names that follow, if any, start at the next byte that isn't padding.
            while !reader.isAtEnd, reader.bytes[reader.offset] == 0 { reader.offset += 1 }
        }
        return result
    }

    /// Each translation unit's files, by the MD5 of its encoded list, which the functions refer to.
    private static func decodeFilenames(_ covmap: UnsafeRawBufferPointer) throws -> [UInt64: [String]] {
        var reader = Reader(bytes: covmap)
        var result = [UInt64: [String]]()
        while reader.offset + 16 <= covmap.count {
            _ = try reader.u32() // The number of records, 0 since version 4.
            let filenamesSize = Int(try reader.u32())
            _ = try reader.u32() // The size of the coverage data, 0 since version 4.
            let version = try reader.u32()
            // The header holds the version minus one.
            guard version == 6 else { throw DecodeError.unsupportedVersion(version + 1) }
            let blob = try reader.take(filenamesSize)
            var names = Reader(bytes: blob)
            let count = try names.int()
            let plain = try decodeBlob(&names)
            var list = [String]()
            try plain.withUnsafeBytes { buffer in
                var inner = Reader(bytes: buffer)
                for _ in 0..<count {
                    let size = try inner.int()
                    list.append(String(bytes: try inner.take(size), encoding: .utf8) ?? "")
                }
            }
            // The first name is the compilation folder, which the relative names are relative to.
            let folder = list.first ?? ""
            result[md5(Data(blob))] = list.map { $0.hasPrefix("/") || folder.isEmpty ? $0 : folder + "/" + $0 }
            reader.align8()
        }
        return result
    }

    private static func decodeFunctions(_ covfun: UnsafeRawBufferPointer,
                                        files: [UInt64: [String]],
                                        lookUp: (UInt64, UInt64) -> (name: String, firstCounter: Int?)) throws -> [Function] {
        var reader = Reader(bytes: covfun)
        var functions = [Function]()
        var seen = Set<Key>()
        while reader.offset + 28 <= covfun.count {
            let nameRef = try reader.u64()
            let dataSize = Int(try reader.u32())
            let hash = try reader.u64()
            let filenamesRef = try reader.u64()
            var map = Reader(bytes: try reader.take(dataSize))
            reader.align8()
            // A function inlined into several translation units has a record in each.
            guard dataSize > 0, seen.insert(Key(nameRef: nameRef, hash: hash)).inserted else { continue }
            let unitFiles = files[filenamesRef] ?? []
            let fileCount = try map.int()
            let functionFiles = try (0..<fileCount).map { _ in
                let index = try map.int()
                return index < unitFiles.count ? unitFiles[index] : ""
            }
            let expressionCount = try map.int()
            let expressions = try (0..<expressionCount).map { _ in (Counter(try map.uleb()), Counter(try map.uleb())) }
            var regions = [Region]()
            for fileIndex in 0..<fileCount {
                let regionCount = try map.int()
                var line = 0
                for _ in 0..<regionCount {
                    let (counter, isCode) = try readRegionHeader(&map)
                    line += try map.int()
                    _ = try map.uleb() // The first column.
                    let lineCount = try map.int()
                    let columnEnd = try map.uleb()
                    // A gap region, between two regions, has the top bit of its last column set.
                    // Only the code regions in the function's own file count, as `llvm-cov report`
                    // counts them.
                    guard isCode, columnEnd & (1 << 31) == 0, fileIndex == 0 else { continue }
                    regions.append(Region(counter: counter, lineStart: line, lineEnd: line + lineCount))
                }
            }
            let (name, firstCounter) = lookUp(nameRef, hash)
            functions.append(Function(name: name,
                                      file: functionFiles.first ?? "",
                                      line: regions.first?.lineStart ?? 0,
                                      expressions: expressions,
                                      regions: regions,
                                      firstCounter: firstCounter))
        }
        return functions
    }

    /// A region's counter, and whether it is a code region rather than an expansion, a skipped region, or
    /// a branch, which `llvm-cov report` doesn't count as regions.
    private static func readRegionHeader(_ map: inout Reader) throws -> (Counter, Bool) {
        let encoded = try map.uleb()
        guard encoded & 3 == 0 else { return (Counter(encoded), true) }
        // An expansion region has bit 2 set, and the rest is the expanded file.
        if encoded & 4 != 0 { return (.zero, false) }
        switch encoded >> 3 {
            case 0: // A code region that never runs.
                return (.zero, true)
            case 2: // A skipped region.
                return (.zero, false)
            case 4: // A branch region, with the counters of its two sides.
                _ = try map.uleb()
                _ = try map.uleb()
                return (.zero, false)
            default:
                throw DecodeError.unsupportedRegion(encoded >> 3)
        }
    }

    /// The low 64 bits of the MD5 of `bytes`, as LLVM keys its names and lists.
    private static func md5(_ bytes: Data) -> UInt64 {
        Insecure.MD5.hash(data: bytes).withUnsafeBytes { UInt64(littleEndian: $0.loadUnaligned(as: UInt64.self)) }
    }
}
#endif
