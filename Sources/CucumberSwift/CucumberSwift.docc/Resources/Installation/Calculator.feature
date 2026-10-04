Feature: Calculator
  A first feature file. CucumberSwift runs every scenario in it as a test.

  Scenario: Add two numbers
    Given I have entered 2 into the calculator
    And I have entered 3 into the calculator
    When I press add
    Then the result is 5
