Feature: Grading

  Scenario: A high score
    Given a score of 95
    Then the grade is "A"

  Scenario: A middling score
    Given a score of 75
    Then the grade is "C"
