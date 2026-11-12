Feature: Coverage

  Scenario: A cuke has a price
    Then a "cuke" costs 50 cents

  Scenario: Another cuke has the same price
    Then a "cuke" costs 50 cents

  Scenario: Something the shop doesn't sell costs nothing
    Then a "melon" costs 0 cents
