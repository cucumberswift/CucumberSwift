"""Checks that macos_xctest_runner runs tests with the Xcode that Bazel selected.

The test is decided when Bazel analyses it: it reads the runner's
AppleTestRunnerInfo and compares it with the selected Xcode (xcode_config,
--xcode_version). It passes when the runner sets XCODE_VERSION_OVERRIDE to that
Xcode's version, which makes Bazel set DEVELOPER_DIR to it for the test, and
carries the Xcode's execution requirements.
"""

load("@rules_apple//apple:providers.bzl", "AppleTestRunnerInfo")

def _xctest_runner_info_test_impl(ctx):
    info = ctx.attr.runner[AppleTestRunnerInfo]
    environment = info.execution_environment or {}
    requirements = info.execution_requirements or {}
    xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    selected = str(xcode_config.xcode_version() or "")

    errors = []
    if not selected:
        errors.append("Bazel selected no Xcode, so there is nothing to check.")
    elif environment.get("XCODE_VERSION_OVERRIDE") != selected:
        errors.append("XCODE_VERSION_OVERRIDE is {}, not the selected Xcode's version {}.".format(
            repr(environment.get("XCODE_VERSION_OVERRIDE")),
            selected,
        ))
    for key in xcode_config.execution_info():
        if key not in requirements:
            errors.append("The execution requirements miss the selected Xcode's {}.".format(key))
    if "requires-darwin" not in requirements:
        errors.append("The execution requirements miss requires-darwin.")

    lines = ["#!/bin/bash"]
    if errors:
        lines += ["echo 'FAIL: {}' >&2".format(e.replace("'", "")) for e in errors]
        lines.append("exit 1")
    else:
        lines.append("echo 'The runner runs xctest with the selected Xcode, {}.'".format(selected))
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(script, "\n".join(lines) + "\n", is_executable = True)
    return [DefaultInfo(executable = script)]

xctest_runner_info_test = rule(
    implementation = _xctest_runner_info_test_impl,
    attrs = {
        "runner": attr.label(mandatory = True, providers = [AppleTestRunnerInfo]),
        "_xcode_config": attr.label(
            default = configuration_field(
                fragment = "apple",
                name = "xcode_config_label",
            ),
        ),
    },
    fragments = ["apple"],
    test = True,
)
