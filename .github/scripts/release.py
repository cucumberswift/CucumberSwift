#!/usr/bin/env python3
"""Release helper for .github/workflows/release.yml.

  plan     Compute the version from the last release and the chosen bump, check
           it, and write the release notes.
  publish  Commit the version files, create the tag and create the release.

Inputs come from environment variables that the workflow's first step has
already checked. Branch names, issue titles and pull request titles are
untrusted text: they are handled as data here and never pass through a shell.
"""
import base64
import difflib
import html
import json
import os
import re
import subprocess
import sys

SEMVER = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
BRANCH = re.compile(r"^(main|support/(0|[1-9][0-9]*)\.x)$")
RANK = {"patch": 1, "minor": 2, "major": 3}
# Version commits made by this workflow, and by the automation it replaced.
VERSION_COMMIT = re.compile(r"^(chore: set version |\[ci skip\] Apply automatic changes)")


def fail(message):
    print(f"::error::{message}")
    sys.exit(1)


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def succeeds(*args):
    return subprocess.run(args, capture_output=True).returncode == 0


def api(path, method="GET", body=None):
    args = ["gh", "api", "-X", method, path]
    if body is not None:
        args += ["--input", "-"]
    result = subprocess.run(args, input=json.dumps(body) if body is not None else None,
                            capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return json.loads(result.stdout) if result.stdout.strip() else {}


def parse(tag):
    match = SEMVER.match(tag)
    return tuple(int(part) for part in match.groups()) if match else None


def fmt(version):
    return ".".join(str(part) for part in version)


def append(env_name, text):
    with open(os.environ[env_name], "a", encoding="utf-8") as handle:
        handle.write(text)


def checked_env():
    branch = os.environ["BRANCH"]
    if not BRANCH.match(branch):
        fail("Unexpected branch.")
    return os.environ["GITHUB_REPOSITORY"], os.environ["RELEASE_SHA"], branch


def clean(title):
    """Make a title safe to show as plain text in Markdown."""
    title = " ".join(title.split())
    title = html.escape(title, quote=False)
    title = title.replace("[", "\\[").replace("]", "\\]")
    return title.replace("@", "@​")  # no mentions


# plan ------------------------------------------------------------------------

def changes(repo, branch, last_tag, sha):
    """Issues closed by pull requests merged since the last release, pull
    requests without an issue, and commits without a pull request."""
    owner, name = repo.split("/")
    query = """query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          number title
          closingIssuesReferences(first: 50) {
            nodes { number title stateReason issueType { name } labels(first: 50) { nodes { name } } }
          }
        }
      }
    }"""
    pull_numbers, direct = [], []
    for commit in run("git", "rev-list", "--reverse", f"refs/tags/{last_tag}..{sha}").split():
        pulls = api(f"repos/{repo}/commits/{commit}/pulls") or []
        merged = [p["number"] for p in pulls if p.get("merged_at") and p["base"]["ref"] == branch]
        if merged:
            pull_numbers += [n for n in merged if n not in pull_numbers]
            continue
        subject = run("git", "log", "-1", "--format=%s", commit).strip()
        if not VERSION_COMMIT.match(subject):
            direct.append((commit[:7], subject))

    issues, lone_pulls = {}, []
    for number in pull_numbers:
        data = json.loads(run("gh", "api", "graphql", "-f", f"query={query}", "-f", f"owner={owner}",
                              "-f", f"name={name}", "-F", f"number={number}"))
        pull = data["data"]["repository"]["pullRequest"]
        linked = [i for i in pull["closingIssuesReferences"]["nodes"]
                  if i["stateReason"] not in ("NOT_PLANNED", "DUPLICATE")]
        if not linked:
            lone_pulls.append((pull["number"], pull["title"]))
        for issue in linked:
            issues[issue["number"]] = {
                "title": issue["title"],
                "type": (issue["issueType"] or {}).get("name", ""),
                "breaking": any(l["name"] == "breaking" for l in issue["labels"]["nodes"]),
            }
    return issues, lone_pulls, direct


def notes(repo, last, version, issues, lone_pulls, direct):
    def section(title, entries):
        return [f"## {title}", ""] + entries + [""] if entries else []

    def listed(predicate):
        return [f"- {clean(i['title'])} (#{n})" for n, i in sorted(issues.items()) if predicate(i)]

    known = ("Bug", "Feature", "Task")
    lines = []
    lines += section("Breaking changes", listed(lambda i: i["breaking"]))
    lines += section("Bugs", listed(lambda i: not i["breaking"] and i["type"] == "Bug"))
    lines += section("Features", listed(lambda i: not i["breaking"] and i["type"] == "Feature"))
    lines += section("Tasks", listed(lambda i: not i["breaking"] and i["type"] == "Task"))
    lines += section("Other", listed(lambda i: not i["breaking"] and i["type"] not in known))
    lines += section("Other changes", [f"- {clean(t)} (#{n})" for n, t in lone_pulls]
                     + [f"- {clean(s)} ({c})" for c, s in direct])
    if not lines:
        lines = [f"No changes since {last}.", ""]
    lines.append(f"**Full list of changes:** https://github.com/{repo}/compare/{last}...{version}")
    return "\n".join(lines) + "\n"


def plan():
    repo, sha, branch = checked_env()
    bump = os.environ["BUMP"]
    if bump not in RANK:
        fail("bump must be patch, minor or major.")
    support = branch != "main"
    line_major = int(branch.split("/")[1][:-2]) if support else None

    all_tags = set(run("git", "tag", "--list").split())
    released = sorted(v for v in map(parse, all_tags) if v)
    reachable = sorted(v for v in map(parse, run("git", "tag", "--merged", sha).split()) if v)
    if support:
        reachable = [v for v in reachable if v[0] == line_major]
    if not reachable:
        fail(f"No release found on {branch}. Create the first release of a line by hand.")
    last = reachable[-1]

    if support and bump == "major":
        fail(f"A major release cannot come from {branch}. Release majors from main.")
    target = {"patch": (last[0], last[1], last[2] + 1),
              "minor": (last[0], last[1] + 1, 0),
              "major": (last[0] + 1, 0, 0)}[bump]
    version = fmt(target)
    if version in all_tags:
        fail(f"The tag {version} already exists.")
    highest = released[-1] if released else None
    if not support and highest and target <= highest:
        fail(f"{version} is not higher than the highest release, {fmt(highest)}.")
    # Leaving 0.x needs no support branch: a 0.x line is not supported after 1.0.0.
    if not support and bump == "major" and last[0] >= 1:
        support_branch = f"support/{last[0]}.x"
        if not (succeeds("git", "rev-parse", "--verify", "-q", f"refs/remotes/origin/{support_branch}")
                and succeeds("git", "merge-base", "--is-ancestor", f"refs/tags/{fmt(last)}",
                             f"refs/remotes/origin/{support_branch}")):
            fail(f"Releasing {version} needs {support_branch}, created from {fmt(last)}. "
                 f"An admin creates it with: git push origin {fmt(last)}:refs/heads/{support_branch}")

    issues, lone_pulls, direct = changes(repo, branch, fmt(last), sha)
    needed, reasons = 0, []
    for number, issue in sorted(issues.items()):
        if issue["breaking"]:
            level = 3 if last[0] >= 1 else 2
            needed = max(needed, level)
            reasons.append(f"#{number} is labelled breaking")
        elif issue["type"] == "Feature" and last[0] >= 1:
            needed = max(needed, 2)
            reasons.append(f"#{number} is a Feature")
    if RANK[bump] < needed:
        wanted = {2: "minor", 3: "major"}[needed]
        fail(f"{bump} is too low: {', '.join(reasons)}, which needs at least {wanted}. "
             "Choose a higher bump, or fix the labels and run again.")

    latest = highest is None or target > highest
    text = notes(repo, fmt(last), version, issues, lone_pulls, direct)
    with open("notes.md", "w", encoding="utf-8") as handle:
        handle.write(text)
    append("GITHUB_OUTPUT", f"version={version}\nlatest={str(latest).lower()}\n")
    append("GITHUB_STEP_SUMMARY",
           f"## This run releases {version}\n\n"
           f"- Branch: `{branch}`\n- Last release on this line: `{fmt(last)}`\n"
           f"- Kind: `{bump}`\n- Marked Latest: {'yes' if latest else 'no'}\n\n"
           f"### Release notes\n\n{text}")


# publish ---------------------------------------------------------------------

def set_version(path, content, version):
    if path.endswith(".plist"):
        pattern = re.compile(r"(<key>CFBundleVersion</key>\s*<string>)[^<]*(</string>)")
    else:
        pattern = re.compile(r"^(\s*s\.version\s*=\s*['\"])[^'\"]*(['\"])", re.MULTILINE)
    updated, count = pattern.subn(lambda m: f"{m.group(1)}{version}{m.group(2)}", content)
    if count != 1:
        fail(f"Could not find exactly one version in {path}.")
    return updated


def publish():
    repo, sha, branch = checked_env()
    version, latest = os.environ["VERSION"], os.environ["LATEST"]
    if not SEMVER.match(version) or latest not in ("true", "false"):
        fail("Unexpected version.")

    changed = []
    for path in filter(None, (os.environ.get("PLIST"), os.environ.get("PODSPEC"))):
        found = api(f"repos/{repo}/contents/{path}?ref={sha}")
        if found is None:
            continue
        content = base64.b64decode(found["content"]).decode("utf-8")
        updated = set_version(path, content, version)
        if updated == content:
            continue
        diff = [l for l in difflib.ndiff(content.splitlines(), updated.splitlines()) if l[:1] in "+-"]
        if len(diff) != 2:
            fail(f"The version change in {path} would touch more than one line.")
        changed.append((path, updated))

    commit = sha
    if changed:
        tree = api(f"repos/{repo}/git/commits/{sha}")["tree"]["sha"]
        items = []
        for path, updated in changed:
            blob = api(f"repos/{repo}/git/blobs", "POST",
                       {"content": base64.b64encode(updated.encode("utf-8")).decode(), "encoding": "base64"})
            items.append({"path": path, "mode": "100644", "type": "blob", "sha": blob["sha"]})
        tree = api(f"repos/{repo}/git/trees", "POST", {"base_tree": tree, "tree": items})["sha"]
        commit = api(f"repos/{repo}/git/commits", "POST",
                     {"message": f"chore: set version {version}", "tree": tree, "parents": [sha]})["sha"]
        if api(f"repos/{repo}/git/refs/heads/{branch}", "PATCH", {"sha": commit, "force": False}) is None:
            fail(f"{branch} moved during the run. Nothing was tagged or released. Start a new run.")

    if api(f"repos/{repo}/git/ref/tags/{version}") is not None:
        fail(f"The tag {version} already exists.")
    tag = api(f"repos/{repo}/git/tags", "POST",
              {"tag": version, "message": version, "object": commit, "type": "commit"})
    if tag is None or api(f"repos/{repo}/git/refs", "POST", {"ref": f"refs/tags/{version}", "sha": tag["sha"]}) is None:
        fail(f"Could not create the tag {version}.")

    subprocess.run(["gh", "release", "create", version, "--verify-tag", "--title", f"Release {version}",
                    "--notes-file", "notes.md", f"--latest={latest}"], check=True)
    append("GITHUB_STEP_SUMMARY", f"Released {version} at {commit}.\n")


if __name__ == "__main__":
    {"plan": plan, "publish": publish}.get(sys.argv[1] if len(sys.argv) > 1 else "", lambda: fail("usage"))()
