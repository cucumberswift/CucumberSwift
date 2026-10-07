"""Runs a consumer test suite on macOS and on an iOS simulator."""

load("@rules_apple//apple:ios.bzl", "ios_unit_test")
load("@rules_apple//apple:macos.bzl", "macos_unit_test")
load("@rules_apple//apple:resources.bzl", "apple_resource_group")
load("@rules_swift//swift:swift_library.bzl", "swift_library")

def consumer_tests(name, copts = []):
    """Defines `name` (macOS) and `name_iOS` for the suite in the folder `name`.

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
    # macOS runs the bundle with `xcrun xctest` (see xctest_runner.bzl). iOS keeps
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
