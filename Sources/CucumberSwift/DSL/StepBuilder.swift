//
//  StepBuilder.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation
@resultBuilder
public enum StepBuilder {
    public static func buildBlock(_ items: StepDSL?...) -> [StepDSL] {
        items.compactMap { $0 }
    }
}
