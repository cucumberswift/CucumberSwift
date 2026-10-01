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

## Verbose Output
To see each feature, scenario and step as it runs, with its result and duration, set the `CUCUMBER_VERBOSE` environment variable to `1` or `true` (in your scheme's Run → Arguments, or on the command line: `CUCUMBER_VERBOSE=1 swift test`). To turn it on from code, return `true` from `verbose` in your `StepImplementation`:

```swift
extension Cucumber: @retroactive StepImplementation {
    public var verbose: Bool { true }
}
```

Each line starts with `[CucumberSwift]`, and a failed step shows its message.

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
