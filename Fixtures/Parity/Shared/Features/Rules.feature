Feature: Rules and Backgrounds

  Background:
    Given the basket is empty

  Rule: A rule adds its own Background

    Background:
      Given I add 1 "cuke" to the basket

    Scenario: The feature's Background runs before the rule's
      Then the basket costs 50 cents

    Scenario: Each scenario starts again from the Backgrounds
      When I add 1 "tomato" to the basket
      Then the basket costs 80 cents

  Rule: Another rule has only the feature's Background

    Scenario: The other rule's Background doesn't run
      Then the basket costs 0 cents
