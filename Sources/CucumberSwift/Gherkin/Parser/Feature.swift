//
//  Feature.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public class Feature: Taggable, Positionable {
    public private(set)  var title = ""
    public private(set)  var desc = ""
    public private(set)  var scenarios = [Scenario]()
    public private(set)  var uri: String = ""
    public internal(set) var tags = [String]()
    public private(set)  var location: Lexer.Position
    public private(set)  var endLocation: Lexer.Position
    internal var startDate = Date()

    init(with node: AST.FeatureNode, uri: String = "") {
        location = node.tokens.first?.position ?? .start
        endLocation = .start
        self.uri = uri
        let header = NodeHeader(node.tokens)
        title = header.title
        desc = header.description
        tags = header.tags
        for content in node.scenarioContents(featureTags: tags, uri: uri) {
            switch content {
                case let .scenario(scenarioNode, backgroundStepNodes):
                    scenarios.append(Scenario(with: scenarioNode, tags: tags, stepNodes: backgroundStepNodes))
                case let .outline(_, examples):
                    scenarios.append(contentsOf: examples.map { Scenario(example: $0) })
            }
        }
        scenarios.forEach { $0.feature = self }
        endLocation ?= scenarios.last?.endLocation
    }

    init(with scenarios: [Scenario], title: String?, description: String = "", tags: [String], position: Lexer.Position, file: StaticString = #file) {
        location = position
        endLocation = scenarios.last?.endLocation ?? .start
        self.scenarios = scenarios
        self.title ?= title
        self.desc = description
        self.tags = tags
        self.scenarios.forEach { [weak self] in $0.feature = self }
        self.uri = String(file)
    }

    public func containsTags(_ tags: [String]) -> Bool {
        if (tags.contains { containsTag($0) }) {
            return true
        }
        if (scenarios.contains { $0.containsTags(tags) }) {
            return true
        }
        return false
    }

    /*func toJSON() -> [String: Any] {
        [
            "uri": uri,
            "id": title.lowercased().replacingOccurrences(of: " ", with: "-"),
            "name": title,
            "description": desc,
            "keyword": "Feature",
            "elements": []
        ]
    }*/
}
