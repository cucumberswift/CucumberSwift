Feature: Scenario state

  Scenario: One scenario keeps its own basket
    Given I add 3 "cuke" to my scenario's basket
    When I wait for the delivery
    Then my scenario's basket holds 3 "cuke"

  Scenario: Another scenario keeps another basket
    Given I add 5 "cuke" to my scenario's basket
    When I wait for the delivery
    Then my scenario's basket holds 5 "cuke"

  Scenario: A scenario hook reaches the scenario's state
    Then my scenario's basket was made by a hook
