import json
import os
import tempfile
import unittest

import mutation_fixture as m

EXPECTED = """# comment
Sources/Voting.swift:11 RelationalOperator < Killed

Sources/Voting.swift:11 RelationalOperator > Survived
"""


def mutant(line, mutator, replacement, status):
    return {"id": "1", "mutatorName": mutator, "replacement": replacement, "status": status,
            "location": {"start": {"line": line, "column": 1}, "end": {"line": line, "column": 3}}}


def report(*mutants):
    return {"files": {"Sources/Voting.swift": {"mutants": list(mutants)}}}


class Folder(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.fixture = os.path.join(self.directory.name, "Fixture")
        self.reports = os.path.join(self.directory.name, "reports")
        os.makedirs(self.fixture)
        os.makedirs(self.reports)

    def write_expected(self, text=EXPECTED):
        with open(os.path.join(self.fixture, "expected-mutants"), "w", encoding="utf-8") as f:
            f.write(text)

    def write_report(self, content):
        with open(os.path.join(self.reports, "mutation-report.json"), "w", encoding="utf-8") as f:
            f.write(content if isinstance(content, str) else json.dumps(content))


class ReadExpectedTests(Folder):
    def test_reads_every_line_other_than_comments_and_blanks(self):
        self.write_expected()
        self.assertEqual(
            m.read_expected(os.path.join(self.fixture, "expected-mutants")),
            {("Sources/Voting.swift", 11, "RelationalOperator", "<"): "Killed",
             ("Sources/Voting.swift", 11, "RelationalOperator", ">"): "Survived"})

    def test_replacement_symbols_are_read_as_they_are(self):
        self.write_expected("Sources/A.swift:3 LogicalOperator || Killed\n")
        self.assertIn(("Sources/A.swift", 3, "LogicalOperator", "||"),
                      m.read_expected(os.path.join(self.fixture, "expected-mutants")))

    def test_refuses_a_missing_file_an_empty_one_a_bad_line_and_a_repeat(self):
        path = os.path.join(self.fixture, "expected-mutants")
        with self.assertRaisesRegex(m.MutantsError, "no expected-mutants"):
            m.read_expected(path)
        self.write_expected("# only a comment\n")
        with self.assertRaisesRegex(m.MutantsError, "lists no mutants"):
            m.read_expected(path)
        self.write_expected("Sources/A.swift:3 Mutator < Maybe\n")
        with self.assertRaisesRegex(m.MutantsError, "line 1 isn't"):
            m.read_expected(path)
        self.write_expected("Sources/A.swift:3 Mutator < Killed\nSources/A.swift:3 Mutator < Survived\n")
        with self.assertRaisesRegex(m.MutantsError, "twice"):
            m.read_expected(path)


class ReadReportTests(Folder):
    def test_reads_each_mutants_place_and_status(self):
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed")))
        self.assertEqual(m.read_report(os.path.join(self.reports, "mutation-report.json")),
                         {("Sources/Voting.swift", 11, "RelationalOperator", "<"): "Killed"})

    def test_refuses_a_missing_report_and_one_that_is_not_a_report(self):
        path = os.path.join(self.reports, "mutation-report.json")
        with self.assertRaisesRegex(m.MutantsError, "no readable"):
            m.read_report(path)
        self.write_report("not json")
        with self.assertRaisesRegex(m.MutantsError, "isn't a mutation report"):
            m.read_report(path)
        self.write_report({"files": {"A.swift": {}}})
        with self.assertRaisesRegex(m.MutantsError, "isn't a mutation report"):
            m.read_report(path)

    def test_refuses_a_report_that_lists_a_mutant_twice(self):
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed"), mutant(11, "RelationalOperator", "<", "Survived")))
        with self.assertRaisesRegex(m.MutantsError, "lists a mutant twice: Sources/Voting.swift:11 RelationalOperator <"):
            m.read_report(os.path.join(self.reports, "mutation-report.json"))


class CheckTests(Folder):
    def good_report(self):
        return report(mutant(11, "RelationalOperator", "<", "Killed"), mutant(11, "RelationalOperator", ">", "Survived"))

    def test_passes_when_every_mutant_is_as_listed(self):
        self.write_expected()
        self.write_report(self.good_report())
        self.assertEqual(m.main(["m", self.fixture, self.reports]), 0)

    def test_fails_a_mutant_with_another_status(self):
        self.write_expected()
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed"),
                                 mutant(11, "RelationalOperator", ">", "Killed")))
        errors = m.check("Fixture", *self.both())
        self.assertEqual(len(errors), 1)
        self.assertIn("is Killed, but expected-mutants lists it as Survived", errors[0])
        self.assertEqual(m.main(["m", self.fixture, self.reports]), 1)

    def test_fails_a_listed_mutant_the_run_did_not_find(self):
        self.write_expected()
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed")))
        errors = m.check("Fixture", *self.both())
        self.assertEqual(len(errors), 1)
        self.assertIn("found no mutant Sources/Voting.swift:11 RelationalOperator >", errors[0])

    def test_fails_a_mutant_the_file_does_not_list(self):
        self.write_expected()
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed"),
                                 mutant(11, "RelationalOperator", ">", "Survived"),
                                 mutant(20, "BooleanLiteral", "false", "Killed")))
        errors = m.check("Fixture", *self.both())
        self.assertEqual(len(errors), 1)
        self.assertIn("doesn't list", errors[0])

    def test_a_run_that_found_no_mutant_cannot_pass(self):
        self.write_expected()
        self.write_report(report())
        self.assertEqual(m.main(["m", self.fixture, self.reports]), 1)

    def test_a_path_outside_the_working_and_temporary_folders_is_refused(self):
        self.write_expected()
        self.write_report(self.good_report())
        self.assertEqual(m.main(["m", "/etc", self.reports]), 1)
        self.assertEqual(m.main(["m", self.fixture, "/etc"]), 1)
        self.assertEqual(m.main(["m", self.fixture, self.reports, "/etc/hosts"]), 1)
        self.assertEqual(m.safe_path(self.fixture), os.path.realpath(self.fixture))

    def test_usage_and_missing_files_fail(self):
        self.assertEqual(m.main(["mutation_fixture.py"]), 2)
        self.assertEqual(m.main(["m", self.fixture, self.reports]), 1)

    def log_for(self, *lines):
        path = os.path.join(self.directory.name, "build.log")
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))
        return path

    def test_the_build_log_must_warn_at_each_survivor_and_only_there(self):
        self.write_expected()
        self.write_report(self.good_report())
        warning = ("/tmp/p/Sources/Voting.swift:11:13: warning: No test failed after changing >= to > at Voting.swift:11. "
                   "Add a scenario that checks this code.")
        self.assertEqual(m.main(["m", self.fixture, self.reports, self.log_for("noise", warning)]), 0)
        self.assertEqual(m.main(["m", self.fixture, self.reports, self.log_for("noise")]), 1)
        killed = warning.replace("to >", "to <")
        self.assertEqual(m.main(["m", self.fixture, self.reports, self.log_for(warning, killed)]), 1)
        self.assertEqual(m.main(["m", self.fixture, self.reports, os.path.join(self.directory.name, "none.log")]), 1)

    def both(self):
        return (m.read_expected(os.path.join(self.fixture, "expected-mutants")),
                m.read_report(os.path.join(self.reports, "mutation-report.json")))


class DocumentedCommands(unittest.TestCase):
    """Each build tool's command in the mutation testing article must be the one that a fixture runs in our CI (#522)."""

    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    def read(self, *path):
        with open(os.path.join(self.root, *path), encoding="utf-8") as f:
            return f.read()

    def article(self):
        return self.read("Sources", "CucumberSwift", "CucumberSwift.docc", "Mutation-Testing.md")

    def test_the_swift_package_command_is_the_one_the_package_fixture_runs(self):
        command = "swift run cucumberswift-cli mutation-test"
        self.assertIn(command, self.article())
        self.assertIn(command, self.read(".github", "scripts", "mutation-package-fixture.sh"))

    def test_the_xcode_options_are_the_ones_the_xcode_fixtures_run_script_passes(self):
        article, project = self.article(), self.read("Fixtures", "MutationTestingTuist", "Project.swift")
        for option in ("--project", "--scheme", "--destination"):
            self.assertIn(option, article)
            self.assertIn(option, project)
        self.assertIn("cucumberswift-cli mutation-test", project)

    def test_the_bazel_command_is_the_one_the_bazel_fixture_runs_without_a_root(self):
        label = "bazel run @cucumberswift//cli:cucumberswift-cli -- mutation-test"
        script = self.read(".github", "scripts", "mutation-bazel-fixture.sh")
        self.assertIn(label, self.article())
        self.assertIn("@cucumberswift//cli:cucumberswift-cli -- mutation-test", script)
        for option in ("--bazel-target", "--sources"):
            self.assertIn(option, self.article())
            self.assertIn(option, script)
        # The article's command has no --root, so under `bazel run` the tool reads BUILD_WORKSPACE_DIRECTORY.
        bazel_run = script[script.index("command=(bazel run"):script.index("else\n  command=(")]
        self.assertNotIn("--root", bazel_run)
        self.assertIn("MUTATION_VIA_BAZEL_RUN=1 .github/scripts/mutation-bazel-fixture.sh", self.read(".github", "workflows", "CI.yml"))


if __name__ == "__main__":
    unittest.main()
