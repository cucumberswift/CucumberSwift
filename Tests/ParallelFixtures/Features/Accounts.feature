# The title sorts after the checkout feature's, though this file comes first, so that XCTest's order of
# classes by name is not the order of the files, and CI can tell a run in the files' order from one that is not.
Feature: Parallel user accounts

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
