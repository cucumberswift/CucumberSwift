"""A macOS test runner that runs the test bundle with `xcrun xctest`.

`rules_apple`'s macOS runner runs tests with `xcodebuild test-without-building`,
which needs the com.apple.testmanagerd service. This one runs the bundle
directly with Apple's `xctest` tool, so it works where that service is not
available, and XCTest activities, which CucumberSwift runs every step and hook
in, still work.

The test runs with the Xcode that Bazel selected for the build (`xcode_config`,
`--xcode_version`), as rules_apple's own runners do: XCODE_VERSION_OVERRIDE in
the test's environment makes Bazel set DEVELOPER_DIR to that Xcode, so `xcrun`
finds its `xctest` rather than the one `xcode-select` or the caller chose.
"""

load("@rules_apple//apple:providers.bzl", "apple_provider")

def _macos_xctest_runner_impl(ctx):
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    execution_requirements = dict(xcode_config.execution_info())
    execution_requirements["requires-darwin"] = ""
    execution_environment = {}
    xcode_version = str(xcode_config.xcode_version() or "")
    if xcode_version:
        execution_environment["XCODE_VERSION_OVERRIDE"] = xcode_version
    return [
        apple_provider.make_apple_test_runner_info(
            test_runner_template = ctx.file._test_template,
            execution_requirements = execution_requirements,
            execution_environment = execution_environment,
        ),
        DefaultInfo(),
    ]

macos_xctest_runner = rule(
    implementation = _macos_xctest_runner_impl,
    attrs = {
        "_test_template": attr.label(
            default = Label(":xctest_runner.template.sh"),
            allow_single_file = True,
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
    fragments = ["apple"],
    doc = "Runs a macos_unit_test's bundle with `xcrun xctest`. Pass it as the test's `runner`.",
)
