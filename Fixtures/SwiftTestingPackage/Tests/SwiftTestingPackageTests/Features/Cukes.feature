Feature: Counting cukes

  Scenario Outline: Eating cukes
    Given I have <start> cukes
    When I eat <eaten> cukes
    Then I have <left> cukes

    Examples: Small
      | start | eaten | left |
      | 12    | 5     | 7    |
      | 20    | 5     | 15   |

    @big
    Examples: Big
      | start | eaten | left |
      | 100   | 1     | 99   |

  Scenario: A shopping list
    Given my shopping list is
      """
      cukes
      apples
      """
    And these prices
      | item  | price |
      | cukes | 2     |
    Then the list has 2 items and the cukes cost 2
