//
//  Grades.swift
//  Grades
//
//  The code under test. The fixture's feature only gives an A, so it covers less than half of `grade(for:)`.
//

public enum Grades {
    public static func grade(for score: Int) -> String {
        switch score {
            case 90...: return "A"
            case 80..<90: return "B"
            case 70..<80: return "C"
            case 60..<70: return "D"
            case 0..<60: return "F"
            default: return "?"
        }
    }
}
