//
//  MacrosLinkedTests.swift
//  BasketUnitTests
//
// This target links CucumberSwiftTestingMacros, so the Swift Testing runner suggests macros for undefined
// steps: it looks for the class the macros module declares.

import Foundation
import Testing

@Test func theRunnerCanTellThatTheMacrosAreLinked() {
    #expect(NSClassFromString("CucumberSwiftTestingMacrosMarker") != nil)
}
