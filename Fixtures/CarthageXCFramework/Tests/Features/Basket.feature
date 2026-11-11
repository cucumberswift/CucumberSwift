Feature: CucumberSwift from the Carthage-built xcframework
  Scenario: Typed arguments from Cucumber expressions
    Given I have 3 cukes in my "basket"
    When I eat 2 cukes
    Then the basket holds 1 cuke

  Scenario: Eating more cukes than the basket holds
    Given I have 3 cukes in my "basket"
    When I eat 5 cukes
    Then the basket holds 0 cukes

  Scenario: Eating one cuke
    Given I have 4 cukes in my "basket"
    When I eat 1 cukes
    Then the basket holds 3 cukes
