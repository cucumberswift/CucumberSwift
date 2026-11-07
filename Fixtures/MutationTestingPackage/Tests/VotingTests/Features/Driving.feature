Feature: Driving

  Scenario: An adult with a licence can drive
    Given a person aged 30 with a licence
    Then the person can drive

  Scenario: An adult without a licence cannot drive
    Given a person aged 30
    Then the person cannot drive

  Scenario: A child with a licence cannot drive
    Given a person aged 10 with a licence
    Then the person cannot drive
