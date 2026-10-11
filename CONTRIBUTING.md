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
6. Optionally, turn on the [checks before each commit](#checks-before-each-commit).

### Checks before each commit

The git hooks in `.githooks` run CI's quick checks before each commit and each push, so a problem shows up in seconds instead of after a CI run. They need [mise](https://mise.jdx.dev), set up as in [The Xcode project](#setting-up-1). Then turn them on once per clone:

```bash
git config core.hooksPath .githooks
```

The first commit installs the tools they run, at the versions `.mise.lint.toml` pins. In a git worktree, each branch runs its own copy of the hooks, even when the worktree's `core.hooksPath` names another checkout's `.githooks`; a branch from before a hook existed runs none.

Before each commit, on what the commit changes:

- [Trunk](https://trunk.io)'s `trunk check` runs actionlint (with ShellCheck) on the workflows, SwiftLint on Swift files, and `.github/scripts/check_lockfiles.py` when a manifest or lockfile changes. Only new problems in what you changed count, and SwiftLint warnings don't stop a commit, just as they don't fail the Xcode build.
- `mise run check-project`, when the commit could change the Xcode project (see [Regenerating](#regenerating)).
- The Python script tests, when a script in `.github/scripts` changes.

Before each push, Trunk checks every commit being pushed, and the Python script tests run. `git commit --no-verify` and `git push --no-verify` skip the hooks; CI runs the same checks anyway.

The tools' versions are pinned in `.mise.lint.toml`, which mise reads only when `MISE_ENV=lint`, as the hooks set it, so CI doesn't install them. Trunk's settings are in `.trunk/trunk.yaml`: the version of the Trunk CLI and its checksums, the linters, and `telemetry: off`, so it sends no usage data or error reports. Trunk installs no git hooks of its own.

## Running the tests

### With Xcode

```bash
xcodebuild test -scheme CucumberSwift -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO
```

This is the reference run. It builds every test target through the Xcode project that CI and Carthage use, on Mac Catalyst.

Experimental parallel testing has fixtures of their own, in `Tests/ParallelFixtures`: a project that uses CucumberSwift as a local Swift package, so `CucumberSwift.xcodeproj` doesn't change. It has an app, and for each platform family (iOS with Mac Catalyst, tvOS, and macOS) unit tests without a host app, unit tests hosted in the app, and UI tests. All of them run the same features. Each scheme turns parallel testing on, for example:

```bash
xcodebuild test -project Tests/ParallelFixtures/ParallelFixtures.xcodeproj -scheme ParallelHostedTestsMac -destination 'platform=macOS' -parallel-testing-worker-count 3
```

The schemes are `ParallelHostlessTests`, `ParallelHostedTests` and `ParallelUITests`, with `TV` or `Mac` at the end for tvOS or macOS. Each worker checks that a scenario's steps ran once each, in order. CI's `Parallel tests` jobs also check across the workers that every scenario ran exactly once and that more than one worker ran them. CI runs each combination with `.github/scripts/parallel-fixture.sh`, which you can run the same way, for example `PLATFORM=macOS KIND=Hostless .github/scripts/parallel-fixture.sh`. It passes `PARALLEL_TEST_RECORDS` to `xcodebuild`, and each run of a scenario writes a file in that folder named after the scenario, its worker's process and a UUID. To keep CI's load down, the jobs run only when the code, the fixtures, a package manifest or the workflow changes, never in the merge queue, and only after the macOS hostless combination has passed; the first failure cancels the rest. A pull request runs the hosted tests on each platform with Xcode 26. `main` runs every combination with Xcode 26, and the iOS and Mac Catalyst ones with Xcode 16.4 too. A nightly or manual run runs all of them whatever changed, and tvOS and macOS with Xcode 16.4 as well. UI tests on a Mac need automation mode, which macOS asks you to allow the first time. The fixtures have no Swift package, because `swift test` can't run scenarios in parallel.

A pull request's own CI runs only the hosted tests with Xcode 26, so a change to parallel testing needs a manual run of the CI workflow on its branch too. A manual run with no inputs runs everything, about 40 jobs, so narrow it to the combinations the change concerns. `parallel_platforms` takes `all` or a comma-separated list of `iOS`, `tvOS`, `macOS` and `Catalyst`; `parallel_kinds` takes `all` or a list of `hostless`, `hosted` and `UI`; `parallel_xcode` takes `all`, `16` or `26`. `parallel_only=true` skips every job but the parallel tests, which the pull request's CI already ran, and they report as skipped. For a change that concerns only the UI tests on a Mac:

```bash
gh workflow run CI.yml --ref <branch> -f parallel_platforms=macOS,Catalyst -f parallel_kinds=UI -f parallel_only=true
```

The macOS hostless combination with Xcode 26 runs first only when the inputs include it. An unknown platform or kind fails the run's `Changed files` job, which names it, and no parallel tests run. Other runs share CI's macOS runners, so check that no other manual run is in progress first (`gh run list --workflow CI.yml --event workflow_dispatch`).

Generate the fixtures' project with `mise run generate-fixtures` before you open or run it, and again after changing `Tests/ParallelFixtures/Project.swift` or adding a file there. Unlike `CucumberSwift.xcodeproj` it is not committed: Tuist names the local package's folder after your checkout's folder, so the project differs from clone to clone. CI generates it the same way.

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

**Why the converter's tests run it as a program.** `CucumberSwiftMacroConverterTests` runs `CucumberSwiftMacroConverterTool --stdin` on source strings, instead of linking the converter. SwiftPM links every test target into one bundle, and a regular target that depends on swift-syntax next to the macros' tests makes them crash with Swift 6.2, whose prebuilt swift-syntax then mixes with the one built from source. The macros' own executable target avoids that, and so does a tool that is only run. Keep swift-syntax out of every target the test bundle links, apart from `CucumberSwiftMacrosPlugin`. With Swift 6.2 or later, the converter tool's own use of swift-syntax still makes `swift test --enable-all-traits` fail to link the macros' plugin, for the same reason: add `--disable-experimental-prebuilts` (and delete `.build` after changing the flag, which leaves objects that don't link). CI's SwiftPM job uses Swift 6.1, which has no prebuilts. The converter shares `StepPattern.swift`, `RegexLiteralPattern.swift` and `LocalizedStepDefinitionNames.swift` with the macros and the lint tool through symlinks, so it gives a converted closure the arguments the macro reads.

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
- **There are two manifests.** Swift 6.1 and later (Xcode 16.3 and later) read `Package@swift-6.1.swift`, which adds the macros. Only Swift 6.0 (Xcode 16.0 to 16.2) reads `Package.swift`: its `swift-tools-version:6.0` is the oldest Xcode CI builds with, and toolchains before it don't resolve this version of CucumberSwift at all. Both set the Swift 5 language mode. Make every other change to both. CI builds `Package.swift` with Xcode 16.0 in its nightly and manual runs. CI's `Project checks` job checks both against `Package.resolved`, which must pin swift-syntax within `Package@swift-6.1.swift`'s range. CI's release build, `swift build --force-resolved-versions` with Swift 6.1, fails without that pin. Toolchains disagree on whether to pin a dependency that only a trait uses: Swift 6.1 adds the pin, but with Swift 6.2 and later a plain `swift package resolve` that re-resolves anything drops it. So with Swift 6.2 or later, resolve with `swift package --enable-all-traits resolve`, which keeps it. If the pin is already gone, `swift package --enable-all-traits update swift-syntax` puts it back.
- **The localized macros are generated.** `Sources/CucumberSwiftMacros/LocalizedStepDefinitionMacros.swift` declares a macro for every localized step type in `Sources/CucumberSwift/Generated/I18n.swift`, such as `#ES_Dado`. `LocalizedStepDefinitionMacroTests` fails when the two differ; rewrite the file with `CUCUMBERSWIFT_WRITE_LOCALIZED_MACROS=1 swift test --traits Macros --filter LocalizedStepDefinitionMacroTests`.
- **So are the lint tool's localized names.** The lint tool can't link CucumberSwift, so `Sources/CucumberSwiftLintTool/LocalizedStepDefinitionNames.swift` lists every localized step type in `I18n.swift`, which the tool finds as a step definition and as a macro, `ES_Dado(…)` and `#ES_Dado(…)`. `LocalizedStepDefinitionNameTests` fails when the two differ; rewrite the file with `CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_NAMES=1 swift test --filter LocalizedStepDefinitionNameTests`.
- **The Gherkin parser is compiled twice.** `Sources/CucumberSwift/Gherkin/Core` is part of CucumberSwift, and the `CucumberSwiftGherkin` target compiles it again, through the `Sources/CucumberSwiftGherkin/Core` symlink, for build tools, which can't link XCTest. So code in that folder may use only Foundation and the other files in it; `swift build` fails otherwise. Tools read feature files through `FeatureFile`, or line by line with `FeatureFile.Keywords`, as the lint tool does, and `ParserParityTests` checks that it reads every feature file under `Tests/` as CucumberSwift does, down to the step definitions it suggests.
- **Two more files are shared by symlink.** `Sources/CucumberSwiftTestingMacros/StepDefinitionMacros.swift` is CucumberSwiftMacros' declarations, which return the step types of whichever runner the module's `Exports.swift` re-exports. `Plugins/CucumberSwiftTestingPlugin/ExpandFolders.swift` is the lint plugin's, because plugins can't share a library. Edit the originals.
- **The Swift Testing runner is tested in three places.** `CucumberSwiftTestingTests` runs single scenarios through the runner, `CucumberSwiftTestingGeneratorTests` checks the generated source, and the fixtures run feature files as a project would: `SwiftTestingPackage` from a Swift package, and `SwiftTestingAndXCTestTuist` and `SwiftTestingAndXCTestMacrosTuist` from an iOS app whose UI tests stay on CucumberSwift and XCTest while its unit tests use Swift Testing. The two Tuist fixtures are the same app, with step definitions written with the plain DSL and with the macros; the macros one links to the other's `App/BasketApp.swift` and `UITests/BasketUI.swift`, so that only the step definitions differ. The macros one also depends on a local package, `MacrosTrait`, which only turns the `Macros` trait on in its own manifest, so it also runs before Xcode 26.4; its test targets link the macros from CucumberSwift itself.
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
- **Keep the CucumberSwiftExpressions versions in step.** `MODULE.bazel`'s `bazel_dep` must be the version `Package.swift` starts from, so Bazel builds against what the SwiftPM and Xcode jobs test. CI's `Project checks` job fails otherwise, and so does its check that `Tests/MODULE.bazel` depends on the same versions as `MODULE.bazel` for the modules both use.
- **`Tests/.bazelrc` runs the tests one at a time.** Each iOS suite needs a booted simulator, and booting several at once timed out in CI. The first run boots a new simulator, which can take a few minutes.
- **`MODULE.bazel.lock` and the `bazel-*` output folders are not committed** (they're in `.gitignore`).

### Fixtures

`Fixtures/` holds small projects that use CucumberSwift the way a project that depends on it would, from this checkout, to test what the packages above cannot: package traits, Tuist-generated projects, and a test target in the Swift 6 language mode. Each has a README that says what it proves. Run them all with:

```bash
mise run test-fixtures
```

CI runs them in the `Fixture tests` job on `macos-26`, and the Swift package fixtures in the `SwiftPM tests` job too.

`Fixtures/CarthageXCFramework` is the exception. It uses the framework that Carthage builds from this checkout rather than the package, so `mise run test-fixtures` skips it. Run it with the following, which builds the framework with Carthage first; CI runs it in the `Carthage tests` jobs:

```bash
mise run test-carthage
```

It builds and tests with the selected Xcode. The pinned Tuist can't read the fixture's manifest with Xcode 16.0, so to test an older Xcode, set `TUIST_DEVELOPER_DIR` to a newer one's `Contents/Developer` folder, and the task generates the fixture's project with that. CI does this in `Carthage tests (Xcode 16)`.

- **A fixture is a Swift package or a Tuist project.** A Swift package (`Package.swift`) is tested with `swift test`. A Tuist project (`Project.swift` and `Tuist.swift`) is generated with the Tuist version in `.mise.toml` and tested with `xcodebuild`; name the project and its scheme after the fixture's folder, which is how the task finds them. It runs on macOS, unless the fixture has an `xcodebuild-destination` file with another `-destination`, such as `platform=iOS Simulator,name=iPhone 17`. A fixture that checks the oldest Xcode a feature needs has an `xcode-version` file, such as `26.4`: the task runs it with `/Applications/Xcode_26.4.app`, the name GitHub's runner images use. In CI that Xcode must be there; on your Mac the task warns and uses the selected Xcode.
- **Depend on CucumberSwift by path.** `.package(name: "CucumberSwift", path: "../..")` in a Swift package, `.package(path: "../..")` in a Tuist project.
- **Apply the plugins a project would.** Every test target applies `CucumberSwiftLint`, and a Swift Testing target also `CucumberSwiftTestingPlugin`. Each test target, other than `StepDefinitionMacrosPackage`'s (below), has a `LintCheck.feature` with one misspelt keyword, and the fixture's `expected-warnings` lists the warning it must cause. The plugin only warns, so `mise run test-fixtures` fails when a listed warning is missing from the build output: that is how a fixture shows that the plugin's warnings reach the build. The task also fails when the plugin made no stamp file, which shows it didn't run.
- **No warnings from CucumberSwift, other than the expected ones.** `mise run test-fixtures` fails on any warning from CucumberSwift that a fixture's `expected-warnings` doesn't list: CucumberSwiftLint's, one in a macro's expansion, one in the library, the plugins or the tools, and SwiftPM's about the package. `.github/scripts/fixture-warnings.sh` says how it tells them from the fixture's own warnings. CI's other fixture runs use the same script.
- **`StepDefinitionMacrosPackage` uses every feature together**, as a project does: the lint plugin, macros and plain step definitions, localized ones too, a commented-out step definition, and feature files in English and Spanish with tables, doc strings and outlines. It has no `LintCheck.feature`, so it must build with no warnings from CucumberSwift at all, and the task runs Fix Feature Files on it, which must change nothing. The task then runs Convert to Gherkin Macros on it: the command's report must have each line of its `expected-conversion`, and its tests must pass again on the converted step definitions, before the task puts its Swift files back. A pull request that adds a user-facing feature also uses it in this fixture.
- **`BrokenFeaturesPackage` is broken on purpose.** Its feature files have a misspelt keyword, an undefined step, an uneven table and an unsupported language, run by both runners. Its tests must fail, with every failure in its `expected-failures` and every warning in its `expected-warnings`. When CucumberSwift's messages change, update the expectations, not the feature files.
- **Make it fail when the thing it tests breaks.** The Tuist fixture's step definitions only compile when the `Macros` trait reaches Xcode, as in Tuist's own fixtures.
- **Nothing generated is committed**: `.gitignore` covers each fixture's Xcode project, `Derived` folder, `.build` folder and `Package.resolved`. They are outside `Project.swift`'s globs, so they are not in CucumberSwift's Xcode project or in what Carthage builds.
- **The checkout's own `Package.resolved` stays as it is.** Xcode's package resolution of a project that depends on this checkout by path writes the checkout's `Package.resolved` for the traits that project enables, so without the `Macros` trait, or with an Xcode before 26.4, it drops the swift-syntax pin. `.github/scripts/keep-package-resolved.sh` puts the file back after each `tuist generate` and `xcodebuild test` of a Tuist fixture, after `mise run generate-fixtures` and after `.github/scripts/parallel-fixture.sh`; use it for any new step that resolves such a project. Building a [CucumberSwiftSample](https://github.com/cucumberswift/CucumberSwiftSample) project against your checkout with `CUCUMBER_SWIFT_PATH` does the same, so afterwards run `git checkout Package.resolved` here.

### The documentation's examples

Every Swift example in the DocC catalog compiles against the code in the same commit: each ` ```swift ` block in an article, and each Swift file under its `Resources` folder that a tutorial shows. Compile them with Swift 6.1 or later:

```bash
mise run test-docs-examples
```

or `python3 .github/scripts/docs_examples.py`, which `--list` makes list each example and how it compiles. CI runs it in the `SwiftPM tests` job, with Xcode 16.3, whenever a pull request changes the code or the catalog, so a PR that only edits an article runs that one step. A target of its own is made for each block, named after its article and the line of its fence, in `.build/documentation-examples`, so an error names the example it's in.

- **A block is a whole Swift file**, unless the line before its fence has a marker, such as `<!-- swift-example: steps -->` for statements written inside `setupSteps()`, or `members` for members of `extension Cucumber: StepImplementation`. A `Package.swift` is found without one. DocC leaves the marker out of the page. The script's header lists the kinds and options, such as `swift6` and `bare-slash-regex`.
- **The reader's own code is stubbed** in `Tests/DocumentationExamples`, for example `basket`. A new example that uses a new name needs a stub there.
- **A block that can't compile on its own is a fragment**: `<!-- swift-example: fragment: <reason> -->`, and its article and reason go in `FRAGMENTS` in the script too, or the script fails. Keep fragments rare: today they're a Tuist manifest and two examples that need UIKit.

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
2. Trust the repository: `mise trust`. mise won't use a repository's `.mise.toml` until you do, because the file can set environment variables and define tasks that run commands. Read it first. Ours pins Tuist and defines tasks that generate and check the Xcode project and run the tests; `mise tasks ls` lists them. `.mise.lint.toml` pins the linters the git hooks run (see [Checks before each commit](#checks-before-each-commit)). Trust applies to that directory only.
3. Install the pinned Tuist: `mise install`. It downloads Tuist from its GitHub release and checks it against the release's published checksums.

You don't have to activate mise in your shell. The commands below all go through `mise run` or `mise exec`.

### Regenerating

```bash
mise run generate          # regenerate the project from Project.swift (tuist generate)
mise run check-project     # regenerate, and fail if the result differs from the project; CI runs this
mise exec -- tuist edit    # open Project.swift in Xcode with autocompletion
```

If your change adds, removes or renames a file, or touches `Project.swift`, run `mise run generate` and commit the regenerated `CucumberSwift.xcodeproj` with your change. A pull request whose project and manifest disagree fails CI.

To catch that before you push, turn on the [checks before each commit](#checks-before-each-commit). The pre-commit hook runs `mise run check-project` when a commit touches the manifests or the project, or adds, removes or renames a file under `Sources` or `Tests`.

You don't need `tuist install`. The package dependencies use Xcode's own Swift Package Manager integration. `tuist generate` may still print "We detected outdated dependencies. Run 'tuist install'"; you can ignore it.

### Why the generated project is committed

Tuist could recreate the project, so committing it is a deliberate choice. Carthage clones this repository and runs `xcodebuild` against the shared schemes it finds in the checkout. It has no way to run a generator first, so a repository without a committed project fails for every Carthage user with "has no shared framework schemes".

### Things to keep in mind

- **Three scheme names are load bearing.** The CI and Release workflows run `CucumberSwift`, and Carthage builds it. Don't rename `CucumberSwift`, `CucumberSwiftConsumerTests` or `CucumberSwiftDSLConsumerTests`. CI's `Parallel tests` jobs run the fixtures' schemes by name too.
- **The framework carries CucumberSwiftExpressions' module.** CucumberSwift's API uses CucumberSwiftExpressions' types, so a target that imports CucumberSwift needs that module too, and Carthage delivers only the framework. The "Embed CucumberSwiftExpressions module" script in `Project.swift` copies the module into the framework's `Modules` folder. Don't remove it: `mise run test-carthage` fails without it.
- **`project.xcworkspace/xcshareddata/swiftpm/Package.resolved` is a lockfile for Carthage users.** It pins the CucumberSwiftExpressions version they get. Regenerating leaves it alone. If your diff changes it anyway, put it back unless updating that dependency is what your change is for.
- **Updating a dependency means both manifests and both lockfiles.** `Package.swift` has its own lockfile, `Package.resolved`. Raise the lower bound (`from:`) in each manifest that declares the dependency to the version you're moving to, run `swift package resolve` (with Swift 6.2 or later, `swift package --enable-all-traits resolve`; see "There are two manifests" under [With Swift Package Manager](#with-swift-package-manager)), run `mise run generate` and then `xcodebuild -resolvePackageDependencies -project CucumberSwift.xcodeproj`, and commit all of it. For CucumberSwiftExpressions, set the same version in `MODULE.bazel` too. CI fails a pull request when a lower bound isn't the locked version, when a lockfile is stale, when the two lockfiles pin a package differently, or when `MODULE.bazel` disagrees with `Package.swift`, and its error says which file to fix.

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

**Toolchain.** CucumberSwift builds with Xcode 16.0 (Swift 6.0) or later: the oldest Xcode CI runs, on its macOS 15 runners. Its other runners use macOS 26. Code that `Package.swift` or the Xcode project builds may use anything Swift 6.0 has, and nothing newer without a `#if compiler(>=…)` check. The macros and the Swift Testing runner, which only `Package@swift-6.1.swift` builds, need Swift 6.1. When GitHub's runner images drop the oldest Xcode, the floor rises with the next release, which says so in its notes.

**Public API.** A change to a `public` or `open` symbol should be additive. If it has to be breaking, say so on the issue before you write it. Be careful with new overloads: one can silently change which method existing code calls (see [#125](https://github.com/cucumberswift/CucumberSwift/issues/125)).

**Breaking changes need a migration note.** If users have to change something to upgrade, the issue body gets a `## Migration` section that says what to change, with an example. The release notes copy it under the issue's entry, and a release refuses to start while an issue labelled `breaking` has none. Any other issue can have one too, for example when an install channel goes away. Keep it to what users must do; the background belongs in the rest of the issue.

**New source files.** `Project.swift` picks up source files by glob, so you don't add them to the Xcode project by hand. Run `mise run generate` and commit the regenerated `CucumberSwift.xcodeproj` with your change. Carthage builds from that project, so a file missing there breaks Carthage users. See [The Xcode project](#the-xcode-project).

**Keep the diff focused.**

- Change only what the issue needs. No drive-by reformatting, renames or refactoring next to the fix. Open a separate issue for those.
- Don't commit local changes, such as Xcode project settings that only your machine needs (your signing team, for example).
- Follow the names and patterns of the code around your change.
- If something looks unnecessary, check the history before you remove it. It may be there for a reason.
- Add a short comment to explain a non-obvious algorithm.

**Documentation.** If users will notice your change, update the DocC catalog in `Sources/CucumberSwift/CucumberSwift.docc/` in the same PR. Its Swift examples must compile: see [The documentation's examples](#the-documentations-examples). Please don't add new Markdown files to the repository. Notes, findings and design discussion belong on the issue, where the next person will look for them.

**Samples.** [CucumberSwiftSample](https://cucumberswift.org/CucumberSwiftSample/documentation/cucumberswiftsample/) documents the working sample projects in [its repository](https://github.com/cucumberswift/CucumberSwiftSample), tested every night against the latest release and against `main`. If your PR adds or changes something users see, add or update a sample there, or open an issue there for one and link it from your PR. Its [CONTRIBUTING](https://github.com/cucumberswift/CucumberSwiftSample/blob/main/CONTRIBUTING.md#adding-a-sample) says how to add a sample.

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

1. **CI runs** the tests, builds the package with Swift Package Manager, and builds the framework with Carthage. Please fix anything it reports. A pull request runs each check on the newest Xcode; the merge queue also runs the older Xcode and Bazel versions before the change merges.
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
