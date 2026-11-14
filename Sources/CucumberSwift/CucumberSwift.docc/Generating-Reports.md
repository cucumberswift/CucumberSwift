# Generating reports

Write a Cucumber JSON report of each run, or receive the runner's events in your own code.

## Automatic reports

CucumberSwift writes a JSON report while your tests run. On a Simulator, the report is inside the Simulator's sandbox. To copy it into your project, add this script as a post-action of the Test action in your Xcode scheme. The script uses Xcode's build variables to find the device you ran on. On a physical device, it downloads the report with the [ios-deploy](https://github.com/ios-control/ios-deploy) tool.

```bash
#!/bin/bash -x
# set -x
# exec > /tmp/my_log_file.txt 2>&1
rm -f $SRCROOT/CucumberReports/ERROR.txt
mkdir -p $SRCROOT/CucumberReports
if [ "$TARGET_DEVICE_PLATFORM_NAME" == "iphonesimulator" ]; then
    find ~/Library/Developer/CoreSimulator/Devices/$TARGET_DEVICE_IDENTIFIER -name "CucumberTestResultsFor$TARGETNAME.json" -print0 | xargs -r -0 ls -1 -t | head -1 | xargs -I '{}' mv '{}' $SRCROOT/CucumberReports
elif [ -x "$(command -v ios-deploy)" ]; then
    ios-deploy --download=/Documents --bundle_id $PRODUCT_BUNDLE_IDENTIFIER.xctrunner --to "$SRCROOT/CucumberReports"
    cp "$SRCROOT/CucumberReports/Documents/CucumberTestResultsFor$TARGETNAME.json" "$SRCROOT/CucumberReports/CucumberTestResultsFor$TARGETNAME.json"
    rm -rf "$SRCROOT/CucumberReports/Documents/"
else
    echo "error: Unable to download CucumberSwift report from actual device, you need the ios-deploy tool installed! Install with 'brew install ios-deploy'" > $SRCROOT/CucumberReports/ERROR.txt
    exit 1
fi
```

### Choose where the report is written

Set `Cucumber.reportPath` in `setupSteps()`, or the environment variable `CUCUMBER_REPORT_PATH`, to a full path. CucumberSwift creates the folder. If both are set, the static variable wins (see <doc:Settings>). By default, the report is `_cucumberReport.json` in the documents folder. On a Simulator, that folder is inside the Simulator.

A path under the Mac's home folder works from the Mac and from every Simulator. Each Simulator finds the Mac's home folder in its `SIMULATOR_HOST_HOME` environment variable.

A Simulator's test process doesn't get your shell's environment. Set the variable in the scheme's Test action instead. There, `$(SRCROOT)/CucumberReports/report.json` writes the report next to your project. With `xcodebuild`, add the prefix `TEST_RUNNER_` to the variable's name:

```bash
TEST_RUNNER_CUCUMBER_REPORT_PATH="$HOME/CucumberReports/report.json" xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

### One report for each test run

Every process of a test run adds its scenarios to one report. A parallel run has a process for each worker (see <doc:Running-Scenarios-In-Parallel>). A run of several test targets has a process for each target, whichever runner it uses. So a `swift test` run of a package with an XCTest target and a Swift Testing target writes both targets' scenarios to the same report. Each scenario appears in it once. A feature whose scenarios ran in several processes lists all of them, in the order of the feature file.

To do this, a process locks the report each time it writes. It reads the report, adds its own features, and writes the result to a temporary file in the same folder. Then it moves that file into place and unlocks the report. A process writes when a scenario starts, when a scenario or a feature finishes, and when its tests start and finish. If a test crashes the process, the report has every scenario that finished and the scenario that crashed, without its steps.

A new run replaces the report. The first process of a run empties the report that the last run left. A process is the first of a new run when no other process is writing the report and one of these is true:

- The `swift test` or `xcodebuild` command that started the last run has finished. A process that one of these commands starts is part of that command's run for as long as the command runs, however long ago the report was written.
- The process runs a test bundle that already ran in this run with the same runner. Xcode and a Simulator don't tell a process which run started it, so this is how running the tests again replaces the report. It doesn't apply to the workers of a parallel run, which all run the same bundle.
- Nothing has written the report for 10 minutes.

A parallel run in Xcode, or on a Simulator, that starts sooner than that after another run adds to its report, because its workers look like the last run's. Delete the report first.

To change how long the report can go unwritten, set `Cucumber.reportStaleAfter` to a number of seconds in `setupSteps()`, or set the environment variable `CUCUMBER_REPORT_STALE_AFTER`. The static variable wins over the environment variable. A value that isn't a number above 0 is ignored. Both runners read it.

<!-- swift-example: steps -->
```swift
Cucumber.reportStaleAfter = 30 * 60 // 30 minutes
```

Choose a longer time when something slow runs between one test target ending and the next starting, such as a build or the start of your test infrastructure. Without it, the later target empties the report that the earlier target wrote. Choose a shorter time when you start parallel runs in Xcode close together, so that each new run replaces the report. A test process that is running protects its own run, so a long scenario never needs a longer time.

Keep these points in mind for the shared report:

- On an iOS or tvOS Simulator, set `reportPath` to a path under the Mac's home folder (see <doc:Generating-Reports#Choose-where-the-report-is-written>). Each Simulator clone, and each app on a Simulator, has its own documents folder. Without `reportPath`, each of them writes its own report, and the post-action script in <doc:Generating-Reports#Automatic-reports> copies only one of them. On macOS and Mac Catalyst, the default path is already one file.
- The report's folder must be writable. Every process also creates `<report>.lock` and `<report>.run` next to the report. You can delete them between runs.
- The copy in `CucumberTestResultsFor<target>.json` has the features of that test bundle, from the report as it was when the bundle's tests finished. A package that you run with `swift test` has one test bundle for all its targets, so its copy has the features of every target.
- We haven't tried a physical device. A device is expected to run one worker and write its own file.

### Swift Testing

The Swift Testing runner writes the same report to the same `Cucumber.reportPath` and `CUCUMBER_REPORT_PATH`, and takes the same custom reporters. See <doc:Running-Feature-Files-With-Swift-Testing#Reports-verbose-output-and-custom-reporters>. Swift Testing runs a test target's tests in one process. That process adds its scenarios to the run's report (see <doc:Generating-Reports#One-report-for-each-test-run>), in the order of the feature files. On an iOS or tvOS Simulator, the default folder is inside the Simulator, so set `reportPath` to a path under the Mac's home folder (see <doc:Generating-Reports#Choose-where-the-report-is-written>).

## Verbose output

To print each feature, scenario and step to the test log as it runs, see <doc:Verbose-Output>.

## Custom reporters

To receive the runner's events in your own code, write a test observer and add it to Cucumber's observers.

### Write a test observer

Create a class that conforms to `CucumberTestObserver`:

```swift
class MyTestObserver: CucumberTestObserver {
    func testSuiteStarted(at date: Date) { }

    func testSuiteFinished(at date: Date) { }

    func didStart(feature: Feature, at date: Date) { }

    func didStart(scenario: Scenario, at date: Date) { }

    func didStart(step: Step, at date: Date) { }

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) { }

    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) { }

    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) { }
}
```

Each `duration` is a `Measurement`, in nanoseconds by default. Convert it to the unit you need:

<!-- swift-example: steps -->
```swift
duration.converted(to: .seconds).value // value in seconds
```

### Add the observer

Extend `Cucumber` to conform to `CucumberTestObservable`, and return your observers:

```swift
extension Cucumber: CucumberTestObservable {
    public var observers: [CucumberTestObserver] {
        [ MyTestObserver() ]
    }
}
```
