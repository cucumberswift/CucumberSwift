//
//  SwiftTestingStubs.swift
//  DocumentationExamples
//
//  The reader's own code that the documentation's examples for CucumberSwiftTesting use, such
//  as `Basket.shared`. .github/scripts/docs_examples.py compiles each example with this module.
//  An example's own declaration of a name takes precedence over the one here.
//

import CucumberSwiftTestingMacros
import Foundation

@MainActor
public final class Basket {
    public static let shared = Basket()
    public private(set) var count = 0
    public func empty() { count = 0 }
    public func add(_ count: Int) { self.count += count }
}
