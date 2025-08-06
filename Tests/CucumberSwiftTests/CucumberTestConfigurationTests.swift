//
//  CucumberTestConfigurationTests.swift
//  CucumberSwiftTests
//
//  Created by GitHub Copilot on 8/6/25.
//  Copyright © 2025 Tyler Thompson. All rights reserved.
//

import XCTest
@testable import CucumberSwift

class CucumberTestConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing environment variables
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testDefaultConfigurationIsStepBased() {
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .stepBased, "Default configuration should be step-based")
    }
    
    func testEnvironmentVariableScenarioMode() {
        setenv("CUCUMBER_TEST_MODE", "scenario", 1)
        
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .scenarioBased, "Should use scenario-based mode when env var is 'scenario'")
        
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testEnvironmentVariableStepMode() {
        setenv("CUCUMBER_TEST_MODE", "step", 1)
        
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .stepBased, "Should use step-based mode when env var is 'step'")
        
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testEnvironmentVariableCaseInsensitive() {
        setenv("CUCUMBER_TEST_MODE", "SCENARIO", 1)
        
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .scenarioBased, "Should handle uppercase environment variable")
        
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testEnvironmentVariablePluralForm() {
        setenv("CUCUMBER_TEST_MODE", "scenarios", 1)
        
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .scenarioBased, "Should handle plural form 'scenarios'")
        
        unsetenv("CUCUMBER_TEST_MODE")
        
        setenv("CUCUMBER_TEST_MODE", "steps", 1)
        
        let config2 = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config2, .stepBased, "Should handle plural form 'steps'")
        
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testInvalidEnvironmentVariableUsesDefault() {
        setenv("CUCUMBER_TEST_MODE", "invalid", 1)
        
        let config = CucumberTestConfiguration.fromEnvironment()
        XCTAssertEqual(config, .stepBased, "Should default to step-based for invalid values")
        
        unsetenv("CUCUMBER_TEST_MODE")
    }
    
    func testConfigurationEquality() {
        XCTAssertEqual(CucumberTestConfiguration.stepBased, .stepBased)
        XCTAssertEqual(CucumberTestConfiguration.scenarioBased, .scenarioBased)
        XCTAssertNotEqual(CucumberTestConfiguration.stepBased, .scenarioBased)
    }
}

// MARK: - Test Configuration Conformance
extension CucumberTestConfiguration: Equatable {
    public static func == (lhs: CucumberTestConfiguration, rhs: CucumberTestConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.stepBased, .stepBased), (.scenarioBased, .scenarioBased):
            return true
        default:
            return false
        }
    }
}
