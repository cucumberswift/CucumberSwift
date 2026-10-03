Feature: Step definition macros
  Each kind of step definition the macros check, run as a project that uses them would run it.

  Scenario: Cucumber expressions, a custom parameter, a regular expression and the step
    Given I have 3 cukes in my "basket"
    And a green cuke
    When I eat 2 cukes
    Then the basket holds 1 cuke
    And the step says "the basket is called basket"

  Scenario: An async step
    When I wait for 2 more cukes
    Then the basket holds 2 cukes
