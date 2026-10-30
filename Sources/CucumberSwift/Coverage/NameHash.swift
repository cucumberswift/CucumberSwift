//
//  NameHash.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink.
//

import Foundation

/// The key that LLVM's coverage format gives a function's name and a list of file names: the low 64 bits
/// of the bytes' MD5 digest, read as a little-endian number.
///
/// The format defines these keys, so CucumberSwift has to compute them the same way to find a name or a
/// list. Nothing here protects data. CucumberSwift computes the digest itself, from RFC 1321, so that it
/// needs no cryptography library.
enum NameHash {
    /// MD5's 4 32-bit words of state.
    private struct State {
        var a: UInt32
        var b: UInt32
        var c: UInt32
        var d: UInt32
    }

    /// How far each step of a round rotates its sum.
    private static let shifts: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ]

    /// The integer part of 2^32 times the absolute sine of each step's number, from 1 to 64.
    private static let constants: [UInt32] = (1...64).map { UInt32(truncatingIfNeeded: Int64(abs(sin(Double($0))) * 4_294_967_296)) }

    /// The key of `bytes`.
    static func of<Bytes: Collection>(_ bytes: Bytes) -> UInt64 where Bytes.Element == UInt8 {
        let digest = md5(Array(bytes))
        return UInt64(digest[0]) | UInt64(digest[1]) << 32
    }

    /// The MD5 digest of `bytes`, as its 4 32-bit words.
    static func md5(_ bytes: [UInt8]) -> [UInt32] {
        var message = bytes
        let bitLength = UInt64(bytes.count) &* 8
        message.append(0x80)
        message.append(contentsOf: repeatElement(0, count: (119 - bytes.count % 64) % 64))
        withUnsafeBytes(of: bitLength.littleEndian) { message.append(contentsOf: $0) }

        var state = State(a: 0x6745_2301, b: 0xEFCD_AB89, c: 0x98BA_DCFE, d: 0x1032_5476)
        message.withUnsafeBytes { buffer in
            for chunk in stride(from: 0, to: buffer.count, by: 64) {
                state = round(state, chunk: buffer, at: chunk)
            }
        }
        return [state.a, state.b, state.c, state.d]
    }

    /// The state after one 64-byte chunk of the message, the chunk at `offset` in `buffer`.
    private static func round(_ state: State, chunk buffer: UnsafeRawBufferPointer, at offset: Int) -> State {
        var (a, b, c, d) = (state.a, state.b, state.c, state.d)
        for step in 0..<64 {
            let mixed: UInt32
            let word: Int
            switch step {
                case 0..<16:
                    mixed = (b & c) | (~b & d)
                    word = step
                case 16..<32:
                    mixed = (d & b) | (~d & c)
                    word = (5 * step + 1) % 16
                case 32..<48:
                    mixed = b ^ c ^ d
                    word = (3 * step + 5) % 16
                default:
                    mixed = c ^ (b | ~d)
                    word = (7 * step) % 16
            }
            let value = UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: offset + word * 4, as: UInt32.self))
            let sum = a &+ mixed &+ constants[step] &+ value
            (a, d, c) = (d, c, b)
            b = b &+ (sum << shifts[step] | sum >> (32 - shifts[step]))
        }
        return State(a: state.a &+ a, b: state.b &+ b, c: state.c &+ c, d: state.d &+ d)
    }
}
