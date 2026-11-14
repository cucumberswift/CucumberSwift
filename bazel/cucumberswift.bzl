"""Runs CucumberSwift's plugins in a Bazel project, as commands of the cucumberswift tool.

SwiftPM and Xcode run the plugins as plugins. Bazel has no plugins, so these rules run the same commands of
`@cucumberswift//cli:cucumberswift`:

    load("@cucumberswift//bazel:cucumberswift.bzl", "cucumberswift_fix_feature_files", "cucumberswift_generate", "cucumberswift_lint")

    # Checks feature files and step definitions as the CucumberSwiftLint plugin does: `bazel build :lint`
    # prints each problem as a warning, and fails on an error.
    cucumberswift_lint(
        name = "lint",
        feature_files = glob(["Features/**/*.feature"]),
        swift_srcs = glob(["*.swift"]),
    )

    # Fixes misspelt keywords as the Fix Feature Files plugin does: `bazel run :fix_feature_files`.
    cucumberswift_fix_feature_files(
        name = "fix_feature_files",
        paths = ["Features"],
    )

    # Writes the Swift Testing tests of feature files as the CucumberSwiftTestingPlugin does.
    cucumberswift_generate(
        name = "FeaturesTests_generated",
        feature_files = glob(["Features/**/*.feature"]),
        swift_srcs = glob(["*.swift"]),
    )
"""

_CLI = Label("//cli:cucumberswift")

def _cucumberswift_lint_impl(ctx):
    stamp = ctx.actions.declare_file(ctx.label.name + ".lint-stamp")
    args = ctx.actions.args()
    args.add("lint")
    args.add("--stamp", stamp)
    args.add("--features")
    args.add_all(ctx.files.feature_files)
    args.add("--step-definitions")
    args.add_all(ctx.files.swift_srcs)
    ctx.actions.run(
        outputs = [stamp],
        inputs = ctx.files.feature_files + ctx.files.swift_srcs,
        executable = ctx.executable._cli,
        arguments = [args],
        mnemonic = "CucumberSwiftLint",
        progress_message = "Checking the feature files of %{label}",
    )
    return [DefaultInfo(files = depset([stamp]))]

cucumberswift_lint = rule(
    implementation = _cucumberswift_lint_impl,
    attrs = {
        "feature_files": attr.label_list(
            allow_files = [".feature"],
            doc = "The feature files to check.",
        ),
        "swift_srcs": attr.label_list(
            allow_files = [".swift"],
            doc = "The Swift files with the step definitions, which the check compares the steps with.",
        ),
        "_cli": attr.label(
            default = _CLI,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Runs `cucumberswift lint`, the CucumberSwiftLint plugin's check. Bazel shows each warning, and the build fails on an error.",
)

def _cucumberswift_generate_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".swift")
    args = ctx.actions.args()
    args.add("generate")
    args.add("--output", output)
    args.add_all(ctx.files.feature_files)
    for swift_src in ctx.files.swift_srcs:
        args.add("--swift", swift_src)
    ctx.actions.run(
        outputs = [output],
        inputs = ctx.files.feature_files + ctx.files.swift_srcs,
        executable = ctx.executable._cli,
        arguments = [args],
        mnemonic = "CucumberSwiftGenerate",
        progress_message = "Generating Swift Testing tests for the feature files of %{label}",
    )
    return [DefaultInfo(files = depset([output]))]

cucumberswift_generate = rule(
    implementation = _cucumberswift_generate_impl,
    attrs = {
        "feature_files": attr.label_list(
            allow_files = [".feature"],
            doc = "The feature files to write tests for.",
        ),
        "swift_srcs": attr.label_list(
            allow_files = [".swift"],
            doc = "The test target's Swift files, which the command reads to find features written in the Swift DSL.",
        ),
        "_cli": attr.label(
            default = _CLI,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Runs `cucumberswift generate`, the CucumberSwiftTestingPlugin's tests for feature files. Compile its output into a Swift Testing test target.",
)

def _cucumberswift_fix_feature_files_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    cli = ctx.executable._cli
    # An external repository's files are under ../<repository> in short_path, and the main repository's under
    # ctx.workspace_name.
    cli_path = cli.short_path[3:] if cli.short_path.startswith("../") else ctx.workspace_name + "/" + cli.short_path
    ctx.actions.write(
        output = launcher,
        is_executable = True,
        content = """#!/bin/bash
set -euo pipefail
# bazel run changes the feature files in the source tree, not in Bazel's sandbox.
runfiles="${{RUNFILES_DIR:-$0.runfiles}}"
cd "${{BUILD_WORKSPACE_DIRECTORY:?Run this with bazel run, so it can change your source files.}}/{package}"
exec "$runfiles/{cli}" fix-feature-files {paths} "$@"
""".format(
            package = ctx.label.package,
            cli = cli_path,
            paths = " ".join(["'%s'" % path for path in ctx.attr.paths]),
        ),
    )
    return [DefaultInfo(
        executable = launcher,
        runfiles = ctx.runfiles(files = [cli]).merge(ctx.attr._cli[DefaultInfo].default_runfiles),
    )]

cucumberswift_fix_feature_files = rule(
    implementation = _cucumberswift_fix_feature_files_impl,
    executable = True,
    attrs = {
        "paths": attr.string_list(
            default = ["."],
            doc = "The feature files and folders to fix, relative to this package. Folders are searched at any depth.",
        ),
        "_cli": attr.label(
            default = _CLI,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "`bazel run` it to run `cucumberswift fix-feature-files`, the Fix Feature Files plugin, on the feature files in the source tree. Extra arguments after `--` are more files or folders.",
)
