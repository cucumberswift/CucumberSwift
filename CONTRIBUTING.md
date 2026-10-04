# Contributing to CucumberSwift

So you want to contribute to CucumberSwift? Cool! Bug reports, fixes, features, docs and reviews are all welcome.

It comes down to three things:

- **Be available for questions.** If there's confusion about what you wrote or why you wrote it that way, we need to be able to talk about it before it makes it into `main`.
- **Test your code.** It's a testing framework, so it really ought to be tested.
- **Open a pull request** once your change is in place and tested, and you know you'll be near your email for the next few days.

The rest of this page explains how each step works here, so your contribution lands quickly and nobody's time is wasted, yours included.

**Contents:** [Questions](#questions) · [Reporting a bug or requesting a feature](#reporting-a-bug-or-requesting-a-feature) · [Before you open a PR](#before-you-open-a-pr) · [Setting up](#setting-up) · [The Xcode project](#the-xcode-project) · [Making a change](#making-a-change) · [Pull request etiquette](#pull-request-etiquette) · [Review](#review) · [Using AI tools](#using-ai-tools)

## Questions

Ask usage questions in **#help** on [Slack](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw) or in [GitHub Discussions](https://github.com/cucumberswift/CucumberSwift/discussions), not in an issue.

Not sure whether the thing you're looking at is even a bug? Ask in **#contributors** on Slack, that's a good place to work it out before it becomes a bug report.

[![Slack](https://img.shields.io/badge/Slack-join%20the%20community-4A154B?style=popout&logo=slack&logoColor=white)](https://join.slack.com/t/cucumberswift/shared_invite/zt-4aj6p9txt-P5FpzOt7YVImZ5V4XtKJDw)

## Reporting a bug or requesting a feature

**Have a look around first.** Search the [issues](https://github.com/cucumberswift/CucumberSwift/issues?q=is%3Aissue) before filing a new one, and search the [pull requests](https://github.com/cucumberswift/CucumberSwift/pulls?q=is%3Apr) too. Look at the closed ones especially: it may already be fixed and shipped, or it may have been proposed and turned down, and that thread is worth reading before you make the same case again. If there's an open issue for it, add your details there, and a 👍 reaction on the issue helps us see how many people it affects. Two minutes of searching beats a lost weekend.

Then open an issue with the **Bug report** or **Feature request** template.

A good bug report has:

- The CucumberSwift version, the Xcode version, and the platform (iOS, macOS or tvOS, and the OS version).
- How you installed CucumberSwift: Swift Package Manager or Carthage.
- A minimal `.feature` file and the step definitions that reproduce the problem. This is the most useful thing you can give us.
- What you expected to happen and what happened instead, including the test output.

A good feature request starts with the problem you're trying to solve, not the solution. That way we can discuss the approach before anyone writes code.

**Security vulnerabilities are different.** Do not open a public issue. Follow [SECURITY.md](SECURITY.md) to report it privately.

## Before you open a PR

Link an issue. If there's already one covering what you're fixing or adding, mention it in your PR. If there isn't, open one first describing the problem or the enhancement.

This isn't process for the sake of process. A quick ticket means we can agree on direction before you spend an evening writing code, and it keeps the diagnosis searchable even when the fix that eventually lands isn't the one you started with.

Typos and docs fixes are exempt, just send the PR. They don't need an issue, a `Closes` line or an issue number in the title.

**One issue per PR.** Two bugs in one pull request isn't something we'll merge. Separate PRs mean each fix stands or falls on its own. Bundled, the one we're unsure about holds up the one we're happy with. Either can also be reverted later without unpicking the other. It also keeps each regression test tied to the issue it closes, so a year from now "what fixed this?" has one answer.

Found a second bug while you were in there? Brilliant. Open a second issue and say so in your PR. That's a contribution in its own right, and we'd far rather hear about it than not.

That's one *problem* per PR, not one file. A single logical change across a dozen files is still one change, and mechanical work of the same kind (a lint pass, a dependency bump, a batch of docs edits) can go in one PR.

**Check for work in progress.** If someone already has an open PR for the issue, a review or a comment on that PR is worth more than a second one. If you want to pick up an issue, say so in a comment, so two people don't fix the same thing.

Finding an existing attempt doesn't automatically mean stop. If it's gone stale, say so: link it, explain why you're starting fresh, and suggest closing the old one. What we want to avoid is a duplicate opened by accident, and anyone pushing to a branch that isn't theirs.

## Setting up

1. Fork the repository and clone your fork.
2. Create a branch for your change. Don't work on your fork's `main` branch. Keeping it as a clean copy of ours makes it easy to stay in sync and to work on more than one change at a time.
3. Open `CucumberSwift.xcodeproj` in Xcode.
4. Install [SwiftLint](https://github.com/realm/SwiftLint) (for example `brew install swiftlint`). The Xcode build runs it with the repository's `.swiftlint.yml`.
5. Only if you'll add, remove or rename files, or change targets or settings, set up Tuist as described in [The Xcode project](#the-xcode-project). Most changes don't need it.

## Running the tests

### With Xcode

```bash
xcodebuild test -scheme CucumberSwift -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO
```

This is the reference run. It builds every test target through the Xcode project that CI and Carthage use, on Mac Catalyst.

### With Swift Package Manager

CI also runs every test target with SwiftPM. Run all four packages:

```bash
swift test --enable-all-traits --skip 'CucumberSwift\.CucumberTest'
swift test --package-path Tests/CucumberSwiftConsumerTests
swift test --package-path Tests/CucumberSwiftDSLConsumerTests
swift test --package-path Tests/CucumberSwiftSwift6ConsumerTests
```

or, with [mise](https://mise.jdx.dev) installed and the repository trusted (steps 1 and 2 of [Setting up](#setting-up-1) under The Xcode project; the task needs no Tuist):

```bash
mise run test-swiftpm
```

**Why separate packages.** SwiftPM links all of a package's test targets into one test bundle. Each test target here declares its own `extension Cucumber: StepImplementation`, and only one of those can take effect in a bundle, so the others would silently run nothing. So each consumer test folder is a package of its own, and the root package holds only `CucumberSwiftTests`. The same rule applies to projects that use CucumberSwift: see "Running Tests with Swift Package Manager" in the documentation.

**The Swift 6 package has no Xcode target.** `Tests/CucumberSwiftSwift6ConsumerTests` builds its test target in the Swift 6 language mode, as a project that has moved to Swift 6 would, while CucumberSwift itself stays in the Swift 5 language mode. It checks that the setup in "Matching Steps" → "Swift 6 language mode" compiles and runs. If a change makes Swift 6 code stop compiling, this package fails to build.

**Why the root package turns on every trait.** The step definition macros, the `CucumberSwiftMacros` product, are behind the `Macros` package trait, so that projects which don't use them never download swift-syntax. `--enable-all-traits` builds them and runs their tests, `CucumberSwiftMacrosTests`. The consumer packages turn no trait on, as most projects that use CucumberSwift, so they check that everything still builds without it. Traits need Swift 6.1 or later; an earlier toolchain reads `Package.swift`, which has no macros, and runs the root package without `--enable-all-traits`.

**Why the root package skips `CucumberTest`.** `CucumberTest` is the run of `Tests/CucumberSwiftTests/Features`, whose steps have no step definitions, so each of those steps would fail. The Xcode test plan skips it too, and `--skip 'CucumberSwift\.CucumberTest'` does the same for SwiftPM.

**Comparing the counts with `xcodebuild`.** The consumer packages run the same tests as their Xcode bundles, and the root package the same as the `CucumberSwiftTests` bundle, apart from the tests that need UIKit, which `swift test` on macOS doesn't have.

Also worth knowing:

- **Each package builds separately**, in its own `.build` folder of about 300 MB, so the first run builds CucumberSwift four times.
- **The consumer packages have no committed `Package.resolved`** (it's in `.gitignore`). They resolve CucumberSwiftExpressions within `Package.swift`'s range, as a project that uses CucumberSwift does.
- **Keep `name: "CucumberSwift"`** in the consumer packages' `.package(name:path:)`. Without it, SwiftPM names the dependency after the checkout's folder, and the build fails in a worktree or a renamed clone.
- **`swift test --filter` can't select a scenario.** Scenarios become tests only when the suite runs, so `swift test list` shows none of them, and a filter for one runs nothing, successfully. Select scenarios by tag instead, for example `CUCUMBER_TAGS=smoke swift test`.
- **Don't use `swift test --parallel`.** It runs only the tests `swift test list` shows, so no scenario runs, and it still passes.
- **SwiftPM builds for macOS only.** iOS and Mac Catalyst behaviour still needs `xcodebuild`.
- **The generated step definitions are compiled.** `GeneratedStepDefinitions.swift` (in `CucumberSwiftTests`) and `GeneratedBareSlashStepDefinitions.swift` (in `CucumberSwiftConsumerTests`, which turns on bare slash regex literals) hold the stub generator's output: Cucumber expressions and `#/…/#` in the first, `/…/` in the second. `GeneratedStepDefinitionTests` fails when the generator's output changes and prints the new output to paste in.
- **There are two manifests.** Swift 6.1 and later read `Package@swift-6.1.swift`, which adds the macros; earlier toolchains read `Package.swift`. Make every other change to both. CI's "Manifests match their lockfiles" job checks both against `Package.resolved`. A swift-syntax pin there may be present or absent: toolchains disagree on whether to pin a dependency that only a trait uses (Swift 6.1 adds the pin, a plain resolve with Swift 6.2 removes it), so the check accepts either, and checks the pin against the manifest's range when there is one. Commit `Package.resolved` as a plain `swift package resolve` leaves it.
- **The localized macros are generated.** `Sources/CucumberSwiftMacros/LocalizedStepDefinitionMacros.swift` declares a macro for every localized step type in `Sources/CucumberSwift/Generated/I18n.swift`, such as `#ES_Dado`. `LocalizedStepDefinitionMacroTests` fails when the two differ; rewrite the file with `CUCUMBERSWIFT_WRITE_LOCALIZED_MACROS=1 swift test --traits Macros --filter LocalizedStepDefinitionMacroTests`.
- **A new consumer-style test target** needs its own package like the existing two, the same exclusions in `Project.swift` and `.swiftlint.yml`, and a line in CI's `SwiftPM tests` job and in the `test-swiftpm` task. New unit tests belong in `CucumberSwiftTests` and need none of that.

### With Bazel

CucumberSwift is also a Bazel module (`MODULE.bazel`, `BUILD.bazel`). Its tests with Bazel are in `Tests/`, a separate module (`Tests/MODULE.bazel`, `Tests/BUILD.bazel`) that depends on `cucumberswift` the way a Bazel project does. It runs the three consumer suites on macOS and on an iOS simulator. `REPO.bazel` and `.bazelignore` keep `Tests/` out of the root module, so `bazel build @cucumberswift//...` works for a consumer. With [Bazelisk](https://github.com/bazelbuild/bazelisk) installed (`brew install bazelisk`), which runs the Bazel version in `.bazelversion`, run from `Tests/`:

```bash
bazelisk test //...
```

Until CucumberSwiftExpressions is on the Bazel Central Registry, point Bazel at a copy of the release `MODULE.bazel` names, for example `--override_module=cucumberswift_expressions=../../CucumberSwiftExpressions` for a checkout of its tag.

CI's `Bazel tests` jobs run the same against a `git archive` of the commit, which is what the release's source archive contains, on the Bazel version in `.bazelversion`, and in the merge queue and on `main` also on Bazel 8, the oldest that `MODULE.bazel` allows. They fail if a suite runs fewer tests than `swift test` does.

- **A new source file needs no change**: `BUILD.bazel` globs `Sources`. A new dependency in `Package.swift` needs a `bazel_dep` in `MODULE.bazel` too.
- **A new consumer test suite** needs a `consumer_tests` line in `Tests/BUILD.bazel` and a floor in CI's `Check every feature ran` step.
- **Keep the CucumberSwiftExpressions versions in step.** CI fails if `MODULE.bazel`'s `bazel_dep` is older than the version `Package.swift` starts from.
- **`Tests/.bazelrc` runs the tests one at a time.** Each iOS suite needs a booted simulator, and booting several at once timed out in CI. The first run boots a new simulator, which can take a few minutes.
- **`MODULE.bazel.lock` and the `bazel-*` output folders are not committed** (they're in `.gitignore`).

### Fixtures

`Fixtures/` holds small projects that use CucumberSwift the way a project that depends on it would, from this checkout, to test what the packages above cannot: package traits, Tuist-generated projects, and a test target in the Swift 6 language mode. Each has a README that says what it proves. Run them all with:

```bash
mise run test-fixtures
```

CI runs them in the "Fixtures" job on `macos-26`, and the Swift package fixtures in the `SwiftPM tests` job too.

`Fixtures/CarthageXCFramework` is the exception. It uses the framework that Carthage builds from this checkout rather than the package, so `mise run test-fixtures` skips it. Run it with the following, which builds the framework with Carthage first; CI runs it in the Carthage build jobs:

```bash
mise run test-carthage
```

- **A fixture is a Swift package or a Tuist project.** A Swift package (`Package.swift`) is tested with `swift test`. A Tuist project (`Project.swift` and `Tuist.swift`) is generated with the Tuist version in `.mise.toml` and tested with `xcodebuild`; name the project and its scheme after the fixture's folder, which is how the task finds them.
- **Depend on CucumberSwift by path.** `.package(name: "CucumberSwift", path: "../..")` in a Swift package, `.package(path: "../..")` in a Tuist project.
- **Make it fail when the thing it tests breaks.** The Tuist fixture's step definitions only compile when the `Macros` trait reaches Xcode, as in Tuist's own fixtures.
- **Nothing generated is committed**: `.gitignore` covers each fixture's Xcode project, `Derived` folder, `.build` folder and `Package.resolved`. They are outside `Project.swift`'s globs, so they are not in CucumberSwift's Xcode project or in what Carthage builds.

Run the tests once before you change anything and note the numbers of tests, failures and skipped tests. Then you can compare after your change. A test that silently stops running still reports success.

## The Xcode project

**Don't edit `CucumberSwift.xcodeproj` by hand.** It's generated from `Project.swift` by [Tuist](https://tuist.dev), and CI fails a pull request whose committed project doesn't match what `Project.swift` generates. Change the manifest and regenerate instead.

### Why a generated project

A hand-edited `project.pbxproj` is hard to review, conflicts constantly, and adding a single source file takes several separate edits in the right places. Generating the project from a manifest avoids all of that, and it's a common approach: [XcodeGen](https://github.com/yonaskolb/XcodeGen) does it from a YAML spec, and [rules_xcodeproj](https://github.com/MobileNativeFoundation/rules_xcodeproj) (the successor to Google's Tulsi) does it for Bazel builds.

We use Tuist because its manifests are Swift, checked by the compiler and edited in Xcode with autocompletion, and it works well as a build tool for Xcode projects that use Swift Package Manager. The maintainers use Tuist and contribute to it. In practice this means:

- New source files are picked up automatically. `Project.swift` finds them by glob.
- A change to targets, settings or schemes is a readable Swift diff, not a `pbxproj` diff.
- Generation is reproducible, so CI can check that the committed project and the manifest agree.

### Do you need Tuist?

Only if your change adds, removes or renames a file, or changes a target, a build setting or a scheme. Editing existing files doesn't need it. Nobody who uses CucumberSwift needs Tuist, whether through Swift Package Manager or Carthage.

### Setting up

We pin the tool versions with [mise](https://mise.jdx.dev), a per-project tool version manager. `.mise.toml` says which version of Tuist this repository needs, much like `.nvmrc` does for Node. Tuist is pinned to an exact version and only changes in a pull request that updates it.

1. Install mise, for example with `brew install mise`. You need mise 2026.9.1 or later; `.mise.toml` checks this.
2. Trust the repository: `mise trust`. mise won't use a repository's `.mise.toml` until you do, because the file can set environment variables and define tasks that run commands. Read it first. Ours pins Tuist and defines three tasks, `generate`, `check-project` and `test-swiftpm`. Trust applies to that directory only.
3. Install the pinned Tuist: `mise install`. It downloads Tuist from its GitHub release and checks it against the release's published checksums.

You don't have to activate mise in your shell. The commands below all go through `mise run` or `mise exec`.

### Regenerating

```bash
mise run generate          # regenerate the project from Project.swift (tuist generate)
mise run check-project     # regenerate, and fail if the result differs from the project; CI runs this
mise exec -- tuist edit    # open Project.swift in Xcode with autocompletion
```

If your change adds, removes or renames a file, or touches `Project.swift`, run `mise run generate` and commit the regenerated `CucumberSwift.xcodeproj` with your change. A pull request whose project and manifest disagree fails CI.

To catch that before you push, turn on the pre-commit hook once in your clone:

```bash
git config core.hooksPath .githooks
```

It runs `mise run check-project`, but only when a commit touches the manifests or the project, or adds, removes or renames a file under `Sources` or `Tests`.

You don't need `tuist install`. The package dependencies use Xcode's own Swift Package Manager integration. `tuist generate` may still print "We detected outdated dependencies. Run 'tuist install'"; you can ignore it.

### Why the generated project is committed

Tuist could recreate the project, so committing it is a deliberate choice. Carthage clones this repository and runs `xcodebuild` against the shared schemes it finds in the checkout. It has no way to run a generator first, so a repository without a committed project fails for every Carthage user with "has no shared framework schemes".

### Things to keep in mind

- **Three scheme names are load bearing.** The CI and Release workflows run `CucumberSwift`, and Carthage builds it. Don't rename `CucumberSwift`, `CucumberSwiftConsumerTests` or `CucumberSwiftDSLConsumerTests`.
- **The framework carries CucumberSwiftExpressions' module.** CucumberSwift's API uses CucumberSwiftExpressions' types, so a target that imports CucumberSwift needs that module too, and Carthage delivers only the framework. The "Embed CucumberSwiftExpressions module" script in `Project.swift` copies the module into the framework's `Modules` folder. Don't remove it: `mise run test-carthage` fails without it.
- **`project.xcworkspace/xcshareddata/swiftpm/Package.resolved` is a lockfile for Carthage users.** It pins the CucumberSwiftExpressions version they get. Regenerating leaves it alone. If your diff changes it anyway, put it back unless updating that dependency is what your change is for.
- **Updating a dependency means both manifests and both lockfiles.** `Package.swift` has its own lockfile, `Package.resolved`. Raise the lower bound (`from:`) in each manifest that declares the dependency to the version you're moving to, run `swift package resolve`, run `mise run generate` and then `xcodebuild -resolvePackageDependencies -project CucumberSwift.xcodeproj`, and commit all of it. CI fails a pull request when a lower bound isn't the locked version, when a lockfile is stale, or when the two lockfiles pin a package differently, and its error says which file to fix.

### Troubleshooting

- **"Config files … are not trusted"**: run `mise trust` in the repository.
- **mise says it's too old for this repository**: update it, for example `brew upgrade mise`.
- **`mise run check-project` fails and you didn't mean to change the project**: run `mise run generate`, check the diff, and commit it if it's what you expect. If it isn't, ask on the pull request.

## Making a change

**Branch names.** We name branches after the issue type and number: `bugfix/<issue>-<short-name>`, `feature/<issue>-<short-name>` or `task/<issue>-<short-name>`, for example `bugfix/135-empty-regex`. It's not a hard rule for forks, but it helps.

**Tests.** Every change that affects behaviour needs tests.

- A bug fix has a test that fails without the fix and passes with it.
- Tests fail with `XCTFail` or an assertion, not a `print`.
- CucumberSwift is mostly black-box tested with feature files, and unit tests are welcome too. Please don't run a full Cucumber feature suite from inside a unit test. The framework drives its own runner, and nesting them causes side effects that are hard to trace.
- Think about the edge cases: empty or whitespace-only input, accented characters and other Unicode, `And` and `But` steps, tags, comments, data tables and doc strings.
- A failing step must never be reported as passing. Anything that could hide a failure is a serious bug.

**Platforms.** The minimum deployment targets are iOS 13, macOS 10.15 and tvOS 13.

- Swift regex literals need iOS 16, macOS 13 or tvOS 16 at runtime. Put them behind an `if #available` check, or use `NSRegularExpression`.
- Don't raise the deployment targets in a PR. That's a breaking change for users on older platforms, so open an issue to discuss it first.

**Public API.** A change to a `public` or `open` symbol should be additive. If it has to be breaking, say so on the issue before you write it. Be careful with new overloads: one can silently change which method existing code calls (see [#125](https://github.com/cucumberswift/CucumberSwift/issues/125)).

**Breaking changes need a migration note.** If users have to change something to upgrade, the issue body gets a `## Migration` section that says what to change, with an example. The release notes copy it under the issue's entry, and a release refuses to start while an issue labelled `breaking` has none. Any other issue can have one too, for example when an install channel goes away. Keep it to what users must do; the background belongs in the rest of the issue.

**New source files.** `Project.swift` picks up source files by glob, so you don't add them to the Xcode project by hand. Run `mise run generate` and commit the regenerated `CucumberSwift.xcodeproj` with your change. Carthage builds from that project, so a file missing there breaks Carthage users. See [The Xcode project](#the-xcode-project).

**Keep the diff focused.**

- Change only what the issue needs. No drive-by reformatting, renames or refactoring next to the fix. Open a separate issue for those.
- Don't commit local changes, such as Xcode project settings that only your machine needs (your signing team, for example).
- Follow the names and patterns of the code around your change.
- If something looks unnecessary, check the history before you remove it. It may be there for a reason.
- Add a short comment to explain a non-obvious algorithm.

**Documentation.** If users will notice your change, update the DocC catalog in `Sources/CucumberSwift/CucumberSwift.docc/` in the same PR. Please don't add new Markdown files to the repository. Notes, findings and design discussion belong on the issue, where the next person will look for them.

**Workflows.** If you change a GitHub Actions workflow, give every job an explicit `permissions:` block. Please don't add a new third-party action without discussing it on the issue first.

**Commit and PR titles.** Start the PR title with a prefix (`fix:`, `feat:`, `docs:`, `chore:` or `ci:`), describe the change in plain words, and end with the issue number (unless it's a typo or docs fix with no issue), for example:

```text
fix: stop compiling an empty regex on every DSL step execution (#135)
```

We squash-merge, so the PR title becomes the commit message on `main`. Your individual commits don't need to be perfect.

## Pull request etiquette

**Link exactly one issue.** Put `Closes #123` (or `Fixes #123`) in the PR description, so the issue closes when the PR merges. Typo and docs fixes without an issue are the only exception.

**Write a real description.** Say what problem the PR solves, how it solves it, and how you tested it. Explain anything a reviewer might find surprising. A PR with no description can't be reviewed, and we'll ask for one.

**Open a draft if it isn't ready.** A draft PR is a good way to get early feedback on an approach. Mark it ready for review when it is.

**Keep "Allow edits by maintainers" turned on.** We only use it for small fixes, such as a rebase, a lint fix or a typo. We won't replace your approach with a different one. If we think a different approach is better, we'll discuss it with you.

**Stay available.** Reply to review comments, and push fixes as new commits rather than rewriting history once review has started, so reviewers can see what changed. Mark a conversation resolved when you've dealt with it. If you can no longer finish the PR, just say so. That's fine, and if we pick it up we'll credit you.

**Respect other people's branches.** Don't push to a branch you didn't create. If you want to build on someone else's PR, comment on it, or open your own PR that links to it.

**Keep it up to date.** If `main` moves on and your branch has conflicts, merge or rebase onto `main`. Ask if you're not sure how.

**Nudge us if it goes quiet.** We're a small team. If you haven't heard back, a polite comment on the PR or a message in **#contributors** is welcome.

## Review

When you open a PR:

1. **CI runs** the tests, builds the package with Swift Package Manager, and builds the framework with Carthage. Please fix anything it reports.
2. **An AI reviewer ([CodeRabbit](https://www.coderabbit.ai/)) leaves a first-pass review**, usually within a few minutes. It only gives advice. It can't approve or block your PR, and its suggestions can be wrong. You don't have to address every AI comment. A maintainer will tell you which ones matter, and you're welcome to reply and disagree with one.
3. **A maintainer reviews it.** A PR needs a maintainer's approval and green CI before it can merge, and only maintainers merge.

Once it's approved, a maintainer squash-merges the PR, and the linked issue closes. Merging doesn't publish a release. Maintainers release separately, and your change ships in the next release.

If we build on your code, tests or reproduction in a different PR, we'll credit you with a `Co-authored-by:` trailer.

## Using AI tools

You're welcome to use AI tools to write code, tests or documentation. The standard is the same as for any other contribution, and you are responsible for the change:

- Read and understand every line before you open the PR, and be ready to explain it.
- Check that the change does what the issue asks and nothing more. AI tools tend to add extra "improvements".
- Run the tests yourself.

Maintainers may use AI tools when reviewing too, and will say so when an AI finding shapes a review.

## Code of conduct

Everyone taking part in this project is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
