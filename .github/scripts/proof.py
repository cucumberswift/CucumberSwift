#!/usr/bin/env python3
"""Saves what tests saw as proof, and builds the Proof check from it (#604).

A test saves proof into the folder that PROOF_DIR names. Each item is a markdown file:

    ---
    title: The XCTest runner prints the coverage warning
    source: Fixtures/CoverageDefaultsTuist (xcodebuild test)
    image: Grading-screenshot.png
    ---
    <what the test saw, as plain text>

`title` says what the item shows and `source` names the test, scenario or fixture that saved it. An item with
`image` is a screenshot: the image file sits beside the markdown file, and the check links to it in the
proof artifact. Anything that can write a file can save proof; the commands below do it for shell steps.

    proof.py save --title T --source S [--name N] < text
        Saves the text as an item.
    proof.py log --title T --source S --patterns FILE LOG
        Saves the lines of LOG that contain a line of FILE (comments and blank lines skipped), in order.
        Saves nothing, and exits 1, when no line matches.
    proof.py attachments --source S RESULT_BUNDLE
        Exports the result bundle's attachments with `xcrun xcresulttool export attachments` (Xcode 16 and
        newer) and saves each image as an item.
    proof.py report --artifacts JSON --out JSON DIR
        Reads the items under DIR, one folder for each job's proof artifact, and writes the Proof check's
        conclusion, title and summary as JSON. JSON maps each artifact's name to its URL.

save, log and attachments do nothing when PROOF_DIR is unset or empty, so a local run saves no proof unless
asked to.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# GitHub cuts a check run's summary at 65,535 characters; this leaves room for the closing lines.
SUMMARY_LIMIT = 60000
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".heic"}


def slug(text):
    """A file name from a title: lowercase letters, digits and dashes."""
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:80] or "item"


def proof_dir():
    folder = os.environ.get("PROOF_DIR", "")
    return Path(folder) if folder else None


def write_item(folder, title, source, body, name=None, image=None):
    """Writes an item as `<name>.md`, adding a number when that name is taken, and returns its path."""
    folder.mkdir(parents=True, exist_ok=True)
    base = slug(name or title)
    path = folder / f"{base}.md"
    number = 2
    while path.exists():
        path = folder / f"{base}-{number}.md"
        number += 1
    # The name is a slug, so it can't leave the folder; this keeps that true if slug changes.
    if path.resolve().parent != folder.resolve():
        raise ValueError(f"{path} is not directly in {folder}")
    lines = ["---", f"title: {one_line(title)}", f"source: {one_line(source)}"]
    if image:
        lines.append(f"image: {image}")
    lines += ["---", body.rstrip("\n"), ""]
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def one_line(text):
    return " ".join(text.split())


def read_item(path):
    """Returns (fields, body) of an item file. A file without front matter is all body."""
    text = path.read_text(encoding="utf-8", errors="replace")
    fields = {}
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            for line in text[4:end].splitlines():
                key, sep, value = line.partition(":")
                if sep:
                    fields[key.strip()] = value.strip()
            text = text[end + 5:]
    return fields, text.strip("\n")


def matching_lines(patterns, log):
    wanted = [line.rstrip("\n") for line in patterns.splitlines()]
    wanted = [line for line in wanted if line.strip() and not line.startswith("#")]
    return [line for line in log.splitlines() if any(pattern in line for pattern in wanted)]


def command_save(args):
    folder = proof_dir()
    if folder is None:
        return
    path = write_item(folder, args.title, args.source, sys.stdin.read(), name=args.name)
    print(f"Saved proof: {path}")


def command_log(args):
    folder = proof_dir()
    if folder is None:
        return 0
    patterns = Path(args.patterns).read_text(encoding="utf-8")
    log = Path(args.log).read_text(encoding="utf-8", errors="replace")
    lines = matching_lines(patterns, log)
    if not lines:
        print(f"error: no line of {args.log} contains a line of {args.patterns}, so there is no proof to save",
              file=sys.stderr)
        return 1
    path = write_item(folder, args.title, args.source, "\n".join(lines), name=args.name)
    print(f"Saved proof: {path} ({len(lines)} lines)")
    return 0


def save_attachments(folder, source, exported):
    """Saves each image in an `xcresulttool export attachments` folder as an item. Returns how many."""
    manifest = json.loads((exported / "manifest.json").read_text(encoding="utf-8"))
    saved = 0
    for test in manifest:
        for attachment in test.get("attachments", []):
            file = exported / attachment["exportedFileName"]
            if file.suffix.lower() not in IMAGE_SUFFIXES or not file.exists():
                continue
            name = attachment.get("suggestedHumanReadableName") or file.stem
            image = f"{slug(test['testIdentifier'] + '-' + name)}{file.suffix.lower()}"
            folder.mkdir(parents=True, exist_ok=True)
            file.replace(folder / image)
            failure = " It is attached to a failure." if attachment.get("isAssociatedWithFailure") else ""
            body = f"Test: {test['testIdentifier']}\nDevice: {attachment.get('deviceName', '')}.{failure}"
            write_item(folder, f"Screenshot: {name}", source, body, name=Path(image).stem, image=image)
            saved += 1
    return saved


def command_attachments(args):
    folder = proof_dir()
    if folder is None:
        return
    with tempfile.TemporaryDirectory() as temp:
        exported = Path(temp)
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", args.result_bundle,
                        "--output-path", str(exported)], check=True)
        saved = save_attachments(folder, args.source, exported)
    print(f"Saved {saved} screenshots as proof from {args.result_bundle}")


def collect(root):
    """Every item under root, as (artifact, fields, body), in path order."""
    items = []
    for path in sorted(root.rglob("*.md")):
        artifact = path.relative_to(root).parts[0] if path.parent != root else ""
        fields, body = read_item(path)
        items.append((artifact, fields, body))
    return items


def fence_for(text):
    """A code fence longer than any run of backticks in text, so the text can't close it."""
    longest = max((len(run) for run in re.findall(r"`+", text)), default=0)
    return "`" * max(3, longest + 1)


def render_item(index, item, budget, artifact_urls):
    """One item's markdown. A text item is cut to its budget of characters."""
    artifact, fields, body = item
    parts = [f"### {fields.get('title') or 'Untitled proof'}\n"]
    if fields.get("source"):
        parts.append(f"Saved by: {fields['source']}\n")
    link = artifact_urls.get(artifact)
    where = f"the [{artifact}]({link}) artifact" if link else f"the {artifact or 'proof'} artifact"
    if "image" in fields:
        parts.append(f"Screenshot `{fields['image']}` in {where}.\n")
        if body:
            parts.append(f"{body}\n")
        return "\n".join(parts)
    text = body
    if budget[index] < len(body):
        text = body[:budget[index]].rstrip() + "\n…"
        parts.append(f"Cut to fit this page. The whole text is in {where}.\n")
    fence = fence_for(text)
    parts.append(f"{fence}text\n{text}\n{fence}\n")
    return "\n".join(parts)


def render(items, artifact_urls, limit=SUMMARY_LIMIT):
    """The check's markdown. Text bodies are cut, longest first, until the page fits under limit."""
    budget = {index: len(body) for index, (_, fields, body) in enumerate(items) if "image" not in fields}

    def page():
        return "\n".join(render_item(index, item, budget, artifact_urls) for index, item in enumerate(items))

    text = page()
    while len(text) > limit and budget:
        longest = max(budget, key=budget.get)
        if budget[longest] == 0:
            break
        budget[longest] = max(0, budget[longest] - (len(text) - limit) - 100)
        text = page()
    return text


def report(root, artifact_urls):
    items = collect(root) if root.is_dir() else []
    if not items:
        return {
            "conclusion": "neutral",
            "title": "No proof saved",
            "summary": "No test saved proof in this run. CONTRIBUTING.md says how a test saves proof.",
        }
    shots = sum(1 for _, fields, _ in items if "image" in fields)
    count = f"{len(items)} item" + ("" if len(items) == 1 else "s")
    if shots:
        count += f", {shots} of them screenshot" + ("" if shots == 1 else "s")
    intro = ("What the tests saw. The pull request's author confirms under `## Proof` in its description "
             "what each item shows and why it proves the change.\n\n")
    return {"conclusion": "success", "title": f"{count} of proof", "summary": intro + render(items, artifact_urls)}


def command_report(args):
    urls = json.loads(Path(args.artifacts).read_text(encoding="utf-8")) if args.artifacts else {}
    result = report(Path(args.dir), urls)
    Path(args.out).write_text(json.dumps(result), encoding="utf-8")
    print(f"{result['conclusion']}: {result['title']}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)

    save = commands.add_parser("save")
    save.add_argument("--title", required=True)
    save.add_argument("--source", required=True)
    save.add_argument("--name")
    save.set_defaults(run=command_save)

    log = commands.add_parser("log")
    log.add_argument("--title", required=True)
    log.add_argument("--source", required=True)
    log.add_argument("--name")
    log.add_argument("--patterns", required=True)
    log.add_argument("log")
    log.set_defaults(run=command_log)

    attachments = commands.add_parser("attachments")
    attachments.add_argument("--source", required=True)
    attachments.add_argument("result_bundle")
    attachments.set_defaults(run=command_attachments)

    build = commands.add_parser("report")
    build.add_argument("--artifacts")
    build.add_argument("--out", required=True)
    build.add_argument("dir")
    build.set_defaults(run=command_report)

    args = parser.parse_args(argv)
    return args.run(args) or 0


if __name__ == "__main__":
    sys.exit(main())
