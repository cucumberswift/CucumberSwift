Feature: Swift 6 language mode

  Scenario: Steps, hooks and reporters use main-actor code
    Given a synchronous step that uses main-actor code
    And an async step that changes a variable declared in setupSteps
    And a synchronous step that sends its step to the main actor
    And a step that reads Cucumber.shared
    And there are 3 flights from LAX
    Then the variable was changed once
    And the hooks and the reporter used main-actor code
