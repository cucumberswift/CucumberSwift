//
//  SequenceExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
extension Sequence where Element: Equatable {
    var uniqueElements: [Element] {
        reduce(into: []) {
            if !$0.contains($1) {
                $0.append($1)
            }
        }
    }
    mutating func removeDuplicates() {
        self ?= uniqueElements as? Self
    }
}

extension Array {
    @inlinable public func dropFirst(upTo k: Int? = nil, predicate: ((Element) throws -> Bool)) rethrows -> Array.SubSequence {
        var new = dropFirst(0)
        var count = k ?? self.count
        while count > 0 { // swiftlint:disable:this empty_count
            count -= 1
            guard let first = new.first else { break }
            if try predicate(first) {
                new = new.dropFirst()
            } else {
                break
            }
        }
        return new
    }

    @inlinable public func dropLast(upTo k: Int? = nil, predicate: ((Element) throws -> Bool)) rethrows -> Array.SubSequence {
        var new = dropLast(0)
        var count = k ?? self.count
        while count > 0 { // swiftlint:disable:this empty_count
            count -= 1
            guard let last = new.last else { break }
            if try predicate(last) {
                new = new.dropLast()
            } else {
                break
            }
        }
        return new
    }

    func appending(_ element: Element) -> [Element] {
        self + [element]
    }

    func appending(contentsOf elementArr: [Element]) -> [Element] {
        self + elementArr
    }
}
