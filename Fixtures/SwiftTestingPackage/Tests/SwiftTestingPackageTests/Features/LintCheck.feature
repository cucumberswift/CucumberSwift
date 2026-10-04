# Checks that the CucumberSwiftLint plugin runs on this target: the build must warn about line 7,
# a misspelt keyword. The scenario still passes, because its step is defined and the misspelt line
# is not a step. `mise run test-fixtures` fails if the warning is missing (see expected-warnings).
Feature: Lint check
  Scenario: A misspelt keyword after a step
    Given I have an apple tree
    Wehn the plugin checks this line
