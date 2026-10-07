Feature: Tables, doc strings and outlines
  Plain step definitions and macros together, with each kind of step argument and an outline.

  Background:
    Given I have 0 cukes in my "basket"

  Scenario: A data table
    Given the basket holds these cukes:
      | color | count |
      | green | 2     |
      | red   | 1     |
    Then the basket holds 3 cukes

  Scenario: A doc string
    Given a note on the basket:
      """
      Keep the cukes cool.
      """
    Then the note says "Keep the cukes cool."

  Scenario Outline: Eating some of the cukes
    Given I have <start> cukes in my "basket"
    When I eat <eaten> cukes
    Then the basket holds <left> cukes

    Examples:
      | start | eaten | left |
      | 3     | 1     | 2    |
      | 5     | 5     | 0    |
