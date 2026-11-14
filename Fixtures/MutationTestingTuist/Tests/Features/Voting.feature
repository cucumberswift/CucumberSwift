Feature: Voting

  Scenario: An adult can vote
    Given a person aged 30
    Then the person can vote

  Scenario: A child cannot vote
    Given a person aged 5
    Then the person cannot vote
