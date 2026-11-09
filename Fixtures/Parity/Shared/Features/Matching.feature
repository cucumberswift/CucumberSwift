Feature: Matching steps

  Scenario: Cucumber expressions read their parameters
    Given the shop sells a cuke for 50 cents
    When I add 3 "cuke" to the basket
    Then the basket costs 1.5 dollars
    And the last item added is a cuke

  Scenario: A regular expression reads its groups
    When I add 2 tomatoes by regular expression
    Then the basket costs 60 cents

  Scenario: A data table
    When I add these to the basket:
      | item   | count |
      | cuke   | 2     |
      | tomato | 1     |
    Then the basket costs 130 cents

  Scenario: A doc string
    When I write this note:
      """
      Two cukes, please
      """
    Then the note has 3 words

  Scenario: And and But continue the step before them
    Given the basket is empty
    And I add 1 "lettuce" to the basket
    But I add 0 "pepper" to the basket
    Then the basket costs 120 cents

  Scenario: An async step definition
    When I wait for the delivery
    Then the delivery has arrived
