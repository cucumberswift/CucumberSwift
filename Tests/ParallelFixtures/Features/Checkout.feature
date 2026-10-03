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
        And the scenario takes a while

    # Purposely the same name as the scenario above: each needs its own class, named the same way in every
    # worker. Both take a while, so that two workers run them at the same time when Xcode hands them to two
    # workers. xcodebuild crashed when two suites with the same name ran at once.
    Scenario: Pay by card
        When I add 4 items
        Then the cart holds 4 items
        And the scenario takes a moment
        And the scenario takes a while

    Scenario Outline: Add <count> items
        When I add <count> items
        Then the cart holds <count> items
        And the scenario takes a moment

        Examples:
            | count |
            | 1     |
            | 3     |
            | 5     |
