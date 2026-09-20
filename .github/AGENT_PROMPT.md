# Prompt: look around before you build

Contributors increasingly work with coding assistants. Paste this into yours before it starts on a
CucumberSwift issue — it makes the assistant go and find prior art before it creates anything.

```
Before writing any code or opening anything on cucumberswift/CucumberSwift, find out whether this
work already exists.

1. Pick 3-5 search terms, not just the words in the title. Include the symptom as a user would
   describe it, the API or type involved, and the file you expect to change. The same bug gets
   reported five different ways.

2. Search issues and pull requests in every state. Do not pass --state: omitting it searches open
   and closed together, which is what you want here. (gh rejects --state all.)

   gh search issues --repo cucumberswift/CucumberSwift "<term>" --limit 20 --json number,title,state,url
   gh search prs    --repo cucumberswift/CucumberSwift "<term>" --limit 20 --json number,title,state,url

3. Find out who has already touched the code you plan to change:

   gh search code --repo cucumberswift/CucumberSwift "<symbol>"
   git log --oneline -- <path/to/file>

4. For every related PR, work out how it ended:

   gh pr view <number> --repo cucumberswift/CucumberSwift --json state,mergedAt,title,url

   MERGED means it shipped. CLOSED with mergedAt null means it was closed without merging — someone
   decided against it. Read that thread before making the same case again. (An OPEN PR also has a
   null mergedAt, so check the state too.)

5. Report what you found, classified as: already shipped / open issue covers it / open PR covers
   it / closed unmerged and why / genuinely new. Then STOP. Do not file an issue, open a PR, or
   push a branch until a human has read that and told you to go ahead.

Two hard rules. Never push to a branch you do not own. And never open a second PR for work that
already has one without saying so — if an existing PR has gone stale that is a fair call to make,
so link it, explain why a fresh attempt is warranted, and suggest closing the old one. The failure
is a duplicate opened in ignorance, not the existence of a second attempt.
```
