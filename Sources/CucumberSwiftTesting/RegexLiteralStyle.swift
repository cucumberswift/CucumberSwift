//
//  RegexLiteralStyle.swift
//  CucumberSwiftTesting
//

/// How suggested step definitions write a regex literal.
public enum RegexLiteralStyle: Int, Sendable {
    /// `#/^…$/#`. Compiles in every language mode, with no compiler setting. The default.
    case extendedDelimiter
    /// `/^…$/`. Needs the Swift 6 language mode or the `BareSlashRegexLiterals` feature. Xcode turns that
    /// feature on by default ("Enable Bare Slash Regex Literals"); Swift Package Manager targets in the
    /// Swift 5 language mode need `swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]`.
    case bareSlash
}
