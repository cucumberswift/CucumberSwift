Feature: Hook macros
  The hooks written as macros run as the hook functions do: in order of priority, before and after each
  step and scenario, and once before and after the feature.

  Scenario: The before hooks
    Given the before hook macros have run in order of priority
    Then the step hook macros run before and after each step

  Scenario: The after hooks
    Then the after hook macros of the first scenario have run
