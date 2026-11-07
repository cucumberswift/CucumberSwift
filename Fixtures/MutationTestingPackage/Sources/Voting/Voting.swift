//
//  Voting.swift
//  Voting
//
//  The code under test. The fixture's features check a person of 30 and one of 5, but nobody of 18, 16 or 65,
//  so the change from `>=` to `>` in each function goes unnoticed. Every other change fails a scenario.
//

public enum Voting {
    public static func canVote(age: Int) -> Bool {
        age >= 18
    }

    public static func canDrive(age: Int, licensed: Bool) -> Bool {
        age >= 16 && licensed
    }

    public static func canRetire(age: Int) -> Bool {
        age >= 65
    }
}
