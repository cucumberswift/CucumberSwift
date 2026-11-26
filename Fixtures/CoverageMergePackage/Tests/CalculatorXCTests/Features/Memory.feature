Feature: Memory
  The calculator keeps a number in memory.

  Background:
    Given a calculator

  @shard1
  Scenario: Reading the memory
    When I read the memory
    Then the display shows "0"

  @shard2
  Scenario: Clearing the memory
    When I clear the memory
    Then the display shows "0"
