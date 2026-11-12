Feature: Hooks

  Scenario: Hooks run around a scenario and its steps
    Given a step runs
    When another step runs
    Then the hooks so far ran in order

  Scenario: Hooks run around the next scenario too
    Given a step runs
    Then the hooks so far ran in order
