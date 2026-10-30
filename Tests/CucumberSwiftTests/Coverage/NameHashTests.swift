//
//  NameHashTests.swift
//  CucumberSwiftTests
//
//  LLVM's coverage format keys names by the low 64 bits of their MD5 digest, which CucumberSwift
//  computes itself (#502). The digests are RFC 1321's test vectors.
//

import Foundation
import XCTest
@testable import CucumberSwift

final class NameHashTests: XCTestCase {
    private func hex(_ text: String) -> String {
        NameHash.md5(Array(text.utf8))
            .flatMap { word in (0..<4).map { UInt8(truncatingIfNeeded: word >> (8 * UInt32($0))) } }
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func testTheDigestsAreRFC1321s() {
        XCTAssertEqual(hex(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(hex("a"), "0cc175b9c0f1b6a831c399e269772661")
        XCTAssertEqual(hex("abc"), "900150983cd24fb0d6963f7d28e17f72")
        XCTAssertEqual(hex("message digest"), "f96b697d7cb7938d525a2f31aaf161d0")
        XCTAssertEqual(hex("abcdefghijklmnopqrstuvwxyz"), "c3fcd3d76192e4007dfb496cca67e13b")
        XCTAssertEqual(hex("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"), "d174ab98d277d9f5a5611c2c9f419d9f")
        XCTAssertEqual(hex(String(repeating: "1234567890", count: 8)), "57edf4a22be3c955ac49da2e2107b67a")
    }

    func testTheKeyIsTheDigestsFirst8BytesAsALittleEndianNumber() {
        XCTAssertEqual(NameHash.of(Array("".utf8)), 0x04B2_008F_D98C_1DD4)
    }
}
