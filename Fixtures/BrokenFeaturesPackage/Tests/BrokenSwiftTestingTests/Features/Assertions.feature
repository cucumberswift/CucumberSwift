# Broken on purpose: each assertion below fails, and must fail its step with both runners. See the fixture's README.md.
Feature: Failing assertions
  Scenario: An expectation fails its step
    When an expectation fails
    Then the step after a failed assertion never runs

  Scenario: A requirement fails its step
    When a requirement fails
    Then the step after a failed assertion never runs

  Scenario: A recorded issue fails its step
    When an issue is recorded
    Then the step after a failed assertion never runs
