//
//  Grades.swift
//  Grades
//
//  The code under test of CucumberSwiftCoverageTests, which mutation testing mutates too. The feature
//  checks scores of 95, 92 and 75, so it runs some branches of `grade(for:)` and no scenario checks a
//  score of exactly 90 or 80.
//

public enum Grades {
    public static func grade(for score: Int) -> String {
        if score >= 90 { return "A" }
        if score >= 80 { return "B" }
        return "C"
    }
}
