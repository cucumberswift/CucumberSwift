"""Unit tests for proof.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The log lines are cut from a real `xcodebuild test` run of the CoverageDefaultsTuist fixture. Only the
standard library is used.
"""
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import proof  # noqa: E402

LOG = """\
Test Case '-[Grading › A high score 1 › Given a score of 90]' passed (0.001 seconds).
CucumberSwift coverage: Grading: 44% of the code its scenarios ran (4 of 9 regions)
/tmp/SwiftTests/Features/Grading.feature:1: warning: Feature coverage 44%: its scenarios ran 4 of the 9 regions
Test Case '-[Grading › Coverage scores Coverage]' passed (0.002 seconds).
"""

PATTERNS = """\
# Each runner's coverage warning.
warning: Feature coverage

CucumberSwift coverage: Grading:
"""


class ProofTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.folder = self.root / "proof"

    def run_main(self, argv, stdin=""):
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.dict(os.environ, {"PROOF_DIR": str(self.folder)}), \
                mock.patch.object(sys, "stdin", io.StringIO(stdin)), redirect_stdout(out), redirect_stderr(err):
            status = proof.main(argv)
        return status, out.getvalue(), err.getvalue()


class SaveTests(ProofTestCase):
    def test_save_writes_an_item_with_its_title_and_source(self):
        status, _, _ = self.run_main(["save", "--title", "The runner prints it", "--source", "Fixture X"], "seen\n")
        self.assertEqual(status, 0)
        path = self.folder / "the-runner-prints-it.md"
        self.assertEqual(proof.read_item(path), ({"title": "The runner prints it", "source": "Fixture X"}, "seen"))

    def test_a_second_item_with_the_same_title_gets_a_number(self):
        self.run_main(["save", "--title", "Same", "--source", "A"], "one")
        self.run_main(["save", "--title", "Same", "--source", "B"], "two")
        self.assertEqual(sorted(p.name for p in self.folder.iterdir()), ["same-2.md", "same.md"])

    def test_without_proof_dir_nothing_is_saved(self):
        with mock.patch.dict(os.environ, {"PROOF_DIR": ""}), mock.patch.object(sys, "stdin", io.StringIO("x")):
            self.assertEqual(proof.main(["save", "--title", "T", "--source", "S"]), 0)
        self.assertFalse(self.folder.exists())

    def test_a_title_on_several_lines_is_kept_on_one(self):
        path = proof.write_item(self.folder, "A\ntitle", "S", "body")
        self.assertEqual(proof.read_item(path)[0]["title"], "A title")


class LogTests(ProofTestCase):
    def write(self, name, text):
        path = self.root / name
        path.write_text(text, encoding="utf-8")
        return str(path)

    def test_log_saves_the_matching_lines_in_order(self):
        status, _, _ = self.run_main(["log", "--title", "Coverage", "--source", "CoverageDefaultsTuist",
                                      "--patterns", self.write("patterns", PATTERNS), self.write("log", LOG)])
        self.assertEqual(status, 0)
        _, body = proof.read_item(self.folder / "coverage.md")
        self.assertEqual(body.splitlines(), [LOG.splitlines()[1], LOG.splitlines()[2]])

    def test_log_fails_when_no_line_matches(self):
        status, _, err = self.run_main(["log", "--title", "T", "--source", "S",
                                        "--patterns", self.write("patterns", "not in the log\n"), self.write("log", LOG)])
        self.assertEqual(status, 1)
        self.assertIn("no proof to save", err)
        self.assertFalse(self.folder.exists())

    def test_comments_and_blank_lines_match_nothing(self):
        self.assertEqual(proof.matching_lines("# warning\n\n", LOG), [])


class AttachmentsTests(ProofTestCase):
    def test_each_image_in_the_export_is_saved_with_its_test(self):
        exported = self.root / "exported"
        exported.mkdir()
        (exported / "A1.png").write_bytes(b"png")
        (exported / "A2.txt").write_text("not an image")
        (exported / "manifest.json").write_text(json.dumps([{
            "testIdentifier": "Basket/testAddCukes()",
            "attachments": [
                {"exportedFileName": "A1.png", "suggestedHumanReadableName": "Basket with 2 cukes",
                 "isAssociatedWithFailure": False, "deviceName": "iPhone 17"},
                {"exportedFileName": "A2.txt", "suggestedHumanReadableName": "Log",
                 "isAssociatedWithFailure": False, "deviceName": "iPhone 17"},
            ],
        }]))
        self.assertEqual(proof.save_attachments(self.folder, "SwiftTestingAndXCTestTuist", exported), 1)
        items = [p for p in self.folder.iterdir() if p.suffix == ".md"]
        self.assertEqual(len(items), 1)
        fields, body = proof.read_item(items[0])
        self.assertEqual(fields["title"], "Screenshot: Basket with 2 cukes")
        self.assertTrue((self.folder / fields["image"]).exists())
        self.assertIn("Basket/testAddCukes()", body)

    def test_an_exported_file_name_that_leaves_the_folder_is_refused(self):
        exported = self.root / "exported"
        exported.mkdir()
        (self.root / "outside.png").write_bytes(b"png")
        (exported / "manifest.json").write_text(json.dumps([{
            "testIdentifier": "Basket/testAddCukes()",
            "attachments": [{"exportedFileName": "../outside.png", "suggestedHumanReadableName": "Escape"}],
        }]))
        with self.assertRaises(ValueError):
            proof.save_attachments(self.folder, "UI tests", exported)
        self.assertTrue((self.root / "outside.png").exists())
        self.assertFalse(self.folder.exists())

    def test_two_screenshots_with_the_same_name_keep_both_images(self):
        exported = self.root / "exported"
        exported.mkdir()
        (exported / "A1.png").write_bytes(b"first")
        (exported / "A2.png").write_bytes(b"second")
        attachment = lambda file: {"exportedFileName": file, "suggestedHumanReadableName": "Basket"}
        (exported / "manifest.json").write_text(json.dumps([
            {"testIdentifier": "Basket/testAddCukes()", "attachments": [attachment("A1.png"), attachment("A2.png")]}]))
        self.assertEqual(proof.save_attachments(self.folder, "UI tests", exported), 2)
        images = {proof.read_item(p)[0]["image"] for p in self.folder.glob("*.md")}
        self.assertEqual(len(images), 2)
        self.assertEqual({(self.folder / image).read_bytes() for image in images}, {b"first", b"second"})


class ReportTests(ProofTestCase):
    def test_no_items_is_neutral(self):
        result = proof.report(self.root / "missing", {})
        self.assertEqual((result["conclusion"], result["title"]), ("neutral", "No proof saved"))

    def test_items_are_shown_with_their_source_and_screenshots_are_linked(self):
        job = self.folder / "proof-fixture-tests"
        proof.write_item(job, "Coverage warning", "CoverageDefaultsTuist", "Grading.feature:1: warning: x")
        proof.write_item(job, "Screenshot: Basket", "UI tests", "Test: Basket", image="basket.png")
        result = proof.report(self.folder, {"proof-fixture-tests": "https://example.test/a/1"})
        self.assertEqual(result["conclusion"], "success")
        self.assertEqual(result["title"], "2 items, 1 of them screenshot of proof")
        summary = result["summary"]
        self.assertIn("### Coverage warning", summary)
        self.assertIn("Saved by: CoverageDefaultsTuist", summary)
        self.assertIn("```text\nGrading.feature:1: warning: x\n```", summary)
        self.assertIn("Screenshot `basket.png` in the [proof-fixture-tests](https://example.test/a/1) artifact.",
                      summary)

    def test_a_long_page_is_cut_to_the_limit(self):
        job = self.folder / "proof-a"
        proof.write_item(job, "Long", "S", "x" * 5000)
        proof.write_item(job, "Short", "S", "short text")
        page = proof.render(proof.collect(self.folder), {}, limit=1000)
        self.assertLessEqual(len(page), 1000)
        self.assertIn("short text", page)
        self.assertIn("Cut to fit this page.", page)

    def test_a_page_of_screenshots_is_bounded_in_bytes(self):
        job = self.folder / "proof-a"
        for number in range(200):
            proof.write_item(job, f"Screenshot {number}: é", "S", "Test: x", image=f"s{number}.png")
        page = proof.render(proof.collect(self.folder), {"proof-a": "https://example.test/a/1"}, limit=2000)
        self.assertLessEqual(len(page.encode("utf-8")), 2000)
        self.assertIn("[proof-a](https://example.test/a/1)", page)
        self.assertIn("more", page)

    def test_an_oversized_artifact_list_is_bounded_too(self):
        urls = {}
        for number in range(300):
            proof.write_item(self.folder / f"proof-job-{number}", "Item", "S", "text")
            urls[f"proof-job-{number}"] = f"https://example.test/artifacts/{number}"
        page = proof.render(proof.collect(self.folder), urls, limit=2000)
        self.assertLessEqual(len(page.encode("utf-8")), 2000)
        self.assertIn("more lines", page)

    def test_multibyte_text_is_cut_by_bytes(self):
        proof.write_item(self.folder / "proof-a", "Long", "S", "é" * 3000)
        page = proof.render(proof.collect(self.folder), {}, limit=3000)
        self.assertLessEqual(len(page.encode("utf-8")), 3000)

    def test_backticks_in_the_text_cannot_close_its_fence(self):
        proof.write_item(self.folder / "proof-a", "Code", "S", "```swift\nlet x = 1\n```")
        self.assertIn("````text\n```swift", proof.render(proof.collect(self.folder), {}))

    def test_report_writes_the_check_as_json(self):
        proof.write_item(self.folder / "proof-a", "One", "S", "seen")
        out = self.root / "check.json"
        status, _, _ = self.run_main(["report", "--out", str(out), str(self.folder)])
        self.assertEqual(status, 0)
        self.assertEqual(json.loads(out.read_text())["title"], "1 item of proof")


if __name__ == "__main__":
    unittest.main()
