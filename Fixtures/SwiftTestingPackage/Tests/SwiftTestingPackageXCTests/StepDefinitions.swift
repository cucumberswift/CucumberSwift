//
//  StepDefinitions.swift
//  SwiftTestingPackageXCTests
//
//  Step definitions for the XCTest target, which runs its feature files with CucumberSwift's XCTest runner
//  beside the Swift Testing target. Both targets write one Cucumber JSON report. `swift test` runs this
//  target first, and `mise run test-fixtures` checks that the Swift Testing target, which starts after the
//  report is two hours old, keeps what this one wrote.
//

import CucumberSwiftMacros
import XCTest

@MainActor final class Checkout {
    static let shared = Checkout()
    var cukes = 0
    var isPaid = false
}

/// Sets the report's age to 2 hours as this process exits, after every write to it, and leaves the file
/// `<report>.aged` as proof.
private func ageTheReport() {
    guard let path = ProcessInfo.processInfo.environment["CUCUMBER_REPORT_PATH"] else { return }
    // The marker only proves the report is aged when the age changed; a missing marker fails the fixture.
    do {
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -7_200)], ofItemAtPath: path)
        FileManager.default.createFile(atPath: path + ".aged", contents: nil)
    } catch {
        FileHandle.standardError.write(Data("error: can't set the age of the report at \(path): \(error)\n".utf8))
    }
}

private let agesTheReport: Void = { atexit(ageTheReport) }()

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle { Bundle.module }

    public func setupSteps() {
        _ = agesTheReport
        #Given("a basket of {int} cukes") { (cukes: Int) in
            Checkout.shared.cukes = cukes
            Checkout.shared.isPaid = false
        }
        #When("I pay for the basket") {
            Checkout.shared.isPaid = true
        }
        #Then("the basket is paid") {
            XCTAssertTrue(Checkout.shared.isPaid)
        }
    }
}
