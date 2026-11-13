Feature: Classifying
  The calculator divides, and names the size of a number.

  @shard2
  Scenario: Dividing by zero
    Given a calculator
    When I divide 1 by 0
    Then the display shows "error"

  Rule: Numbers have sizes

    @shard1
    Scenario Outline: Classifying a number
      Given a calculator
      When I classify <number>
      Then the display shows "<size>"

      Examples:
        | number | size   |
        | 7      | small  |
        | 42     | medium |

    @shard2
    Scenario: Classifying seven again
      Given a calculator
      When I classify 7
      Then the display shows "small"
