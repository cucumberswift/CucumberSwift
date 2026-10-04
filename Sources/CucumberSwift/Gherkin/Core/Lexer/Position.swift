//
//  Position.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 11/29/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation

extension Lexer {
    public struct Position: Hashable, Sendable {
        static let start: Position = {
            Position(line: 0, column: 0)
        }()
        public internal(set) var line: UInt
        public internal(set) var column: UInt
        public internal(set) var uri: URL?
    }
}

extension Lexer.Position: Equatable {
    public static func == (lhs: Lexer.Position, rhs: Lexer.Position) -> Bool {
        lhs.line == rhs.line && lhs.column == rhs.column
    }
}
