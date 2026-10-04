import Foundation

precedencegroup MightBePrecedence {
    lowerThan: NilCoalescingPrecedence
    associativity: left
}

infix operator ?= : MightBePrecedence
internal func ?= <T> ( lhs: inout T, rhs: T?) {
    if let r = rhs {
        lhs = r
    }
}
