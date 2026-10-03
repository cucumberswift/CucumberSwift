//
//  NodeHeader.swift
//  CucumberSwift
//

import Foundation

/// A feature's or a scenario's title, description and tags, read from its tokens.
struct NodeHeader {
    private(set) var title = ""
    /// Each line of the description, each followed by a newline.
    private(set) var description = ""
    private(set) var tags = [String]()

    init(_ tokens: [Lexer.Token]) {
        for token in tokens {
            if case Lexer.Token.title(_, let t) = token {
                title = t
            } else if case Lexer.Token.description(_, let d) = token {
                description += d + "\n"
            } else if case Lexer.Token.tag(_, let tag) = token {
                tags.append(tag)
            }
        }
    }
}
