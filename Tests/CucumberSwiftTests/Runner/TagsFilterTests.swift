//
//  TagsFilterTests.swift
//  CucumberSwift
//
//  
//  Copyright © 2025 Tyler Thompson. All rights reserved.
//

import Testing
import Foundation
@testable import CucumberSwift

class TagsFilterTests {
    init() {
        // Clear any existing TAGS environment variable before each test
        setenv("TAGS", "", 1)
    }

    deinit {
        // Clean up environment variable after each test
        unsetenv("TAGS")
    }

    // MARK: - shouldRunWith Unit Tests (testing the logic directly)

    // Test data structure
    struct TagsFilterTestCase {
        let env: String?
        let tags: [String]
        let expected: Bool
        let desc: Comment
    }

    @Test(arguments: [
        TagsFilterTestCase(
            env: nil,
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should run all scenarios when no TAGS environment variable is set (multiple tags)"),

        TagsFilterTestCase(
            env: nil,
            tags: ["dev"],
            expected: true,
            desc: "Should run all scenarios when no TAGS environment variable is set (single tag)"),

        TagsFilterTestCase(
            env: nil,
            tags: [],
            expected: true,
            desc: "Should run all scenarios when no TAGS environment variable is set (no tag)"),

        TagsFilterTestCase(
            env: "",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should run all scenarios when TAGS environment variable is empty (multiple tags)"),

        TagsFilterTestCase(
            env: "",
            tags: ["dev"],
            expected: true,
            desc: "Should run all scenarios when TAGS environment variable is empty (single tag)"),

        TagsFilterTestCase(
            env: "",
            tags: [],
            expected: true,
            desc: "Should run all scenarios when TAGS environment variable is empty (no tag)"),

        TagsFilterTestCase(
            env: "@dev",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should run scenario that matches the tag from environment variable (multiple tags)"),

        TagsFilterTestCase(
            env: "@dev",
            tags: ["dev"],
            expected: true,
            desc: "Should run scenario that matches the tag from environment variable (single tag)"),

        TagsFilterTestCase(
            env: "@dev",
            tags: [],
            expected: false,
            desc: "Should not run scenario that matches with no tags"),

        TagsFilterTestCase(
            env: "@production",
            tags: ["dev", "smoke"],
            expected: false,
            desc: "Should not run scenario that doesn't match the tag from environment variable"),

        TagsFilterTestCase(
            env: "@dev and @smoke",
            tags: ["dev", "smoke", "ui"],
            expected: true,
            desc: "Should run scenario that matches AND expression from environment variable"),

        TagsFilterTestCase(
            env: "@dev or @pre",
            tags: ["dev", "smoke", "ui"],
            expected: true,
            desc: "Should run scenario that matches OR expression from environment variable"),

        TagsFilterTestCase(
            env: "not @dev",
            tags: ["smoke", "ui"],
            expected: true,
            desc: "Should run scenario that matches NOT expression from environment variable"),

        TagsFilterTestCase(
            env: "not @dev",
            tags: ["dev", "smoke"],
            expected: false,
            desc: "Should not run scenario with excluded tag"),

        TagsFilterTestCase(
            env: "(@dev or @staging) and @smoke",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should run dev scenario with smoke - Parentheses, dev+smoke"),

        TagsFilterTestCase(
            env: "(@dev or @staging) and @smoke",
            tags: ["staging", "smoke"],
            expected: true,
            desc: "Should run staging scenario with smoke - Parentheses, staging+smoke"),

        TagsFilterTestCase(
            env: "(@dev or @staging) and @smoke",
            tags: ["dev"],
            expected: false,
            desc: "Should not run dev scenario without smoke - Parentheses, dev only"),

        TagsFilterTestCase(
            env: "@smoke",
            tags: ["smoke", "fast"],
            expected: true,
            desc: "CI: Should run smoke tests"),

        TagsFilterTestCase(
            env: "not @slow",
            tags: ["fast", "integration"],
            expected: true,
            desc: "CI: Should run fast tests"),

        TagsFilterTestCase(
            env: "not @slow",
            tags: ["slow", "integration"],
            expected: false,
            desc: "CI: Should not run slow tests"),

        TagsFilterTestCase(
            env: "@regression or (@smoke and @critical)",
            tags: ["regression"],
            expected: true,
            desc: "CI: Should run regression tests"),

        TagsFilterTestCase(
            env: "@regression or (@smoke and @critical)",
            tags: ["smoke", "critical"],
            expected: true,
            desc: "CI: Should run critical smoke tests"),

        TagsFilterTestCase(
            env: "@regression or (@smoke and @critical)",
            tags: ["smoke"],
            expected: false,
            desc: "CI: Should not run non-critical smoke tests"),

        TagsFilterTestCase(
            env: "not @dev and (@smoke or @sanity)",
            tags: ["smoke", "ui"],
            expected: true,
            desc: "CI: Should run smoke or sanity but not dev"),

        TagsFilterTestCase(
            env: "not @dev and (@smoke or @sanity)",
            tags: ["smoke", "dev"],
            expected: false,
            desc: "CI: Should not run dev"),

        TagsFilterTestCase(
            env: "((@dev or @staging) and @smoke)",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "CI: Nested parentheses"),

        TagsFilterTestCase(
            env: "@dev",
            tags: ["@dev", "@smoke"],
            expected: true,
            desc: "Should handle @ prefixes in scenario tags"),

        TagsFilterTestCase(
            env: "@dev",
            tags: ["dev", "@smoke"],
            expected: true,
            desc: "Should handle mixed @ prefixes"),

        TagsFilterTestCase(
            env: "  @dev   and   @smoke  ",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should handle extra whitespace in environment variable"),

        TagsFilterTestCase(
            env: "  @dev   and   @smoke  ",
            tags: ["DEV", "SMOKE"],
            expected: true,
            desc: "Should handle extra whitespaces and case differences"),

        TagsFilterTestCase(
            env: "  @DEV   and   @smoke  ",
            tags: ["dev", "SMOKE"],
            expected: true,
            desc: "Should handle extra whitespaces and case differences (mixed)"),

        TagsFilterTestCase(
            env: "@DEV",
            tags: ["dev", "smoke"],
            expected: true,
            desc: "Should handle case differences"),

        TagsFilterTestCase(
            env: "@DEV",
            tags: ["DEV", "smoke"],
            expected: true,
            desc: "Should handle case differences (mixed)"),

        TagsFilterTestCase(
            env: "@dev or @staging and @smoke",
            tags: ["dev"],
            expected: true,
            desc: "Should match: dev (regardless of smoke)"),

        TagsFilterTestCase(
            env: "@dev or @staging and @smoke",
            tags: ["staging", "smoke"],
            expected: true,
            desc: "Should match: staging and smoke"),

        TagsFilterTestCase(
            env: "@dev or @staging and @smoke",
            tags: ["staging"],
            expected: false,
            desc: "Should NOT match: staging without smoke"),

        TagsFilterTestCase(
            env: "@dev or @staging and @smoke",
            tags: ["production"],
            expected: false,
            desc: "Should NOT match: neither dev nor (staging and smoke)"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke)",
                    tags: ["pre", "smoke"],
                    expected: true,
                    desc: "Should match: @env and single tag in parenthesis"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke)",
                    tags: ["pro", "smoke"],
                    expected: false,
                    desc: "Should NOT match: @env and single tag in parenthesis"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke or @sanity)",
                    tags: ["pre", "smoke"],
                    expected: true,
                    desc: "Should match: @env and multiple tags in parenthesis with one tag"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke or @sanity)",
                    tags: ["pro", "sanity"],
                    expected: false,
                    desc: "Should NOT match: @env and multiple tags in parenthesis with one tag"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke and @feature)",
                    tags: ["pre", "smoke", "feature"],
                    expected: true,
                    desc: "Should match: @env and multiple tags in parenthesis with all tags"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke and @feature)",
                    tags: ["pro", "feature"],
                    expected: false,
                    desc: "Should NOT match: @env and multiple tags in parenthesis with all tags"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke and (@feature1 or @feature2))",
                    tags: ["pre", "smoke", "feature1"],
                    expected: true,
                    desc: "Should match: @env and nested tags in parenthesis with one tag"),

        TagsFilterTestCase(
                    env: "@pre and (@smoke and (@feature1 or @feature2))",
                    tags: ["pro", "feature2"],
                    expected: false,
                    desc: "Should NOT match: @env and nested tags in parenthesis with one tag"),

        TagsFilterTestCase(
                    env: "@pre and (@feature or (@smoke and @sanity))",
                    tags: ["pre", "feature"],
                    expected: true,
                    desc: "Should match: @env and nested tags with OR condition"),

        TagsFilterTestCase(
                    env: "@pre and (@feature or (@smoke and @sanity))",
                    tags: ["pre", "smoke", "sanity"],
                    expected: true,
                    desc: "Should match: @env and nested tags with OR condition"),

        TagsFilterTestCase(
                    env: "@pre and (@feature or (@smoke and @sanity))",
                    tags: ["pro", "sanity"],
                    expected: false,
                    desc: "Should NOT match: @env and nested tags with OR condition")
    ] as [TagsFilterTestCase])
    func shouldRunWithParameterized(testCase: TagsFilterTestCase) {
        if let env = testCase.env {
            setenv("TAGS", env, 1)
        } else {
            unsetenv("TAGS")
        }
        let result = shouldRunWith(tags: testCase.tags)
        #expect(testCase.expected == result, testCase.desc)
    }

    // MARK: - Helper Methods

    /// Helper function that simulates the shouldRunWith extension method
    private func shouldRunWith(tags: [String]) -> Bool {
        // This replicates the logic from the Cucumber extension
        let filterExpression: String?
        if let tagsEnvVar = ProcessInfo.processInfo.environment["TAGS"], !tagsEnvVar.isEmpty {
            filterExpression = tagsEnvVar
        } else {
            filterExpression = nil
        }

        return TagsFilter.shouldRun(filterExpression: filterExpression, scenarioTags: tags)
    }
}
