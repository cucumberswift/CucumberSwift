# Broken on purpose: each problem below must be reported. See the fixture's README.md. Don't fix them.
Feature: Broken features
  Scenario: Problems in a scenario
    Given a defined step
    Thne a misspelt keyword
    When a step that no step definition matches
    And a data table with a row that is too long
      | name  | count |
      | cukes | 2     | 3 |
