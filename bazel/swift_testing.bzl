"""Runs a project's feature files with CucumberSwift's Swift Testing runner.

`cucumberswift_testing_sources` writes the Swift Testing tests for feature files, as the
CucumberSwiftTestingPlugin build tool plugin does in a Swift package. Compile its output into the
`swift_library` of a test target that depends on `@cucumberswift//:CucumberSwiftTesting`, and put the
feature files in the test bundle's `Features` folder, as for the XCTest runner:

    cucumberswift_testing_sources(
        name = "FeaturesTests_generated",
        feature_files = glob(["Features/**/*.feature"]),
        swift_srcs = glob(["*.swift"]),
    )

    swift_library(
        name = "FeaturesTestsLib",
        testonly = True,
        srcs = glob(["*.swift"]) + [":FeaturesTests_generated"],
        data = [":FeaturesTestsFeatures"],
        module_name = "FeaturesTests",
        deps = ["@cucumberswift//:CucumberSwiftTesting"],
    )

Run the bundle with any test runner that runs `xctest`: `macos_unit_test` with a `macos_xctest_runner`
(xctest_runner.bzl) or `ios_unit_test` with rules_apple's runner. `xctest` runs the Swift Testing tests of
a bundle that links XCTest, which CucumberSwiftTesting does, after its XCTest tests.
"""

def _cucumberswift_testing_sources_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".swift")
    args = ctx.actions.args()
    args.add("--output", output)
    args.add_all(ctx.files.feature_files)
    for swift_src in ctx.files.swift_srcs:
        args.add("--swift", swift_src)
    ctx.actions.run(
        outputs = [output],
        inputs = ctx.files.feature_files + ctx.files.swift_srcs,
        executable = ctx.executable._generator,
        arguments = [args],
        mnemonic = "CucumberSwiftTestingGenerate",
        progress_message = "Generating Swift Testing tests for the feature files of %{label}",
    )
    return [DefaultInfo(files = depset([output]))]

cucumberswift_testing_sources = rule(
    implementation = _cucumberswift_testing_sources_impl,
    attrs = {
        "feature_files": attr.label_list(
            allow_files = [".feature"],
            doc = "The feature files to write tests for.",
        ),
        "swift_srcs": attr.label_list(
            allow_files = [".swift"],
            doc = "The test target's Swift files, which the generator reads to find features written in the Swift DSL.",
        ),
        "_generator": attr.label(
            default = Label("//:CucumberSwiftTestingGenerator"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Writes the Swift Testing tests of feature files, and of the features that Swift files write in the Swift DSL.",
)
