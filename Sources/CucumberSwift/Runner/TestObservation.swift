//
//  TestObservation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/26/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

extension Cucumber: XCTestObservation {
    nonisolated public func testBundleDidFinish(_ testBundle: Bundle) {
        MainActor.assumeIsolated {
            reporters.forEach { $0.testSuiteFinished(at: Date()) }
            let name = Cucumber.shared.reportName.appending(String(testBundle.bundleURL.lastPathComponent.prefix { $0 != "." })).appending(".json")
            if  let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
                let reportURL = Reporter.reportURL {
                let fileURL = documentDirectory.appendingPathComponent(name)
                try? FileManager.default.copyItem(at: reportURL, to: fileURL)
            }
        }
    }

    nonisolated public func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        MainActor.assumeIsolated {
            Cucumber.shared.currentStep?.result = .failed(description)
            Cucumber.shared.currentStep?.errorMessage = description
            Cucumber.shared.currentStep?.endTime = Date()
            guard let step = Cucumber.shared.currentStep,
                  let scenario = step.scenario else {
                return
            }
            Cucumber.shared.failedScenarios.append(scenario)
            var foundStep = false
            scenario.steps.forEach { step in
                if step === Cucumber.shared.currentStep {
                    foundStep = true
                } else if foundStep && step.result == .pending {
                    step.result = .skipped
                }
            }
        }
    }
}
