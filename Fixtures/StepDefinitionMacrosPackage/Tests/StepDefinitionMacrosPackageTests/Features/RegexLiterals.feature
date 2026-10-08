Feature: Step definition macros with regex literals
  Each kind of regex literal step definition the macros check, run as a project that uses them would run it.

  Scenario: Numbered, named and optional captures, and the step
    Given the shelf holds 4 cukes from "Lisbon"
    When I take 3 cukes
    And I take 1 cuke slowly
    And nothing happens
    Then the shelf has 0 cukes left
    And the regex step says "shelf"

  Scenario: Async, throwing and capture lists
    Given the shelf holds 2 cukes from "Porto", counted by a captured clerk
    When I restock 3 cukes asynchronously
    Then the shelf has 5 cukes left, checked by a weak runner
