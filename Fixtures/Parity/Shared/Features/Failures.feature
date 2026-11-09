Feature: Failures

  Scenario: An XCTest assertion fails a step
    When an XCTest assertion fails
    Then this step never runs

  Scenario: An expectation fails a step
    When an expectation fails
    Then this step never runs

  Scenario: A recorded issue fails a step
    When an issue is recorded
    Then this step never runs

  Scenario: A requirement stops a step
    When a requirement fails
    Then this step never runs

  Scenario: A thrown error fails a step
    When a step throws an error
    Then this step never runs

  Scenario: A step with no step definition fails
    When a step that nothing matches
    Then this step never runs

  Scenario: A skipped step skips the rest of the scenario
    When a step skips the scenario
    Then this step never runs
