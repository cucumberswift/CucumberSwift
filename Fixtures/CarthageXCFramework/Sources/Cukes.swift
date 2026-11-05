//
//  Cukes.swift
//  Cukes
//
//  The code under test. The feature's scenarios take both branches of `remaining(after:from:)`.
//

public enum Cukes {
    public static func remaining(after eaten: Int, from have: Int) -> Int {
        if eaten > have {
            return 0
        }
        return have - eaten
    }
}
