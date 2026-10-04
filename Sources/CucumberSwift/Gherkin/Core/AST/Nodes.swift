//
//  Nodes.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 12/6/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
extension AST {
    class Node {
        var parent: Node?
        var tokens: [Lexer.Token] = []
        var children: [Node] = []
        final func add(child: Node) {
            child.parent = self
            children.append(child)
        }
        init(node: Node? = nil) {
            parent ?= node?.parent
            tokens ?= node?.tokens
            children ?= node?.children
        }
    }

    // these classes are merely a way to hold onto hierarchy, it's very useful in the parser
    class FeatureNode: Node { }
    class RuleNode: Node { }
    class BackgroundNode: Node { }
    class ScenarioNode: Node { }
    class ScenarioOutlineNode: Node { }
    class StepNode: Node { }
}
