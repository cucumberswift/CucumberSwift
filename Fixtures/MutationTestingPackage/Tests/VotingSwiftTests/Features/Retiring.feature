Feature: Retiring

  Scenario: A senior can retire
    Given a person aged 70
    Then the person can retire

  Scenario: A worker cannot retire
    Given a person aged 30
    Then the person cannot retire
