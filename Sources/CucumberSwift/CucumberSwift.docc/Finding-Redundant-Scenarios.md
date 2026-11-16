# Finding redundant scenarios

Find the scenarios that run only code that other scenarios run, and merge or remove them.

## Overview

CucumberSwift marks a scenario as redundant when the other scenarios run all the code it runs. It measures this with code coverage, so turn coverage on first, as <doc:Measuring-Code-Coverage> describes. The redundancy is then on, with these defaults:

```swift
public func setupSteps() {
    // Cucumber.redundancy = true              // CUCUMBER_REDUNDANCY, default on
    // Cucumber.redundancyWarningLevel = 30    // CUCUMBER_REDUNDANCY_WARNING_LEVEL, default 30
    // Cucumber.redundancyErrorLevel = .off    // CUCUMBER_REDUNDANCY_ERROR_LEVEL, default off
    // Cucumber.redundantStepWarningLevel = 50 // CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL, default 50
    // Your steps
}
```

CucumberSwift marks a scenario as redundant when the other scenarios run all the code it runs. Such a scenario costs time on every run and adds no coverage, so you can merge it into a Scenario Outline or remove it.

## Which scenarios are redundant

A scenario is redundant when the scenarios that are kept run all the code it runs after its `Background`. CucumberSwift first keeps every scenario that the others don't cover. Of the scenarios that the others cover, the one that runs more code is kept first. Only scenarios that run as much code as each other, such as two duplicates, are settled by their order in the feature file, and the later one is redundant. With mutation testing on, the redundancy also compares the scenarios by the mutants they fail on: see <doc:#Find-redundant-scenarios-by-what-they-check>.

CucumberSwift compares the code that runs, not the values you pass in. The Coverage sample's `Adding.feature` has 3 scenarios that add positive numbers through `add`, a function without branches, so they run the same code:

```gherkin
Feature: Adding
  The calculator adds whole numbers.

  Background:
    Given a calculator

  Scenario: Adding two numbers
    When I add 2 and 3
    Then the display shows "5"

  Scenario: Adding two other numbers
    When I add 4 and 4
    Then the display shows "8"

  Scenario: Adding ones
    When I add 1 and 1
    Then the display shows "2"

  Scenario: Adding two negative numbers
    When I add -2 and -3
    Then the display shows "minus 5"
```

The summary adds the redundancy and the wasted time after the coverage, and marks each redundant scenario:

```
CucumberSwift coverage: Adding: 100% of the code its scenarios ran (4 of 4 regions in 2 functions), 12% of all measured code, redundancy 50%, about 0.03 s of 0.16 s in redundant scenarios
    Share  Own regions      Time  Scenario
      21%            0     0.12s  Adding two numbers (line 7)
      21%            0     0.01s  Adding two other numbers (line 11, adds no coverage of its own)
      21%            0     0.01s  Adding ones (line 15, adds no coverage of its own)
      38%            1     0.01s  Adding two negative numbers (line 19)
```

The first scenario is kept, and the next two are redundant. The negative-numbers scenario runs code of its own, so it is kept too. A feature's redundancy is the share of its scenarios that are redundant, here 2 of 4. A feature at or above 30% gets a warning on its `Feature:` line. The wasted time is the total time of the redundant scenarios, such as "about 4.2 s of 12.6 s". The manifest records the time of each scenario and each feature.

Each redundant scenario gets a warning on its line, with its time. Both warnings are in the feature's `Redundancy` test:

```
Scenario adds no coverage of its own: other scenarios run all the code it runs after the Background. It took 0.01 s. Consider a Scenario Outline for other values, or remove it.
```

The warnings suggest a Scenario Outline because the scenarios differ only in their values. Write one Scenario Outline for the positive numbers, and its examples count as one scenario:

```gherkin
Scenario Outline: Adding positive numbers
  When I add <first> and <second>
  Then the display shows "<sum>"

  Examples:
    | first | second | sum |
    | 2     | 3      | 5   |
    | 4     | 4      | 8   |
    | 1     | 1      | 2   |
```

Xcode shows the warnings on the feature and on each scenario. The sample sets the redundancy's error level to 40%, so the feature line is an error here. By default it is a warning, and it never fails a test. The screenshot also shows a warning on each `When` step, which <doc:#Find-redundant-steps> explains:

![The Adding feature file in Xcode with a redundancy error on the Feature line, warnings on 2 scenarios, and warnings on 3 When steps. Each When step says 100% of its code is repeated by another step, and suggests a Scenario Outline for different values.](RedundantSteps-ScenarioOutline.png)

## Put shared code in a Background

Put the steps that every scenario needs in a `Background`. CucumberSwift leaves out of the redundancy the code that a scenario runs during its Background steps, including the code that those steps call. That code still counts toward the coverage. The `Given a calculator` step in the feature above is an example.

## Find redundant steps

CucumberSwift also marks redundant steps, because two steps with different text can run the same code. A step is redundant when other scenarios run its code in exactly the same way. Each redundant step gets a warning on its line that gives the share of its code that another step repeats.

Take the Coverage sample's `Memory.feature`, where both `When` steps open the memory before they read or clear it:

```gherkin
Feature: Memory
  The calculator keeps numbers in memory.

  Background:
    Given a calculator

  Scenario: Reading the memory
    When I read the memory
    Then the display shows "0"

  Scenario: Clearing the memory
    When I clear the memory
    Then the display shows "3"
```

The warnings suggest moving the code that opens the memory into the `Background`:

```
Redundant step. 75% of the code in this step is repeated by the step at line 12. Consider moving it to the Background.
Redundant step. 60% of the code in this step is repeated by the step at line 8. Consider moving it to the Background.
```

Xcode shows the warning on each step, and lists both under the feature's `Redundancy` test:

![The Memory feature file in Xcode with a warning on each of its 2 When steps, "I read the memory" and "I clear the memory". They say that 75% and 60% of the code in the step is repeated by the other step, and suggest moving it to the Background.](RedundantSteps-Background.png)

A step that opens the memory in the `Background` removes both warnings, and each `When` step then only reads or clears it.

The steps of scenarios that run exactly the same code after the Background, as in `Adding.feature`, get a warning too, and it suggests a Scenario Outline in place of the Background:

```
Redundant step. 100% of the code in this step is repeated by the step at line 12. Consider a Scenario Outline for different values.
```

CucumberSwift compares function by function. A function that two scenarios run with exactly the same regions counts as redundant. A function that they run with different inputs does not, because each input runs different regions: `sum` with positive numbers and with negative numbers runs different branches.

A step gets a warning at 50% or more. Set `Cucumber.redundantStepWarningLevel` to another percentage, or to `.off`. The environment variable `CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL` takes a number from 0 to 100, or `NO`. These warnings are in the feature's `Redundancy` test, and they don't change the feature's redundancy.

Some repetition is deliberate, so the score leaves out 3 more kinds:

- A Scenario Outline's examples count as one scenario, so rows that run the same code with other values aren't redundant.
- A scenario tagged `@redundant` doesn't count. Use the tag for a scenario you keep on purpose, such as a test for a bug that came back.
- A scenario with no steps of its own after the Background has nothing to compare.

Set the redundancy's levels as <doc:Measuring-Code-Coverage#Set-the-levels> shows. Setting its warning level to `.off` also turns off the warnings on scenarios. The score is on whenever coverage is, and `Cucumber.redundancy = false` or `CUCUMBER_REDUNDANCY=NO` turns it off.

## Eliminate redundant scenarios

Set the redundancy's error level to 1% to make the XCTest runner fail every feature that has a redundant scenario, and raise the coverage levels with it. This strict mode suits a suite whose scenarios are slow, where each one must test code that no other one tests:

```swift
public func setupSteps() {
    Cucumber.coverageWarningLevel = 90
    Cucumber.coverageErrorLevel = 80
    Cucumber.redundancyErrorLevel = 1
    // Your steps
}
```

The warning level stays on in strict mode, because it also puts a warning on each scenario that adds no coverage of its own, which shows what to merge or remove. A Scenario Outline's examples and a scenario tagged `@redundant` still don't count as redundant, as <doc:#Which-scenarios-are-redundant> describes.

## Compare scenarios by what they check

The redundancy compares the scenarios by the mutants they fail on, as well as by the code they run, when mutation testing is on. <doc:Mutation-Testing> describes how to turn it on.

### Find redundant scenarios by what they check

The redundancy compares the scenarios by the mutants they fail on as well as by the code they run when mutation testing is on. A scenario is then redundant only when the other scenarios run all of its code and fail on every mutant it fails on. With mutation testing off, or with a report that is out of date, the redundancy compares them by code alone, as <doc:#Which-scenarios-are-redundant> describes.

In the sample's `Basket-killed.feature`, "Two items pay shipping" and "A total of exactly 100 pays shipping" run the same code. By code alone, the first is kept and the second is redundant:

```
    Share  Own regions      Time  Scenario
      19%            0     0.01s  Two items pay shipping (line 5)
      30%            3     0.00s  Three items get a discount (line 9)
      17%            1     0.01s  Checking out saves the basket (line 13)
      19%            0     0.01s  A total of exactly 100 pays shipping (line 18, adds no coverage of its own)
      15%            1     0.01s  An empty basket isn't saved (line 22)
```

Only the second fails when `>` becomes `>=`, and it also fails on every mutant that the first fails on. With mutation testing on, the second is kept and the first is redundant:

```
    Share  Own regions      Time  Scenario
      19%            0     0.01s  Two items pay shipping (line 5, adds nothing of its own)
      30%            3     0.01s  Three items get a discount (line 9)
      17%            1     0.01s  Checking out saves the basket (line 13)
      19%            0     0.00s  A total of exactly 100 pays shipping (line 18)
      15%            1     0.01s  An empty basket isn't saved (line 22)
```

The redundant scenario gets this warning:

```
Basket-killed.feature:5  Scenario adds nothing of its own: other scenarios run all the code it runs after the Background, and fail on every mutant it fails on. It took 0.01 s. Consider a Scenario Outline for other values, or remove it.
```

Xcode shows the warning on the scenario, and lists it under the feature's `Redundancy` test:

![The Basket-killed feature file in Xcode. The scenario "Two items pay shipping" has a warning that it adds nothing of its own, because other scenarios run all its code and fail on every mutant it fails on. Its steps, and the steps of "A total of exactly 100 pays shipping", have redundant-step warnings.](MutationTesting-Redundant.png)

Of two scenarios that run the same code, the one that fails on more mutants is kept. Between two that fail on the same mutants, the one that runs more code is kept, and then the first in the feature file.

### Combine two scenarios that each check something

Two scenarios can each have something that the other lacks. One runs more code, and the other fails on a mutant that the first misses. The sample's `Basket-overlap.feature`, also tagged `@after`, has two of them:

```gherkin
@after
Feature: Basket, with two scenarios that each check something the other misses
  10% off from 3 items, and free shipping over 100.

  Scenario: Checking out a basket of 100
    Given a basket with items costing 50 and 50
    When I check out
    Then the basket is saved
    And the total is at least 100

  Scenario: A basket of 100 pays shipping
    Given a basket with items costing 50 and 50
    Then the total is 105
```

The first runs the checkout code, which the second doesn't. Its check of the total is loose, so it still passes when the shipping rule changes, and only the second fails then. Neither is redundant, because removing either one loses something. Both count in the redundancy, because one scenario could do the work of both:

```
    Share  Own regions      Time  Scenario
      46%            2     0.01s  Checking out a basket of 100 (line 5, overlaps line 11)
      31%            0     0.01s  A basket of 100 pays shipping (line 11, overlaps line 5)
```

Each of the two gets a warning that names what the other one adds:

```
Basket-overlap.feature:5   Scenario overlaps the scenario at line 11. This scenario runs 2 regions that one doesn't. Only this one fails when ! at Basket.swift:26 is removed or true at Basket.swift:27 is changed to false. Only that one fails when > at Basket.swift:22 is changed to <=, > at Basket.swift:22 is changed to >= or discounted > 100 ? discounted : discounted + 5 at Basket.swift:22 is changed to discounted > 100 ? discounted + 5 : discounted. Combine the best of both into one scenario, or into a Scenario Outline for different values.
Basket-overlap.feature:11  Scenario overlaps the scenario at line 5. That scenario runs 2 regions this one doesn't. Only this one fails when > at Basket.swift:22 is changed to <=, > at Basket.swift:22 is changed to >= or discounted > 100 ? discounted : discounted + 5 at Basket.swift:22 is changed to discounted > 100 ? discounted + 5 : discounted. Only that one fails when ! at Basket.swift:26 is removed or true at Basket.swift:27 is changed to false. Combine the best of both into one scenario, or into a Scenario Outline for different values.
```

Xcode shows the two warnings on the scenarios, and the feature's redundancy and coverage warnings on its first line:

![The Basket-overlap feature file in Xcode. Each of its two scenarios has a warning that it overlaps the other: "Checking out a basket of 100" runs 2 regions the other doesn't, and only "A basket of 100 pays shipping" fails when the shipping rule changes. The feature's first line has a coverage warning and a redundancy warning.](MutationTesting-Overlap.png)

Checking that the total is 105 in the first scenario does the work of both, so the second can go. The time of the two scenarios doesn't count as wasted time, because neither can go until you combine them.
