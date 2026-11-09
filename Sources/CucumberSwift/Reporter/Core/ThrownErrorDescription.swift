//
//  ThrownErrorDescription.swift
//  CucumberSwift
//

import Foundation

/// How a step that throws is described in the report and in the failure, shared by both runners so that
/// the same error gives the same message in each.
enum ThrownErrorDescription {
    /// The error's own description: a `LocalizedError`'s `errorDescription`, or else what `String(describing:)`
    /// gives. A failed `try #require` is described by its expectation, as Swift Testing prints it, such as
    /// `Expectation failed: 1 == 2`.
    static func of(_ error: any Error) -> String {
        if let expectation = expectationFailure(error) { return expectation }
        return (error as? any LocalizedError)?.errorDescription ?? String(describing: error)
    }

    /// Swift Testing's `ExpectationFailedError` is read by reflection, because the XCTest runner can't import
    /// Swift Testing (older toolchains and Carthage don't have it). `nil` for any other error, or when the
    /// expression has a form this doesn't know, in which case the error's own description is used.
    private static func expectationFailure(_ error: any Error) -> String? {
        guard String(describing: type(of: error)) == "ExpectationFailedError",
              let expectation = child("expectation", of: error) ?? Mirror(reflecting: error).children.first?.value,
              let expression = child("evaluatedExpression", of: expectation),
              let text = render(expression) else { return nil }
        return "Expectation failed: \(text)"
    }

    private static func child(_ label: String, of value: Any) -> Any? {
        Mirror(reflecting: value).children.first { $0.label == label }?.value
    }

    /// The source text of an expression, from the cases of Swift Testing's `__Expression.Kind` that
    /// `#require` and `#expect` produce for ordinary conditions.
    private static func render(_ kind: Any) -> String? {
        let mirror = Mirror(reflecting: kind)
        if mirror.displayStyle == .optional {
            return mirror.children.first.flatMap { render($0.value) }
        }
        // An `__Expression` wraps its `Kind`.
        if mirror.displayStyle == .struct {
            return mirror.children.first { $0.label == "kind" }.flatMap { render($0.value) }
        }
        guard mirror.displayStyle == .enum, let payload = mirror.children.first else { return nil }
        let parts = Mirror(reflecting: payload.value).children
        func part(_ label: String) -> Any? { parts.first { $0.label == label }?.value }
        switch payload.label {
            case "generic":
                return payload.value as? String
            case "stringLiteral":
                return part("sourceCode") as? String
            case "binaryOperation":
                guard let lhs = part("lhs").flatMap(render), let op = part("operator") as? String,
                      let rhs = part("rhs").flatMap(render) else { return nil }
                return "\(lhs) \(op) \(rhs)"
            case "propertyAccess":
                guard let value = part("value").flatMap(render), let keyPath = part("keyPath").flatMap(render) else { return nil }
                return "\(value).\(keyPath)"
            case "functionCall":
                guard let name = part("functionName") as? String,
                      let arguments = part("arguments").flatMap(renderArguments) else { return nil }
                let receiver = part("value").flatMap(render).map { "\($0)." } ?? ""
                return "\(receiver)\(name)(\(arguments))"
            default:
                return nil
        }
    }

    private static func renderArguments(_ arguments: Any) -> String? {
        var rendered = [String]()
        for argument in Mirror(reflecting: arguments).children {
            guard let value = child("value", of: argument.value).flatMap(render) else { return nil }
            let label = (child("label", of: argument.value) as Any?).flatMap { Mirror(reflecting: $0).children.first?.value as? String }
            rendered.append(label.map { "\($0): \(value)" } ?? value)
        }
        return rendered.joined(separator: ", ")
    }
}
