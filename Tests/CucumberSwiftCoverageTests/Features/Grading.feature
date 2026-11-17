Feature: Grading

  Scenario: A high score
    Given a score of 95
    Then the grade is "A"

  Scenario: A middling score
    Given a score of 75
    Then the grade is "C"

  # Runs the same code as "A high score", which ran first: it adds no coverage of its own, and the feature has redundancy.
  Scenario: Another high score
    Given a score of 92
    Then the grade is "A"
