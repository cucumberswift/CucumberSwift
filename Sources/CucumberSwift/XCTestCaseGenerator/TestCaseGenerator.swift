//
//  TestCaseGenerator.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 3/2/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

enum TestCaseGenerator {
    static func initWith(className: String, method: TestCaseMethod?) -> (XCTestCase.Type, Selector)? {
        guard let method = method,
              let testCase = makeClass(className: className ) else { return nil }

        if let methodSelector = addTestMethod(testCase: testCase, method: method) {
            return (testCase, methodSelector)
        }

        return nil
    }

    static func makeClass(className: String, superclass: XCTestCase.Type = XCTestCase.self) -> XCTestCase.Type? {
        let uniqueName = { () -> String in
            var count = 0
            var name = className
            while NSClassFromString(name) != nil {
                count += 1
                name = "\(className)\(count)"
            }
            return name
        }()

        // swiftlint:disable:next legacy_objc_type
        guard let className = (uniqueName as NSString).utf8String else { return nil }

        if let testCase = objc_allocateClassPair(superclass, className, 0) as? XCTestCase.Type {
            return testCase
        }

        return nil
    }

    static func addTestMethod(testCase: XCTestCase.Type?, method: TestCaseMethod?) -> Selector? {
        guard let method = method,
              let testCase = testCase else { return nil }

        let methodSelector = sel_registerName(method.name)
        let implementation = imp_implementationWithBlock(method.closure)
        class_addMethod(testCase, methodSelector, implementation, "v@:")
        return methodSelector
    }
}
