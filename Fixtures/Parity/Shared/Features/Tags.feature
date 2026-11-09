@shop
Feature: Tags

  @fast
  Scenario: A scenario has its feature's tags and its own
    Then the scenario's tags are "@shop @fast"

  @skip
  Scenario: A scenario that shouldRunWith leaves out
    Then this step never runs

  @slow
  Rule: A rule's tags reach its scenarios

    @fast
    Scenario: A scenario has its rule's tags too
      Then the scenario's tags are "@shop @slow @fast"
