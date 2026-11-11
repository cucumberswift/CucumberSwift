Feature: Grading

  Scenario: A high score
    Given a score of 95
    Then the grade is "A"

  Scenario: Another high score
    Given a score of 97
    Then the grade is "A"

  Scenario: A failing score
    Given a score of 10
    Then the grade is "F"
