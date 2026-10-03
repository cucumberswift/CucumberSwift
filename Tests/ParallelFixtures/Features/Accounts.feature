Feature: Parallel accounts

    Scenario: Sign in
        Given a fresh cart
        When I add 1 items
        Then the cart holds 1 items
        And the scenario takes a moment

    Scenario: Sign out
        Given a fresh cart
        Then the cart holds 0 items
        And the scenario takes a moment

    Scenario: Reset a password
        Given a fresh cart
        When I add 2 items
        And I add 3 items
        Then the cart holds 5 items
        And the scenario takes a moment

    Scenario: Delete an account
        Given a fresh cart
        Then the cart holds 0 items
        And the scenario takes a moment
