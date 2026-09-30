Feature: Async steps
Step definitions and hooks can be async. Steps still run one at a time, in the order written.

    Scenario: Async and sync steps run in the order written
        Given an async step that waits
        And a sync step
        When an async step awaits work on a background thread
        Then every async step ran on the main thread
        And the steps and the async hook ran in the order written
