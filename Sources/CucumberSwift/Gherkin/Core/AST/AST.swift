//
//  AST.swift
//  CucumberSwift
//
//  Created by dev1 on 7/17/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

class AST {
    static var standard: AST {
        AST()
        .ruleFor(.feature(), Rule.cleanAST
                               .then(.createNewNode)
                               .then(.appendTags))
        .ruleFor(.rule(), Rule.createNewNode
                            .then(.addToNearestParent))
        .ruleFor(.background(), Rule.createNewNode
                                  .then(.addToNearestParent))
        .ruleFor(.scenario(), Rule.createNewNode
                                .then(.appendTags)
                                .then(.addToNearestParent))
        .ruleFor(.scenarioOutline(), Rule.createNewNode
                                       .then(.appendTags)
                                       .then(.addToNearestParent))
        .ruleFor(.examples(), Rule.traverseToAppropriateDepth
                                .then(.appendTags))
        .ruleFor(.step(), Rule.createNewNode
                            .then(.addToNearestParent))
        .ruleFor(.description(), Rule.validateParentExists)
    }

    private init(_ ruleLookup: [AST.Token?: Rule] = [:]) {
        self.ruleLookup = ruleLookup
    }

    func parse(_ tokens: [Lexer.Token], inFile url: String = "") -> [FeatureNode] {
        for token in tokens {
            if case Lexer.Token.tag = token {
                tags.append(token)
            } else {
                if let t = AST.Token(token) {
                    ruleLookup[t]?.execute(t, self)
                }
                currentNode?.tokens.append(token)
            }
        }
        if !tags.isEmpty {
            Gherkin.errors.append("File: \(url) unexpected end of file, expected: #TagLine, #ScenarioLine, #Comment, #Empty")
        }
        return featureNodes
    }
    var featureNodes: [FeatureNode] = []
    var ruleLookup: [AST.Token?: Rule] = [:]
    var nodeLookup: [UInt: Node] = [:]
    var tags = [Lexer.Token]()

    var currentNode: Node?

    func ruleFor(_ token: AST.Token, _ rule: Rule) -> AST {
        var ruleLookupCopy = ruleLookup
        ruleLookupCopy[token] = rule
        return AST(ruleLookupCopy)
    }
}
