### Contributing

Let's keep this short and sweet. So you want to contribute to CucumberSwift? Cool! There are 3 things required to do so:

- Be available for questions. If there's confusion about what you wrote or why you wrote it that way we need to be able to talk about it before it makes it into main.
- TEST YOUR CODE! CucumberSwift is primarily black-box tested, that's fine. Feel free to unit test as well, the point is the testing framework really ought to be tested.
- Submit a Pull Request. At this point you've got everything tested, your new feature or bug fix is in place and you know you'll be near your email for the next few days. Submit your PR and we'll get it turned around and into main ASAP


### Before you open a PR

Link an issue. If there's already one covering what you're fixing or adding, mention it in your PR. If there isn't, open one first describing the problem or the enhancement.

This isn't process for the sake of process. A quick ticket means we can agree on direction before you spend an evening writing code, and it keeps the diagnosis searchable even when the fix that eventually lands isn't the one you started with.

Typos and docs fixes are exempt, just send the PR.

One issue per PR. Two bugs in one pull request isn't something we'll merge. Separate PRs mean each fix stands or falls on its own — bundled, the one we're unsure about holds up the one we're happy with — and either can be reverted later without unpicking the other. It also keeps each regression test tied to the issue it closes, so a year from now "what fixed this?" has one answer.

Found a second bug while you were in there? Brilliant — open a second issue and say so in your PR. That's a contribution in its own right, and we'd far rather hear about it than not.

That's one *problem* per PR, not one file. A single logical change across a dozen files is still one change, and mechanical work of the same kind — a lint pass, a dependency bump, a batch of docs edits — can go in one PR.

Not sure whether the thing you're looking at is even a bug? Ask in **#contributors** on Slack, that's a good place to work it out before it becomes a bug report.

[![Slack](https://img.shields.io/badge/Slack-join%20the%20community-4A154B?style=popout&logo=slack&logoColor=white)](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw)

I realize this document is somewhat lacking in terms of process, for now I don't care. If we start seeing more contributors I'll think through more how this should work.
