//
//  Errors.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 10/6/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
enum Gherkin {
    /// Problems in a .feature file. `CucumberTest.testGherkin()` fails each one.
    static let errors = Locked([String]())
}
