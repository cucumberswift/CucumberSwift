//
//  ASTRule.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 12/6/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
extension AST {
    class Rule {
        private(set) var execute: (AST.Token, AST) -> Void
        private init(_ closure: @escaping (AST.Token, AST) -> Void) {
            execute = closure
        }

        func then(_ rule: Rule) -> Rule {
            Rule {
                self.execute($0, $1)
                rule.execute($0, $1)
            }
        }

        static let cleanAST = Rule { $1.nodeLookup = [:] }
        static let traverseToAppropriateDepth = Rule { $1.currentNode = $1.nodeLookup[$0.priority] }

        static let createNewNode = Rule {
            switch $0 {
                case .feature:
                    let feature = FeatureNode()
                    $1.nodeLookup[$0.priority] = feature
                    $1.featureNodes.append(feature)
                case .rule: $1.nodeLookup[$0.priority] = RuleNode()
                case .background: $1.nodeLookup[$0.priority] = BackgroundNode()
                case .scenario: $1.nodeLookup[$0.priority] = ScenarioNode()
                case .scenarioOutline: $1.nodeLookup[$0.priority] = ScenarioOutlineNode()
                case .step: $1.nodeLookup[$0.priority] = StepNode()
                default: return
            }
            $1.currentNode = $1.nodeLookup[$0.priority]
        }

        static let addToNearestParent = Rule {
            let nodeLookup = $1.nodeLookup
            guard let current = $1.currentNode,
                  let parentPosition = (0..<$0.priority).reversed().first(where: {
                    nodeLookup[$0] != nil
                  }) else { return }
            nodeLookup[parentPosition]?.add(child: current)
        }

        static let validateParentExists = Rule {
            let nodeLookup = $1.nodeLookup
            guard let current = $1.currentNode,
                  let parentPosition = (0..<$0.priority).reversed().first(where: {
                    nodeLookup[$0] != nil
                  }) else {
                if let token = $0.token,
                   let uri = token.position.uri {
                    Gherkin.errors.append("File: \(uri), expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got '\(token.valueDescription)'")
                }
                return
            }
        }

        static let appendTags = Rule {
            $1.currentNode?.tokens.append(contentsOf: $1.tags)
            $1.tags.removeAll()
        }
    }
}
