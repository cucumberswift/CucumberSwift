Feature: CucumberSwift from the Carthage-built xcframework
  Scenario: Typed arguments from Cucumber expressions
    Given I have 3 cukes in my "basket"
    When I eat 2 cukes
    Then the basket holds 1 cuke
