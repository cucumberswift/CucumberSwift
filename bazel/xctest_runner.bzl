"""Test runners that run the test bundle with Apple's `xctest` tool.

`macos_xctest_runner` runs a macOS bundle with `xcrun xctest`.
`watchos_xctest_runner` runs a watchOS bundle on a watchOS simulator that it
creates for the run and deletes afterwards, with the simulator's `xctest`.
rules_apple's own watchOS runner runs no tests, so the module publishes
`@cucumberswift//bazel:watchos_xctest_runner` for projects to use. CucumberSwift's
own Bazel tests in Tests/ use both runners.

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

def _xctest_runner_impl(ctx):
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    execution_requirements = dict(xcode_config.execution_info())
    execution_requirements["requires-darwin"] = ""
    execution_environment = {}
    xcode_version = str(xcode_config.xcode_version() or "")
    if xcode_version:
        execution_environment["XCODE_VERSION_OVERRIDE"] = xcode_version
    # rules_apple fills in the %(name)s values; this fills in the platform first.
    template = ctx.actions.declare_file(ctx.label.name + ".template.sh")
    ctx.actions.expand_template(
        template = ctx.file._test_template,
        output = template,
        substitutions = {"__PLATFORM__": ctx.attr._platform},
    )
    return [
        apple_provider.make_apple_test_runner_info(
            test_runner_template = template,
            execution_requirements = execution_requirements,
            execution_environment = execution_environment,
        ),
        DefaultInfo(),
    ]

def _runner_attrs(platform):
    return {
        "_platform": attr.string(default = platform),
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
    }

macos_xctest_runner = rule(
    implementation = _xctest_runner_impl,
    attrs = _runner_attrs("macos"),
    fragments = ["apple"],
    doc = "Runs a macos_unit_test's bundle with `xcrun xctest`. Pass it as the test's `runner`.",
)

watchos_xctest_runner = rule(
    implementation = _xctest_runner_impl,
    attrs = _runner_attrs("watchos"),
    fragments = ["apple"],
    doc = "Runs a watchos_unit_test's bundle on a new watchOS simulator. Pass it as the test's `runner`.",
)
