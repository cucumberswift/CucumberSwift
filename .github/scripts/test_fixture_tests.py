"""Unit tests for fixture_tests.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The outputs below are cut from real `swift test` and `xcodebuild test` runs of
the fixtures, apart from XCODEBUILD_NOTHING_RAN, which has the shape #509
describes. Only the standard library is used.
"""
import io
import os
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fixture_tests  # noqa: E402

# `swift test` of a package with XCTest scenarios, and no Swift Testing tests.
SWIFT_TEST_XCTEST = """\
Test Suite 'All tests' started at 2026-11-02 12:38:20.238.
Test Suite 'StepDefinitionMacrosPackagePackageTests.xctest' started at 2026-11-02 12:38:20.239.
Test Suite 'CucumberTest' started at 2026-11-02 12:38:20.239.
Test Case '-[Step definition macros › An async step 1 › When I wait for 2 more cukes]' passed (0.048 seconds).
Test Case '-[Step definition macros › An async step 2 › Then the basket holds 2 cukes]' passed (0.004 seconds).
Test Suite 'Step definition macros › An async step' passed at 2026-11-02 12:38:20.300.
\t Executed 2 tests, with 0 failures (0 unexpected) in 0.052 (0.053) seconds
Test Suite 'CucumberTest' passed at 2026-11-02 12:38:20.810.
\t Executed 2 tests, with 0 failures (0 unexpected) in 0.404 (0.423) seconds
Test Suite 'StepDefinitionMacrosPackagePackageTests.xctest' passed at 2026-11-02 12:38:20.829.
\t Executed 2 tests, with 0 failures (0 unexpected) in 0.415 (0.434) seconds
Test Suite 'All tests' passed at 2026-11-02 12:38:20.829.
\t Executed 2 tests, with 0 failures (0 unexpected) in 0.415 (0.438) seconds
◇ Test run started.
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
"""

# `swift test` of a package with Swift Testing scenarios, and no XCTest tests.
SWIFT_TEST_SWIFT_TESTING = """\
Test Suite 'All tests' started at 2026-11-02 12:56:20.588.
Test Suite 'All tests' passed at 2026-11-02 12:56:20.597.
\t Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.009) seconds
◇ Test run started.
✔ Test "Feature files are valid Gherkin" passed after 0.001 seconds.
✔ Test "Eating cukes in a rule" with 10 test cases passed after 0.019 seconds.
✔ Test run with 18 tests in 8 suites passed after 0.175 seconds.
"""

# `swift test` of a package whose tests fail, as expected-failures requires.
SWIFT_TEST_FAILING = """\
Test Suite 'All tests' failed at 2026-11-02 12:36:06.933.
\t Executed 6 tests, with 1 test skipped and 3 failures (0 unexpected) in 0.310 (0.317) seconds
✘ Test run with 3 tests in 3 suites failed after 0.052 seconds with 2 issues.
"""

# `xcodebuild test` of a scheme with a Swift Testing unit test bundle and an
# XCTest UI test bundle. Each bundle has its own 'All tests' suite.
XCODEBUILD_TWO_BUNDLES = """\
Test Suite 'All tests' started at 2026-11-02 12:47:18.144.
Test Suite 'All tests' passed at 2026-11-02 12:47:18.146.
\t Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
◇ Test run started.
✔ Test run with 6 tests in 3 suites passed after 0.749 seconds.
Test Suite 'All tests' started at 2026-11-02 12:47:30.185.
Test Suite 'BasketUITests.xctest' started at 2026-11-02 12:47:30.186.
Test Suite 'CucumberTest' passed at 2026-11-02 12:47:50.390.
\t Executed 6 tests, with 0 failures (0 unexpected) in 20.193 (20.204) seconds
Test Suite 'BasketUITests.xctest' passed at 2026-11-02 12:47:50.390.
\t Executed 6 tests, with 0 failures (0 unexpected) in 20.193 (20.204) seconds
Test Suite 'All tests' passed at 2026-11-02 12:47:50.390.
\t Executed 6 tests, with 0 failures (0 unexpected) in 20.193 (20.205) seconds
Test session results, code coverage, and logs:
** TEST SUCCEEDED **
"""

# `xcodebuild test` after the test process crashed and Xcode ran the bundle
# again with 0 tests (#509). It exits with success.
XCODEBUILD_NOTHING_RAN = """\
XCTest/HarnessEventHandler.swift:26: Fatal error: Internal inconsistency: Recording issues for suites is not supported.
Test Suite 'All tests' started at 2026-11-02 13:00:00.000.
Test Suite 'All tests' passed at 2026-11-02 13:00:00.001.
\t Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
◇ Test run started.
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
Test session results, code coverage, and logs:
** TEST SUCCEEDED **
"""


class CountTestsTests(unittest.TestCase):
    def test_counts_xctest_from_the_all_tests_summary_only(self):
        self.assertEqual(fixture_tests.count_tests(SWIFT_TEST_XCTEST),
                         {"XCTest": 2, "Swift Testing": 0})

    def test_counts_swift_testing_from_the_run_summary(self):
        self.assertEqual(fixture_tests.count_tests(SWIFT_TEST_SWIFT_TESTING),
                         {"XCTest": 0, "Swift Testing": 18})

    def test_counts_a_failed_run(self):
        self.assertEqual(fixture_tests.count_tests(SWIFT_TEST_FAILING),
                         {"XCTest": 6, "Swift Testing": 3})

    def test_adds_up_every_bundle(self):
        self.assertEqual(fixture_tests.count_tests(XCODEBUILD_TWO_BUNDLES),
                         {"XCTest": 6, "Swift Testing": 6})

    def test_counts_one_test(self):
        output = ("Test Suite 'All tests' passed at 2026-11-02 12:41:42.181.\n"
                  "\t Executed 1 test, with 0 failures (0 unexpected) in 0.043 (0.066) seconds\n"
                  "✔ Test run with 1 test in 1 suite passed after 0.001 seconds.\n")
        self.assertEqual(fixture_tests.count_tests(output),
                         {"XCTest": 1, "Swift Testing": 1})

    def test_counts_nothing_in_a_run_without_summaries(self):
        self.assertEqual(fixture_tests.count_tests("Build complete!\n"),
                         {"XCTest": 0, "Swift Testing": 0})


class ReadExpectedTests(unittest.TestCase):
    def write(self, text):
        folder = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, folder)
        path = os.path.join(folder, "expected-tests")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return path

    def test_reads_both_frameworks_and_skips_comments(self):
        path = self.write("# A comment\n\nXCTest: 6\nSwift Testing:3\n")
        self.assertEqual(fixture_tests.read_expected(path),
                         {"XCTest": 6, "Swift Testing": 3})

    def test_reads_a_last_line_without_a_newline(self):
        path = self.write("Swift Testing: 18")
        self.assertEqual(fixture_tests.read_expected(path), {"Swift Testing": 18})

    def test_a_missing_file_is_an_error(self):
        with self.assertRaisesRegex(fixture_tests.ExpectedTestsError,
                                    "no expected-tests file"):
            fixture_tests.read_expected(os.path.join(tempfile.gettempdir(),
                                                     "no-such-folder", "expected-tests"))

    def test_a_file_that_lists_nothing_is_an_error(self):
        with self.assertRaisesRegex(fixture_tests.ExpectedTestsError, "lists no tests"):
            fixture_tests.read_expected(self.write("# Only a comment\n"))

    def test_an_unreadable_line_is_an_error(self):
        for line in ["XCTest 6", "XCTests: 6", "XCTest: six", "XCTest: -1"]:
            with self.subTest(line=line):
                with self.assertRaisesRegex(fixture_tests.ExpectedTestsError, "line 1"):
                    fixture_tests.read_expected(self.write(line + "\n"))

    def test_a_framework_listed_twice_is_an_error(self):
        with self.assertRaisesRegex(fixture_tests.ExpectedTestsError, "twice"):
            fixture_tests.read_expected(self.write("XCTest: 1\nXCTest: 2\n"))


class CheckTests(unittest.TestCase):
    def test_passes_when_each_framework_ran_enough(self):
        self.assertEqual(fixture_tests.check("F", {"XCTest": 6, "Swift Testing": 6},
                                             {"XCTest": 6, "Swift Testing": 7}), [])

    def test_fails_a_framework_that_ran_fewer(self):
        errors = fixture_tests.check("F", {"XCTest": 6, "Swift Testing": 6},
                                     {"XCTest": 6, "Swift Testing": 5})
        self.assertEqual(errors, ["error: F: ran 5 Swift Testing tests, fewer than "
                                  "the 6 expected-tests requires"])

    def test_fails_tests_of_a_framework_it_does_not_list(self):
        errors = fixture_tests.check("F", {"Swift Testing": 18},
                                     {"XCTest": 2, "Swift Testing": 18})
        self.assertEqual(errors, ["error: F: ran 2 XCTest tests, which "
                                  "expected-tests doesn't list"])


class MainTests(unittest.TestCase):
    def run_main(self, expected, output):
        folder = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, folder)
        fixture = os.path.join(folder, "SomeFixture")
        os.mkdir(fixture)
        if expected is not None:
            with open(os.path.join(fixture, "expected-tests"), "w", encoding="utf-8") as f:
                f.write(expected)
        log = os.path.join(folder, "output.log")
        with open(log, "w", encoding="utf-8") as f:
            f.write(output)
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            status = fixture_tests.main(["fixture_tests.py", fixture + "/", log])
        return status, out.getvalue(), err.getvalue()

    def test_fails_a_run_of_0_tests_that_exited_with_success(self):
        # #509: TEST SUCCEEDED, exit status 0, nothing ran.
        status, _, err = self.run_main("XCTest: 6\nSwift Testing: 6\n",
                                       XCODEBUILD_NOTHING_RAN)
        self.assertEqual(status, 1)
        self.assertIn("error: SomeFixture: ran 0 XCTest tests, fewer than the 6 "
                      "expected-tests requires", err)
        self.assertIn("error: SomeFixture: ran 0 Swift Testing tests, fewer than the 6 "
                      "expected-tests requires", err)

    def test_fails_a_run_with_no_test_output(self):
        status, _, err = self.run_main("Swift Testing: 18\n", "Build complete!\n")
        self.assertEqual(status, 1)
        self.assertIn("ran 0 Swift Testing tests", err)

    def test_passes_a_run_of_every_test(self):
        status, out, err = self.run_main("XCTest: 6\nSwift Testing: 6\n",
                                         XCODEBUILD_TWO_BUNDLES)
        self.assertEqual((status, err), (0, ""))
        self.assertEqual(out, "SomeFixture: ran 6 XCTest and 6 Swift Testing tests, "
                              "as many as expected-tests requires.\n")

    def test_fails_a_fixture_without_expected_tests(self):
        status, _, err = self.run_main(None, XCODEBUILD_TWO_BUNDLES)
        self.assertEqual(status, 1)
        self.assertEqual(err, "error: SomeFixture: has no expected-tests file\n")


class FixturesTests(unittest.TestCase):
    """Every fixture has an expected-tests file that this script can read."""

    def test_every_fixture_lists_its_tests(self):
        fixtures = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                os.pardir, os.pardir, "Fixtures")
        if not os.path.isdir(fixtures):
            self.skipTest("Fixtures/ isn't in this checkout")
        names = sorted(name for name in os.listdir(fixtures)
                       if os.path.isdir(os.path.join(fixtures, name)))
        self.assertTrue(names)
        for name in names:
            with self.subTest(fixture=name):
                expected = fixture_tests.read_expected(
                    os.path.join(fixtures, name, "expected-tests"))
                self.assertTrue(all(count > 0 for count in expected.values()))


if __name__ == "__main__":
    unittest.main()
