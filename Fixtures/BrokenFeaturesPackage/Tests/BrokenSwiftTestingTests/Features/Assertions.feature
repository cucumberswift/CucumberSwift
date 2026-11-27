# Broken on purpose: the requirement below fails, and must fail its step with one issue. See the fixture's README.md.
Feature: Failing assertions
  Scenario: A requirement fails its step
    When a requirement fails
    Then the step after a failed assertion never runs
