Feature: Scenario Outlines

  Scenario Outline: Each example runs the steps with its values
    When I add <count> "<item>" to the basket
    Then the basket costs <cents> cents

    Examples: Vegetables
      | count | item    | cents |
      | 1     | cuke    | 50    |
      | 2     | tomato  | 60    |

    @fast
    Examples: Salad
      | count | item    | cents |
      | 1     | lettuce | 120   |
