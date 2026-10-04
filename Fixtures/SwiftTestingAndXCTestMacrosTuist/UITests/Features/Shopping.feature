Feature: Shopping

  Scenario: Tap to add and remove cukes
    Given the app is open
    When I tap "add" 3 times
    And I tap "remove" 1 times
    Then the app shows 2 cukes
