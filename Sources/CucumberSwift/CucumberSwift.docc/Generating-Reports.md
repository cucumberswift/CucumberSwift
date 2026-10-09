# Generating Reports

Reports are an important part of what Cucumber does, it allows us to see the specification in Gherkin executed. 

## Automatic Reports
CucumberSwift has a JSON reporter that writes in real-time while your code is executing. Unfortunately because the simulator is sandboxed it can be a tad tricky to get at that report.

To help you get started here's a script you can add as a post-action after running your tests in your Xcode scheme. It uses some XCode build variables to find the device you ran on, and get the Cucumber json file from it. This particular command can also pull reports off a physical device using the [ios-deploy](https://github.com/ios-control/ios-deploy) utility. 

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
By default the report is `_cucumberReport.json` in the documents folder, which on a Simulator is inside the Simulator. Set `Cucumber.reportPath` in `setupSteps()`, or the environment variable `CUCUMBER_REPORT_PATH`, to a full path to write it somewhere else. The static variable wins when both are set (see <doc:Settings>), and CucumberSwift creates the folder. A path under the Mac's home folder is the same one from the Mac and from every Simulator, which reads the Mac's home folder in its `SIMULATOR_HOST_HOME` environment variable.

A Simulator's test process doesn't get your shell's environment. Set the variable in the scheme's Test action, where `$(SRCROOT)/CucumberReports/report.json` writes beside your project, or give `xcodebuild` the same variable with a `TEST_RUNNER_` prefix:

```bash
TEST_RUNNER_CUCUMBER_REPORT_PATH="$HOME/CucumberReports/report.json" xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

### One report for a parallel run
With <doc:Running-Tests-In-Xcode#Parallel-testing> on, each worker is a process of its own, but they write one report. Each time a worker writes, it locks the report, reads it, adds its own features, writes the result to a temporary file in the same folder, moves that into place and unlocks. A feature whose scenarios ran in several workers has all of them, in the order of the feature file, and every scenario is in the report once.

- **Put the report where every worker reaches it.** On macOS and Mac Catalyst the default is already one file. On an iOS or tvOS Simulator, each clone has a documents folder of its own, so without `reportPath` there is one report in each clone, and the script above copies one of them. Set `reportPath` to a path on the Mac, as above, and the workers share one file.
- **A new run replaces the old report.** The first worker of a run empties the report the last run left, when nothing is writing it and it hasn't been written for a minute. Delete the report before a run that starts within a minute of another's.
- **The report's folder must be writable, and its lock files too.** The workers also create `<report>.lock` and `<report>.run` beside the report. They are empty, and safe to delete between runs.
- **A device runs one worker**, and writes its own file as before.
- **A serial run** writes the same report as ever.

## Verbose Output
To print each feature, scenario and step to the test log as it runs, see <doc:Verbose-Output>.

### Custom Reporters
If you'd like to be notified about what the Cucumber runner saw during execution there are 2 steps needed.

### The Test Observer
Start by creating a test observer, something like this:
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

Note the duration is a `Measurement` type, by default its value is in nanoseconds but you can convert that to whatever makes sense, like this:
<!-- swift-example: steps -->
```swift
duration.converted(to: .seconds).value // value in seconds
```

Next you'll want to add your reporter to a list of reporters Cucumber knows about by extending it, like this:
```swift
extension Cucumber: CucumberTestObservable {
    public var observers: [CucumberTestObserver] {
        [ MyTestObserver() ]
    }
}
```
