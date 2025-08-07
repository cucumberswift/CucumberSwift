//
//  CucumberTestConfiguration.swift
//  CucumberSwift
//
//  Created by GitHub Copilot on 8/6/25.
//  Copyright © 2025 Tyler Thompson. All rights reserved.
//

import Foundation

/// Configuration options for how CucumberSwift generates XCTest cases
public enum CucumberTestConfiguration {
    /// Each step becomes an individual test case (current default behavior)
    /// Provides fine-grained reporting but can be overwhelming in test navigator
    case stepBased

    /// Each scenario becomes a single test case with steps as activities
    /// Provides cleaner test organization with step details in activities
    case scenarioBased

    /// Reads configuration from environment variables and Info.plist
    /// Environment variable: CUCUMBER_TEST_MODE (step|scenario)
    /// Info.plist key: CucumberTestMode (step|scenario)
    /// Defaults to stepBased if not specified
    public static func fromEnvironment() -> CucumberTestConfiguration {
        // Check environment variable first
        var mode = ProcessInfo.processInfo.environment["CUCUMBER_TEST_MODE"]
        var origin = "CUCUMBER_TEST_MODE"
        if mode == nil {
            // Check Info.plist
            if let testBundle = (Cucumber.shared as? StepImplementation)?.bundle {
                mode = testBundle.infoDictionary?["CucumberTestMode"] as? String
                if mode != nil && !mode!.isEmpty{
                    origin = "CucumberTestMode"
                }
            }
        }
        if mode != nil {
            switch mode!.lowercased() {
                case "scenario", "scenarios":
                    return .scenarioBased
                case "step", "steps":
                    return .stepBased
                default:
                    print("Warning: Invalid '\(origin)' '\(mode!)'. Valid values: 'step', 'scenario'. Using default 'step'.")
                    return .stepBased
            }
        }

        // Default to step-based (current behavior)
        return .stepBased
    }
}
