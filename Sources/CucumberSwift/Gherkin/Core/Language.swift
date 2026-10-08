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
    // Every step keyword, lowercased and as the language data writes it, with or without a trailing
    // space, longest first.
    private var stepKeywords = [String]()

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
            stepKeywords = Self.stepKeywords([Keys.given, Keys.when, Keys.then, Keys.and, Keys.but]
                .flatMap { language[$0] as? [String] ?? [] })
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

    /// The step keyword that `line` starts with, as written in `line` and without a trailing space, such
    /// as `Gegeben sei` or `前提`. As in Gherkin, it is the longest keyword the line starts with, and a
    /// keyword the language data writes with a trailing space must be followed by one, or end the line.
    func stepKeyword(startingLine line: String) -> String? {
        let lowercased = line.lowercased()
        for keyword in stepKeywords {
            let name = keyword.trimmingCharacters(in: .whitespaces)
            if lowercased.hasPrefix(keyword) || lowercased == name {
                return String(line.prefix(name.count))
            }
        }
        return nil
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
        l.stepKeywords = stepKeywords(["* ", "Given ", "When ", "Then ", "And ", "But "])
        return l
    }()

    /// `keywords` lowercased, without duplicates, longest first.
    private static func stepKeywords(_ keywords: [String]) -> [String] {
        Set(keywords.map { $0.lowercased() }).sorted { ($0.count, $0) > ($1.count, $1) }
    }
}
