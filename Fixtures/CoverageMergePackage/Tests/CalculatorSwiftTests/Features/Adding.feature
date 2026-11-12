Feature: Adding
  The calculator adds whole numbers.

  Background:
    Given a calculator

  @shard1
  Scenario: Adding two numbers
    When I add 2 and 3
    Then the display shows "5"

  @shard2
  Scenario: Adding two other numbers
    When I add 4 and 4
    Then the display shows "8"

  @redundant @shard1
  Scenario: Adding zeros
    When I add 0 and 0
    Then the display shows "0"

  @shard2
  Scenario: Adding two negative numbers
    When I add -2 and -3
    Then the display shows "minus 5"
