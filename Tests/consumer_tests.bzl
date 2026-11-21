"""Runs a consumer test suite on macOS, and on iOS and watchOS simulators, and builds it for tvOS."""

load("@rules_apple//apple:ios.bzl", "ios_unit_test")
load("@rules_apple//apple:macos.bzl", "macos_unit_test")
load("@rules_apple//apple:resources.bzl", "apple_resource_group")
load("@rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@cucumberswift//bazel:swift_testing.bzl", "cucumberswift_testing_sources")
load("@rules_swift//swift:swift_library.bzl", "swift_library")

def consumer_tests(name, copts = []):
    """Defines `name` (macOS), `name_iOS`, `name_tvOS` and `name_watchOS` for the suite in the folder `name`.

    Args:
        name: the suite's folder, which is also its module name.
        copts: Swift compiler options for the suite.
    """

    # CucumberSwift looks for a Features folder at the root of the test bundle.
    apple_resource_group(
        name = name + "Features",
        strip_structured_resources_prefixes = [name],
        structured_resources = native.glob([name + "/Features/**"], allow_empty = True),
    )

    swift_library(
        name = name + "Lib",
        testonly = True,
        srcs = native.glob([name + "/*.swift"], exclude = [name + "/Package.swift"]),
        copts = copts,
        data = [":" + name + "Features"],
        module_name = name,
        deps = ["@cucumberswift//:CucumberSwift"],
    )

    # The lowest OS versions CucumberSwift supports, so the library is compiled for them too.
    # macOS runs the bundle with `xcrun xctest`, and watchOS with a watchOS simulator's xctest,
    # with the runner the cucumberswift module publishes (see bazel/xctest_runner.bzl). iOS keeps
    # rules_apple's runner, which runs the tests on a simulator.
    macos_unit_test(
        name = name,
        minimum_os_version = "10.15",
        runner = Label("//:macos_xctest_runner"),
        deps = [":" + name + "Lib"],
    )

    ios_unit_test(
        name = name + "_iOS",
        minimum_os_version = "13.0",
        deps = [":" + name + "Lib"],
    )

    # Built, never run: rules_apple's default tvOS runner fails every test without running it
    # (5.2.0). Tagged "tvos" so CI can leave it out: only nightly and manual runs build it, and
    # no run tests it (--test_tag_filters=-tvos). The tvOS tests run through Xcode and SwiftPM.
    tvos_unit_test(
        name = name + "_tvOS",
        minimum_os_version = "13.0",
        tags = ["tvos"],
        deps = [":" + name + "Lib"],
    )

    # Run with the cucumberswift module's runner, because rules_apple's default watchOS runner
    # fails every test without running it too. Tagged "watchos": CI neither builds nor runs it
    # (both tag filters), and the watchOS tests run through SwiftPM in CI.
    watchos_unit_test(
        name = name + "_watchOS",
        minimum_os_version = "7.4",
        runner = Label("@cucumberswift//bazel:watchos_xctest_runner"),
        tags = ["watchos"],
        deps = [":" + name + "Lib"],
    )

def swift_testing_consumer_tests(name, copts = []):
    """Like `consumer_tests`, for a suite that runs its feature files with the Swift Testing runner.

    Defines `name` (macOS), `name_iOS`, `name_tvOS` and `name_watchOS` for the suite in the folder `name`, at the
    lowest OS versions CucumberSwift supports, as `consumer_tests` does. The tests are generated from the
    feature files, as the CucumberSwiftTestingPlugin does in a Swift package, and the bundle is run by the same
    runners as the XCTest suites: `xctest` runs the Swift Testing tests of a bundle that links XCTest.

    Args:
        name: the suite's folder, which is also its module name.
        copts: Swift compiler options for the suite.
    """

    apple_resource_group(
        name = name + "Features",
        strip_structured_resources_prefixes = [name],
        structured_resources = native.glob([name + "/Features/**"]),
    )

    cucumberswift_testing_sources(
        name = name + "Generated",
        feature_files = native.glob([name + "/Features/**/*.feature"]),
        swift_srcs = native.glob([name + "/*.swift"]),
    )

    swift_library(
        name = name + "Lib",
        testonly = True,
        srcs = native.glob([name + "/*.swift"]) + [":" + name + "Generated"],
        copts = copts,
        data = [":" + name + "Features"],
        module_name = name,
        deps = ["@cucumberswift//:CucumberSwiftTesting"],
    )

    macos_unit_test(
        name = name,
        minimum_os_version = "10.15",
        runner = Label("//:macos_xctest_runner"),
        deps = [":" + name + "Lib"],
    )

    ios_unit_test(
        name = name + "_iOS",
        minimum_os_version = "13.0",
        deps = [":" + name + "Lib"],
    )

    tvos_unit_test(
        name = name + "_tvOS",
        minimum_os_version = "13.0",
        tags = ["tvos"],
        deps = [":" + name + "Lib"],
    )

    watchos_unit_test(
        name = name + "_watchOS",
        minimum_os_version = "7.4",
        runner = Label("@cucumberswift//bazel:watchos_xctest_runner"),
        tags = ["watchos"],
        deps = [":" + name + "Lib"],
    )
