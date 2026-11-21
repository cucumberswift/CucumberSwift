Feature: Rules

  Background:
    Given the world is reset
    And I have 10 cukes

  @in-a-rule
  Rule: A rule's Background runs after the feature's

    Background:
      When I eat 1 cukes

    Scenario Outline: Eating cukes in a rule
      When I eat <eaten> cukes
      Then I have <left> cukes

      Examples:
        | eaten | left |
        | 2     | 7    |
        | 4     | 5    |

  @left-out-in-code
  Rule: A rule's tags are its scenarios' tags

    Scenario: Left out by its rule's tag
      Given a step that fails if the scenario runs
