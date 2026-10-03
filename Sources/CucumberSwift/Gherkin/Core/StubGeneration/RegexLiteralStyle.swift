//
//  RegexLiteralStyle.swift
//  CucumberSwift
//

import Foundation

/// How a generated step definition writes its regular expression literal.
///
/// Which form compiles is a setting of the test target the code is pasted into, not of CucumberSwift,
/// so CucumberSwift can't detect it. Both need Swift 5.7 or later.
@objc public enum RegexLiteralStyle: Int {
    /// `#/^…$/#`. Compiles in every language mode, with no compiler setting. The default.
    case extendedDelimiter
    /// `/^…$/`. Needs the Swift 6 language mode or the `BareSlashRegexLiterals` feature. Xcode
    /// turns that feature on by default ("Enable Bare Slash Regex Literals"); Swift Package Manager
    /// targets in the Swift 5 language mode need
    /// `swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]`.
    case bareSlash
}
