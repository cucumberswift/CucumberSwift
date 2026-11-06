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

    def run_main(self):
        return m.main(["mutation_fixture.py", self.fixture, self.reports])


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


class CheckTests(Folder):
    def good_report(self):
        return report(mutant(11, "RelationalOperator", "<", "Killed"), mutant(11, "RelationalOperator", ">", "Survived"))

    def test_passes_when_every_mutant_is_as_listed(self):
        self.write_expected()
        self.write_report(self.good_report())
        self.assertEqual(self.run_main(), 0)

    def test_fails_a_mutant_with_another_status(self):
        self.write_expected()
        self.write_report(report(mutant(11, "RelationalOperator", "<", "Killed"),
                                 mutant(11, "RelationalOperator", ">", "Killed")))
        errors = m.check("Fixture", *self.both())
        self.assertEqual(len(errors), 1)
        self.assertIn("is Killed, but expected-mutants lists it as Survived", errors[0])
        self.assertEqual(self.run_main(), 1)

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
        self.assertEqual(self.run_main(), 1)

    def test_usage_and_missing_files_fail(self):
        self.assertEqual(m.main(["mutation_fixture.py"]), 2)
        self.assertEqual(self.run_main(), 1)

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


if __name__ == "__main__":
    unittest.main()
