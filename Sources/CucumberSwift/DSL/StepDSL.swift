//
//  StepDSL.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//
// swiftlint:disable file_types_order

import Foundation

public class StepDSL: Step {
    public init(line: Int,
                file: StaticString) {
        super.init(with: AST.StepNode(), language: .default)
        sourceLine = line
        sourceFile = file
    }

    public init(line: UInt, column: UInt, match: String?, handler: @escaping () -> Void, file: StaticString) {
        super.init(with: { _, _ in handler() }, match: match, position: Lexer.Position(line: line, column: column))
        sourceLine = Int(line)
        sourceFile = file
    }

    public func continueAfterFailure(_ val: Bool) -> StepDSL {
        continueAfterFailure = val
        return self
    }
}

public final class GivenStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { .given }
}

public final class WhenStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { .when }
}

public final class ThenStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { .then }
}

public final class AndStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { .and }
}

public final class ButStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { .but }
}

public final class MatchAllStep: StepDSL, Matcher, GherkinDSL {
    override public var keyword: Step.Keyword { [] }
}

public typealias Given = GivenStep
public typealias When = WhenStep
public typealias Then = ThenStep
public typealias And = AndStep
public typealias But = ButStep
public typealias MatchAll = MatchAllStep
