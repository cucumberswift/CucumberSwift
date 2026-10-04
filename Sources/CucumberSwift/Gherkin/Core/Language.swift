//
//  Language.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/22/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public class Language {
    enum Keys {
        static let feature = "feature"
        static let scenario = "scenario"
        static let background = "background"
        static let examples = "examples"
        static let scenarioOutline = "scenarioOutline"
        static let given = "given"
        static let when = "when"
        static let then = "then"
        static let and = "and"
        static let but = "but"
        static let rule = "rule"
    }

    private var featureNames = [String]()
    private var scenarioNames = [String]()
    private var backgroundNames = [String]()
    private var examplesNames = [String]()
    private var scenarioOutlineNames = [String]()
    private var ruleNames = [String()]
    private var givenNames = [String]()
    private var whenNames = [String]()
    private var thenNames = [String]()
    private var andNames = [String]()
    private var butNames = [String]()

    public var given: String {
        givenNames.last?.capitalizingFirstLetter() ?? "Given"
    }
    public var when: String {
        whenNames.last?.capitalizingFirstLetter() ?? "When"
    }
    public var then: String {
        thenNames.last?.capitalizingFirstLetter() ?? "Then"
    }
    public var and: String {
        andNames.last?.capitalizingFirstLetter() ?? "And"
    }
    public var but: String {
        butNames.last?.capitalizingFirstLetter() ?? "But"
    }

    private init() { }

    init?(_ langName: String = "en") {
        if  let data = Self.languages.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = jsonObject as? [String: Any],
            let language = json[langName] as? [String: Any] {
            featureNames ?= (language[Keys.feature]         as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            scenarioNames ?= (language[Keys.scenario]        as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            backgroundNames ?= (language[Keys.background]      as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            examplesNames ?= (language[Keys.examples]        as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            scenarioOutlineNames ?= (language[Keys.scenarioOutline] as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            ruleNames ?= (language[Keys.rule]            as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            givenNames ?= (language[Keys.given]           as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            whenNames ?= (language[Keys.when]            as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            thenNames ?= (language[Keys.then]            as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            andNames ?= (language[Keys.and]             as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            butNames ?= (language[Keys.but]             as? [String])?.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        } else {
            return nil
        }
    }

    func matchesFeature(_ str: String) -> Bool {
        featureNames.contains { $0 == str.lowercased() }
    }

    func matchesScenario(_ str: String) -> Bool {
        scenarioNames.contains { $0 == str.lowercased() }
    }

    func matchesBackground(_ str: String) -> Bool {
        backgroundNames.contains { $0 == str.lowercased() }
    }

    func matchesExamples(_ str: String) -> Bool {
        examplesNames.contains { $0 == str.lowercased() }
    }

    func matchesScenarioOutline(_ str: String) -> Bool {
        scenarioOutlineNames.contains { $0 == str.lowercased() }
    }

    func matchesRule(_ str: String) -> Bool {
        ruleNames.contains { $0 == str.lowercased() }
    }

    func matchesGiven(_ str: String) -> Bool {
        givenNames.contains { $0 == str.lowercased() }
    }

    func matchesWhen(_ str: String) -> Bool {
        whenNames.contains { $0 == str.lowercased() }
    }

    func matchesThen(_ str: String) -> Bool {
        thenNames.contains { $0 == str.lowercased() }
    }

    func matchesAnd(_ str: String) -> Bool {
        andNames.contains { $0 == str.lowercased() }
    }

    func matchesBut(_ str: String) -> Bool {
        butNames.contains { $0 == str.lowercased() }
    }
}

extension Language {
    static var `default`: Language = {
        var l = Language()
        l.featureNames = ["Feature", "Business Need", "Ability"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.scenarioNames = ["Scenario", "Example"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.backgroundNames = ["Background"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.examplesNames = ["Examples", "Scenarios"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.ruleNames = ["Rule"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.scenarioOutlineNames = ["Scenario Outline", "Scenario Template"].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.givenNames = ["* ", "Given "].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.whenNames = ["* ", "When "].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.thenNames = ["* ", "Then "].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.andNames = ["* ", "And  "].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        l.butNames = ["* ", "But "].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        return l
    }()
}
