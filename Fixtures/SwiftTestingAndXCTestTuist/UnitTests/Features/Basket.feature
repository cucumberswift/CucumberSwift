Feature: Basket

  Background:
    Given an empty basket

  Scenario: Add cukes
    When I add 3 cukes
    Then the basket has 3 cukes

  Scenario Outline: Remove cukes
    When I add <added> cukes
    And I remove <removed> cukes
    Then the basket has <left> cukes

    Examples:
      | added | removed | left |
      | 5     | 2       | 3    |
      | 1     | 1       | 0    |

  Scenario: Remove more cukes than the basket has
    When I add 1 cukes
    Then removing 2 cukes fails
