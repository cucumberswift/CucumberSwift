@checkout
Feature: Checkout with XCTest
  Run by CucumberSwift's XCTest runner, in the same `swift test` run as the Swift Testing target's features,
  and written to the same report.

  Scenario: Pay for the basket
    Given a basket of 3 cukes
    When I pay for the basket
    Then the basket is paid

  Scenario: Pay for an empty basket
    Given a basket of 0 cukes
    When I pay for the basket
    Then the basket is paid
