@fruit
Feature: I can eat fruit

  Background:
    Given I have an apple tree

  Scenario: I can eat a green apple
    When I pick a "green" apple
    Then I can enjoy a delicious snack

  @slow
  Scenario: I can eat a red apple
    When I pick a "red" apple
    Then I can enjoy a delicious snack
    But I still have 0 cukes
