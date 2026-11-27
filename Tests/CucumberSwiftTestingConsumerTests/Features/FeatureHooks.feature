Feature: Feature hooks and attachments

  Scenario: The first scenario
    Given the feature's before hook has run once
    And the feature's after hook has not run
    Then I attach a note

  Scenario: The second scenario
    Given the feature's before hook has run once
    And the feature's after hook has not run

  Scenario: The third scenario
    Given the feature's before hook has run once
    And the feature's after hook has not run
