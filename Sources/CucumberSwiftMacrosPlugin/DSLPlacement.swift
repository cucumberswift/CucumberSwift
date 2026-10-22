//
//  DSLPlacement.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// What the placement checks report.
enum DSLPlacementMessage: String, DiagnosticMessage {
    case stepDefinitionInFeature
    case stepOutsideScenario

    var message: String {
        switch self {
            case .stepDefinitionInFeature:
                "A step definition belongs in setupSteps(), outside a feature written in the Swift DSL. "
                    + "Inside a scenario, write a DSL step, such as #Given(I: doSomething())."
            case .stepOutsideScenario:
                "A DSL step belongs inside #Scenario, #Background or #ScenarioOutline. "
                    + "To match a step of a feature file, write a step definition, such as #Given(\"I do something\") { }."
        }
    }

    var diagnosticID: MessageID { MessageID(domain: "CucumberSwiftMacros", id: rawValue) }
    var severity: DiagnosticSeverity { .error }
}

/// Finds the step definitions among a container's contents, leaving those of a nested container macro to it.
private final class StepDefinitionFinder: SyntaxVisitor {
    private(set) var found = [Syntax]()

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
           DSLPlacement.stepNames.contains(name), DSLPlacement.isStepDefinition(node.arguments) {
            found.append(Syntax(node))
        }
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.macroName.text
        if DSLPlacement.containerNames.contains(name) { return .skipChildren }
        if DSLPlacement.stepNames.contains(name), DSLPlacement.isStepDefinition(node.arguments) {
            found.append(Syntax(node))
        }
        return .visitChildren
    }
}

/// Keeps the two ways of writing steps apart: a step definition, such as `#Given("I do X") { … }`, which matches a
/// feature file's step, belongs in `setupSteps()`; a step of the Swift DSL, such as `#Given(I: doX())`, which is the
/// code it runs, belongs in a scenario. The container macros report a step definition among their contents, and
/// the DSL step macros report a step written where no scenario can hold it.
enum DSLPlacement {
    /// The names a step is written with, as in the lint tool: the step classes, their typealiases and the
    /// localized typealiases, such as `ES_Dado`.
    static let stepNames: Set<String> = Set([
        "GivenStep", "WhenStep", "ThenStep", "AndStep", "ButStep", "MatchAllStep",
        "Given", "When", "Then", "And", "But", "MatchAll"
    ] + StepDefinition.localizedNames)

    /// The DSL's containers, whose macros check their own contents.
    static let containerNames: Set<String> = ["Feature", "Scenario", "ScenarioOutline", "Background", "Rule", "Description"]

    /// The result builders a DSL step can be written in outside a container, such as a function that returns a
    /// scenario's shared steps.
    static let builderAttributes: Set<String> = ["StepBuilder", "ScenarioBuilder"]

    /// Reports each step definition written among a container macro's contents, at the step definition.
    static func reportStepDefinitions(in node: some FreestandingMacroExpansionSyntax, context: some MacroExpansionContext) {
        let finder = StepDefinitionFinder()
        for argument in node.arguments { finder.walk(argument.expression) }
        if let trailingClosure = node.trailingClosure { finder.walk(trailingClosure) }
        for closure in node.additionalTrailingClosures { finder.walk(closure.closure) }
        for found in finder.found {
            context.diagnose(Diagnostic(node: found, message: DSLPlacementMessage.stepDefinitionInFeature))
        }
    }

    /// Reports a DSL step written outside any closure, function or property that a scenario can take its steps from.
    static func reportStepOutsideScenario(_ node: some FreestandingMacroExpansionSyntax, context: some MacroExpansionContext) {
        guard !isInScenario(context.lexicalContext) else { return }
        context.diagnose(Diagnostic(node: Syntax(node), message: DSLPlacementMessage.stepOutsideScenario))
    }

    /// Whether the innermost lexical context can be a scenario's contents: a closure, such as a container's, an
    /// enclosing macro, or a function or property that builds steps or scenarios.
    static func isInScenario(_ lexicalContext: [Syntax]) -> Bool {
        guard let innermost = lexicalContext.first else { return false }
        if innermost.is(ClosureExprSyntax.self) || innermost.isProtocol(FreestandingMacroExpansionSyntax.self) {
            return true
        }
        // A computed property's context is its binding, without the attributes of its declaration: accept it.
        if innermost.is(PatternBindingSyntax.self) || innermost.is(AccessorDeclSyntax.self) {
            return true
        }
        if let function = innermost.as(FunctionDeclSyntax.self) {
            return function.attributes.contains { attribute in
                guard let name = attribute.as(AttributeSyntax.self)?.attributeName.trimmedDescription else { return false }
                return builderAttributes.contains(name)
            }
        }
        return false
    }

    /// Whether a call or macro's arguments are a step definition's: a string or regex literal as the first,
    /// unlabeled argument. A DSL step's argument is code, labeled `I:` and the rest or not.
    static func isStepDefinition(_ arguments: LabeledExprListSyntax) -> Bool {
        guard let first = arguments.first, first.label == nil else { return false }
        var expression = first.expression
        if let cast = expression.as(AsExprSyntax.self) { expression = cast.expression }
        return expression.is(StringLiteralExprSyntax.self) || expression.is(RegexLiteralExprSyntax.self)
    }
}
#endif
