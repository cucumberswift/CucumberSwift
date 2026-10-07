//
//  TriviaPiece+Classification.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

extension TriviaPiece {
    var isComment: Bool {
        switch self {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment: return true
            default: return false
        }
    }

    var isSpaceOrTab: Bool {
        switch self {
            case .spaces, .tabs: return true
            default: return false
        }
    }
}
#endif
