Feature: Parallel checkout

    Background:
        Given a fresh cart

    Scenario: Pay with a gift card
        When I add 2 items
        Then the cart holds 2 items
        And the scenario takes a moment

    Scenario: Pay by card
        When I add 1 items
        Then the cart holds 1 items
        And the scenario takes a moment

    # Purposely the same name as the scenario above: each needs its own class, named the same way in every worker.
    Scenario: Pay by card
        When I add 4 items
        Then the cart holds 4 items
        And the scenario takes a moment

    Scenario Outline: Add <count> items
        When I add <count> items
        Then the cart holds <count> items
        And the scenario takes a moment

        Examples:
            | count |
            | 1     |
            | 3     |
            | 5     |
