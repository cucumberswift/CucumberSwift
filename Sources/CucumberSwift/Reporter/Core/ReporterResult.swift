//
//  ReporterResult.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 5/14/21.
//  Copyright © 2021 Tyler Thompson. All rights reserved.
//

import Foundation

/// What a feature, scenario or step finished with. CucumberSwift and CucumberSwiftTesting compile this
/// file both, so a custom observer reads the same results from either runner.
public enum Reporter {
    public enum Result: Sendable {
        case passed
        case failed(String? = nil)
        case skipped
        case pending
        case undefined
        case ambiguous

        static let failed = Result.failed()
    }
}

extension Reporter.Result: Equatable {
    public static func == (lhs: Reporter.Result, rhs: Reporter.Result) -> Bool {
        switch(lhs, rhs) {
            case (.passed, .passed): return true
            case (.failed(let f1), .failed(let f2)):
                guard let f1 = f1, let f2 = f2 else { return true }
                return f1 == f2
            case (.skipped, .skipped): return true
            case (.pending, .pending): return true
            case (.undefined, .undefined): return true
            case (.ambiguous, .ambiguous): return true
            default: return false
        }
    }
}
