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

### One report for a parallel run

All the workers write one report when scenarios run in parallel (see <doc:Running-Scenarios-In-Parallel>), even though each worker is a separate process. Each scenario appears in it once. A feature whose scenarios ran in several workers lists all of them, in the order of the feature file.

To do this, a worker locks the report each time it writes. It reads the report, adds its own features, and writes the result to a temporary file in the same folder. Then it moves that file into place and unlocks the report.

Keep these points in mind for the shared report:

- On an iOS or tvOS Simulator, set `reportPath` to a path on the Mac, as above. Each Simulator clone has its own documents folder. Without `reportPath`, each clone writes its own report, and the script above copies only one of them. On macOS and Mac Catalyst, the default path is already one file.
- A new run replaces the old report. The first worker of a run empties the report that the last run left, if nothing is writing it and nothing has written it for a minute. If you start a run within a minute of another, delete the report first.
- The report's folder must be writable. The workers also create `<report>.lock` and `<report>.run` next to the report. These files are empty, and you can delete them between runs.
- We haven't tried a physical device. A device is expected to run one worker and write its own file.
- A serial run writes the report in the same way as before.

### Swift Testing

The Swift Testing runner writes the same report to the same `Cucumber.reportPath` and `CUCUMBER_REPORT_PATH`, and takes the same custom reporters. See <doc:Running-Feature-Files-With-Swift-Testing#Reports-verbose-output-and-custom-reporters>. Swift Testing runs a test target's tests in one process. That process writes the report once, with every scenario in the order of the feature files. On an iOS or tvOS Simulator, the default folder is inside the Simulator, so set `reportPath` to a path on the Mac, as above.

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
