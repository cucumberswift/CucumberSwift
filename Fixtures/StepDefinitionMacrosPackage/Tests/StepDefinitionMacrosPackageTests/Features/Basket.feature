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

  Scenario: Closures with capture lists
    Given I have 5 cukes in a captured container
    When I eat 2 cukes without keeping the runner
    And I wait for 2 more cukes in a captured container
    And I wait for 1 more cukes without saying async
    Then the basket holds 6 cukes, checked in a nested closure
    And the step after a capture list says "the basket is called basket"
    And in the end the basket holds 6 cukes
