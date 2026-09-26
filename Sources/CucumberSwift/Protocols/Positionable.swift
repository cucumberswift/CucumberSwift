//
//  Positionable.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 11/30/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
@MainActor
public protocol Positionable {
    var location: Lexer.Position { get }
    var endLocation: Lexer.Position { get }
}

extension Positionable {
    public func withLine(_ line: UInt) -> Bool {
        guard endLocation.line > location.line else {
            return location.line == endLocation.line && location.line == line
        }
        return (location.line...endLocation.line).contains(line)
    }
}

public func shouldRun(_ closure: @escaping @autoclosure () -> Bool?) -> Bool {
    closure() == true
}
