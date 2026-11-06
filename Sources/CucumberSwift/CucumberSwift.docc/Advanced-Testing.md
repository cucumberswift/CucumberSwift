# Advanced CucumberSwift testing

Measure how much code your scenarios run, how much they repeat each other, and whether they fail when the code is wrong.

## Overview

CucumberSwift measures your scenarios with two commands. The first runs your tests with code coverage, and the second runs mutation testing:

```bash
swift test --enable-code-coverage
swift run cucumberswift-mutation-test
```

Both build on your scenarios: feature files that describe how your app behaves, and step definitions that drive it. If you haven't written any yet, start with the tutorial in <doc:Tutorial-Table-of-Contents>, and see <doc:Matching-Steps> for how a step finds its step definition. The measures on this page show how good those scenarios are.

## Three pillars of effective testing

CucumberSwift measures your scenarios in three ways, and each one answers a different question:

| Score | Pillar | Question |
|---|---|---|
| Coverage | Scope | Which lines of code do the scenarios run? |
| Redundancy | Efficiency | Which scenarios duplicate existing coverage? |
| Mutation | Strength | Do the scenarios fail as they should when a bug is introduced in the code? |

The best scenario is strong and efficient. It fails on a mutant that no other scenario fails on, and it doesn't repeat what the other scenarios do. Coverage alone can't find that scenario, because a scenario can run code without checking what the code does.

Each pillar builds on the one before it. Coverage shows which code your scenarios reach, redundancy compares the scenarios by that code, and mutation testing checks the code they reach. Mutation testing depends on good coverage, because it tests only the code that your scenarios run.

## Measure scope with coverage

CucumberSwift measures the code that each scenario runs, and gives each feature a coverage score, as <doc:Measuring-Code-Coverage> describes. A feature at or below 80% gets a warning on its `Feature:` line, with the functions whose code no scenario ran.

## Measure efficiency with redundancy

CucumberSwift marks a scenario as redundant when the other scenarios run all the code it runs, as <doc:Finding-Redundant-Scenarios> describes. A redundant scenario costs time on every run and adds nothing, so you can merge it into a Scenario Outline or remove it. With mutation testing on, the redundancy also compares the scenarios by the mutants they fail on, so a scenario that runs the same code but checks it more closely is kept.

## Measure strength with mutation testing

The `cucumberswift-mutation-test` command changes your code in small ways and runs your scenarios against each change, as <doc:Mutation-Testing> describes. A scenario that still passes with the code changed doesn't check that code. With `Cucumber.mutationTesting` on, each feature gets a Mutation test that fails on such a change, and the redundancy compares the scenarios by the changes they detect.

## Topics

- <doc:Measuring-Code-Coverage>
- <doc:Finding-Redundant-Scenarios>
- <doc:Mutation-Testing>
