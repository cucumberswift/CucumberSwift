//
//  GeneratedBareSlashStepDefinitions.swift
//  CucumberSwiftConsumerTests
//
// swiftlint:disable all

import Foundation
import XCTest
import CucumberSwift

/// The step definitions CucumberSwift generates, in the `/…/` style, for the feature in
/// CucumberSwiftTests' `GeneratedStepDefinitions.swift`, pasted in unchanged. This target turns on
/// bare slash regex literals (Xcode does by default, and this folder's Package.swift enables the
/// `BareSlashRegexLiterals` feature), so compiling this file proves that style compiles.
/// CucumberSwiftTests' `GeneratedStepDefinitionTests` checks that it still matches the generator.
/// Nothing calls this function.
///
/// If the generator changes, replace everything between the BEGIN and END lines with the output
/// the failing test prints.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
func registerGeneratedBareSlashStepDefinitions() {
    // BEGIN GENERATED
    Given(/^a step with no parameters$/) { _, _ in
        XCTFail("Step not implemented: replace this line with your test code")
    }
    MatchAll(/^a repeated step$/) { _, _ in
        XCTFail("Step not implemented: replace this line with your test code")
    }
    When(/^I log in as \"(.*?)\" with the password \"(.*?)\"$/) { matches, _ in
        let string = matches.1
        let stringTwo = matches.2
        XCTFail("Step not implemented: replace this line with your test code")
    }
    Then(/^I see (\d+) messages$/) { matches, _ in
        let integer = matches.1
        XCTFail("Step not implemented: replace this line with your test code")
    }
    Given(/^a step with \(brackets\), \[square brackets], a\/slash, a price of \$(\d+)\.(\d+)\? and a star\*$/) { matches, _ in
        let integer = matches.1
        let integerTwo = matches.2
        XCTFail("Step not implemented: replace this line with your test code")
    }
    When(/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/) { matches, _ in
        let integer = matches.1
        let string = matches.2
        let integerTwo = matches.3
        let stringTwo = matches.4
        XCTFail("Step not implemented: replace this line with your test code")
    }
    Then(/^I open the path a\/#b$/) { _, _ in
        XCTFail("Step not implemented: replace this line with your test code")
    }
    Then(/^a data table$/) { _, step in
        let dataTable = step.dataTable
        XCTFail("Step not implemented: replace this line with your test code")
    }
    Then(/^a doc string$/) { _, step in
        let docString = step.docString
        XCTFail("Step not implemented: replace this line with your test code")
    }
    // END GENERATED
}
