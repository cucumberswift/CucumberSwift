//
//  PlainXCTestControl.swift
//  ParallelFixtures
//
//  Plain XCTest classes, with no CucumberSwift in them, in every parallel fixture. CI counts the workers Xcode
//  gives them as well as the workers the scenarios get: the scenarios must get as many, up to two. Where Xcode
//  runs these in one worker too, that is how Xcode runs that kind of target, not something CucumberSwift does.
//

import Foundation
import XCTest

// Xcode hands whole classes to its workers, so the control needs several classes, here side by side.
// swiftlint:disable single_test_class file_types_order

final class PlainXCTestControl1: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}

final class PlainXCTestControl2: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}

final class PlainXCTestControl3: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}

final class PlainXCTestControl4: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}

final class PlainXCTestControl5: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}

final class PlainXCTestControl6: XCTestCase {
    func testTakesAMoment() { Thread.sleep(forTimeInterval: 0.5) }
}
// swiftlint:enable single_test_class file_types_order
