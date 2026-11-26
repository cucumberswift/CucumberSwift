@scoped
Feature: Tag scopes
  The test target maps each scenario's tags to Swift Testing scoping traits with Cucumber.mapTags.

  @fixtures:basket
  Scenario: A scenario runs inside the scopes of its tags
    Then the test's tags are "@scoped @fixtures:basket"
    And the basket is set up for this scenario

  Scenario Outline: Each example runs inside the scopes of its own tags
    Then the test's tags are "<tags>"
    And the basket is <basket> for this scenario

    @fixtures:basket
    Examples: With a basket
      | tags                     | basket |
      | @scoped @fixtures:basket | set up |

    @fixtures:none @scoped
    Examples: Without a basket
      | tags                   | basket     |
      | @scoped @fixtures:none | not set up |

  @in-a-rule
  Rule: A rule's tags are its scenarios' tags

    @fixtures:basket
    Scenario: A scenario in a rule
      Then the test's tags are "@scoped @in-a-rule @fixtures:basket"
      And the basket is set up for this scenario
