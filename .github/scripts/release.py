#!/usr/bin/env python3
"""Release helper for .github/workflows/release.yml.

  plan     Compute the version from the last release and the chosen bump, check
           it, and write the release notes. A dry run also builds and checks
           the source archive.
  publish  Commit the version files, build the source archive, create the tag
           and create the release.

Inputs come from environment variables that the workflow's first step has
already checked. Branch names, issue titles and pull request titles are
untrusted text: they are handled as data here and never pass through a shell.
"""
import base64
import difflib
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import tarfile

SEMVER = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\Z")
BRANCH = re.compile(r"^(main|support/(0|[1-9][0-9]*)\.x)\Z")
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


def api(path, method="GET", body=None, allow=(), paginate=False, token=None):
    """Call the GitHub API. Return None only for an HTTP status listed in `allow`,
    such as 404 for "does not exist". Any other failure stops the run. With
    `paginate`, read every page of a list and return one list. With `token`, call
    as that token instead of GH_TOKEN."""
    args = ["gh", "api", "-X", method, path] + (["--paginate", "--slurp"] if paginate else [])
    if body is not None:
        args += ["--input", "-"]
    # A list of arguments, no shell: nothing here is interpreted as a command.
    env = dict(os.environ, GH_TOKEN=token) if token else None
    result = subprocess.run(args, input=json.dumps(body) if body is not None else None,
                            capture_output=True, text=True, env=env)
    if result.returncode != 0:
        status = re.search(r"\(HTTP (\d{3})\)", result.stderr)
        if status and int(status.group(1)) in allow:
            return None
        fail(f"GitHub API {method} {path.split('?')[0]} failed "
             f"(HTTP {status.group(1) if status else 'error'}).")
    data = json.loads(result.stdout) if result.stdout.strip() else {}
    return [item for page in data for item in page] if paginate else data


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


# CommonMark: a backtick fence's info string has no backticks, and a closing
# fence is the same character, at least as long, followed only by spaces.
FENCE_OPEN = re.compile(r"^ {0,3}(?:(`{3,})[^`]*|(~{3,}).*)$")
FENCE_CLOSE = re.compile(r"^ {0,3}(`{3,}|~{3,})[ \t]*$")
HEADING = re.compile(r"^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t#]*$")


def code_spans(line):
    """(start, end) of each code span in `line`, as CommonMark reads them. A
    backtick escaped with a backslash cannot open one. A span closes at the next
    backtick run of exactly the opening run's length; backslashes inside a span
    are literal, so they do not escape its closing run.

    Lines are read one at a time. CommonMark lets a span in a paragraph wrap
    onto the next line; such a span is escaped like plain text, which only
    shows `&lt;` in its code. Joining lines would need the block structure
    (list items, quotes, tables) to be right, and getting it wrong would leave
    text outside code unescaped."""
    spans, i = [], 0
    while i < len(line):
        if line[i] == "\\":
            i += 2  # the next character is escaped
            continue
        if line[i] != "`":
            i += 1
            continue
        run = len(line[i:]) - len(line[i:].lstrip("`"))
        j, end = i + run, None
        while j < len(line):
            if line[j] != "`":
                j += 1
                continue
            length = len(line[j:]) - len(line[j:].lstrip("`"))
            if length == run:
                end = j + length
                break
            j += length
        if end is None:
            i += run  # no closing run: the backticks are literal
        else:
            spans.append((i, end))
            i = end
    return spans


def fence_after(line, fence):
    """The code fence open after `line`, given the one open before it, or None
    outside a fenced code block."""
    if fence:
        closed = FENCE_CLOSE.match(line)
        if closed and closed.group(1)[0] == fence[0] and len(closed.group(1)) >= len(fence):
            return None
        return fence
    opened = FENCE_OPEN.match(line)
    return (opened.group(1) or opened.group(2)) if opened else None


def migration(body):
    """The text of the issue body's "## Migration" section, up to the next
    heading of the same or a higher level, or "" when there is none. Lines in
    fenced code blocks are never taken for headings."""
    found, lines, fence = False, [], None
    for line in (body or "").replace("\r\n", "\n").split("\n"):
        code, fence = bool(fence), fence_after(line, fence)
        if not (code or fence):
            heading = HEADING.match(line)
            if heading and len(heading.group(1)) <= 2:
                if found:
                    break
                found = len(heading.group(1)) == 2 and (heading.group(2) or "").strip().lower() == "migration"
                continue
        if found:
            lines.append(line)
    return "\n".join(lines).strip("\n")


def clean_block(text):
    """Make Markdown written in an issue safe to copy into the release notes.
    HTML and mentions are neutralised outside code, as in `clean`; code spans,
    code blocks, links and other Markdown are kept."""
    out, fence = [], None
    for line in text.split("\n"):
        code, fence = bool(fence), fence_after(line, fence)
        if code or fence:
            out.append(line)
            continue
        parts, last = [], 0
        for start, end in code_spans(line):
            parts.append(html.escape(line[last:start], quote=False).replace("@", "@​"))
            parts.append(line[start:end])
            last = end
        parts.append(html.escape(line[last:], quote=False).replace("@", "@​"))
        out.append("".join(parts))
    return "\n".join(out)


# plan ------------------------------------------------------------------------

# Branch rules that stop a direct push of the version commit. "required_signatures"
# is not one: GitHub signs commits made through its API (committer web-flow).
# Metadata rules (commit_message_pattern, tag_name_pattern and similar) are not
# checked: GitHub rejects them as invalid on this organization's plan.
BLOCKS_PUSH = {"pull_request", "required_status_checks", "update", "required_deployments", "merge_queue"}


def ref_pattern(pattern):
    """A ruleset ref pattern as GitHub reads it (Ruby's File.fnmatch with
    FNM_PATHNAME): `*` and `?` do not cross `/`; `**/` matches zero or more
    directories; `**` without a following `/` is the same as `*`; `[...]` is a
    character set."""
    out, i = [], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:[^/]*/)*"); i += 3
        elif pattern.startswith("**", i):
            out.append("[^/]*"); i += 2
        elif pattern[i] == "*":
            out.append("[^/]*"); i += 1
        elif pattern[i] == "?":
            out.append("[^/]"); i += 1
        elif pattern[i] == "[" and "]" in pattern[i + 2:]:
            end = pattern.index("]", i + 2)
            body = pattern[i + 1:end]
            body = "^" + body[1:] if body.startswith("!") else body
            out.append("[" + body.replace("\\", "\\\\") + "]"); i = end + 1
        else:
            out.append(re.escape(pattern[i])); i += 1
    return re.compile("".join(out))


def check_rulesets(repo, branch, version):
    """Stop before anything is written if a ruleset would block the version
    commit or the tag. A ruleset counts only if the token that writes them cannot
    bypass it. GitHub answers that for the token that asks, so the rules are read
    with RULES_TOKEN, a read-only token of the same release app, when it is set."""
    rulesets = {}
    token = os.environ.get("RULES_TOKEN") or None

    def ruleset(ruleset_id):
        if ruleset_id not in rulesets:
            rulesets[ruleset_id] = api(f"repos/{repo}/rulesets/{ruleset_id}?includes_parents=true", token=token)
        return rulesets[ruleset_id]

    def blocks(found):
        # GitHub reports "always", "exempt", "pull_requests_only" or "never". The
        # version commit and the tag are direct writes, so only the first two let
        # this run through.
        return found.get("current_user_can_bypass") not in ("always", "exempt")

    def name(found):
        return " ".join(str(found.get("name", "unnamed")).split())

    def matches(ref, patterns):
        return any(p == "~ALL" or ref_pattern(p).fullmatch(ref) for p in patterns)

    problems = []
    for rule in api(f"repos/{repo}/rules/branches/{branch}?per_page=100", paginate=True, token=token):
        found = ruleset(rule["ruleset_id"]) if rule["type"] in BLOCKS_PUSH else None
        if found and blocks(found):
            problems.append(f'ruleset "{name(found)}" ({rule["type"]}) blocks the version commit on {branch}')

    ref = f"refs/tags/{version}"
    for summary in api(f"repos/{repo}/rulesets?includes_parents=true&per_page=100", paginate=True, token=token):
        if summary.get("target") != "tag" or summary.get("enforcement") != "active":
            continue
        found = ruleset(summary["id"])
        names = found.get("conditions", {}).get("ref_name", {})
        if not matches(ref, names.get("include", [])) or matches(ref, names.get("exclude", [])):
            continue
        if any(r["type"] == "creation" for r in found.get("rules", [])) and blocks(found):
            problems.append(f'ruleset "{name(found)}" (creation) blocks creating the tag {version}')

    if problems:
        fail("This release would stop part-way: " + "; ".join(problems) + ". Nothing was written. "
             "Change the ruleset, or let the release app bypass it, and run again.")


def changes(repo, branch, last_tag, sha):
    """Issues closed by pull requests merged since the last release, pull
    requests without an issue, and commits without a pull request."""
    owner, name = repo.split("/")
    query = """query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          number title
          closingIssuesReferences(first: 50) {
            nodes { number title body stateReason repository { nameWithOwner } issueType { name } labels(first: 50) { nodes { name } } }
          }
        }
      }
    }"""
    pull_numbers, authors, direct = [], {}, []
    # Merge commits are skipped: a merged pull request is found through its own commits.
    for commit in run("git", "rev-list", "--reverse", "--no-merges", f"refs/tags/{last_tag}..{sha}").split():
        pulls = api(f"repos/{repo}/commits/{commit}/pulls")
        # The API also returns pull requests from other repositories in the fork network. A layer
        # of a stacked pull request is squashed onto the branch but keeps the base it had in the
        # stack, so a pull request whose merge commit is this commit counts too.
        merged = [p for p in pulls
                  if p.get("merged_at") and p["base"]["repo"]["full_name"] == repo
                  and (p["base"]["ref"] == branch or p.get("merge_commit_sha") == commit)]
        if merged:
            for pull in merged:
                authors[pull["number"]] = author(pull["user"])
                if pull["number"] not in pull_numbers:
                    pull_numbers.append(pull["number"])
            continue
        subject = run("git", "log", "-1", "--format=%s", commit).strip()
        if not VERSION_COMMIT.match(subject):
            direct.append((commit[:7], subject))

    issues, lone_pulls = {}, []
    for number in pull_numbers:
        data = json.loads(run("gh", "api", "graphql", "-f", f"query={query}", "-f", f"owner={owner}",
                              "-f", f"name={name}", "-F", f"number={number}"))
        pull = data["data"]["repository"]["pullRequest"]
        # Only this repository's issues: a pull request can also close issues elsewhere.
        linked = [i for i in pull["closingIssuesReferences"]["nodes"]
                  if i["repository"]["nameWithOwner"] == repo
                  and i["stateReason"] not in ("NOT_PLANNED", "DUPLICATE")]
        if not linked:
            lone_pulls.append((pull["number"], pull["title"]))
        for issue in linked:
            entry = issues.setdefault(issue["number"], {
                "title": issue["title"],
                "type": (issue["issueType"] or {}).get("name", ""),
                "breaking": any(l["name"] == "breaking" for l in issue["labels"]["nodes"]),
                "migration": migration(issue.get("body")),
                "pulls": [],
            })
            entry["pulls"].append(pull["number"])
    return issues, lone_pulls, direct, authors


LOGIN = re.compile(r"^[A-Za-z0-9-]+(\[bot\])?\Z")


def author(user):
    """"@login" for a person, the plain name for a bot. GitHub logins are only
    letters, digits and hyphens, so they cannot carry markup."""
    login = (user or {}).get("login", "")
    if not LOGIN.match(login):
        return ""
    return login if user.get("type") == "Bot" or login.endswith("[bot]") else f"@{login}"


def pull_ref(number, authors):
    who = authors.get(number, "")
    return f"#{number} by {who}" if who else f"#{number}"


def notes(repo, last, version, issues, lone_pulls, direct, authors):
    def section(title, entries):
        return [f"## {title}", ""] + entries + [""] if entries else []

    def entry(n, i):
        line = f"- {clean(i['title'])} (#{n}, {', '.join(pull_ref(p, authors) for p in i['pulls'])})"
        text = i.get("migration", "")
        if not text:
            return line
        # Indented under the entry, so it belongs to that list item.
        block = "\n".join(f"  {l}" if l.strip() else "" for l in clean_block(text).split("\n"))
        return f"{line}\n\n  **Migration:**\n\n{block}"

    def listed(predicate):
        return [entry(n, i) for n, i in sorted(issues.items()) if predicate(i)]

    known = ("Bug", "Feature", "Task")
    lines = []
    lines += section("Breaking changes", listed(lambda i: i["breaking"]))
    lines += section("Features", listed(lambda i: not i["breaking"] and i["type"] == "Feature"))
    lines += section("Bugs", listed(lambda i: not i["breaking"] and i["type"] == "Bug"))
    lines += section("Tasks", listed(lambda i: not i["breaking"] and i["type"] == "Task"))
    # Everything else in one section: issues with no type, pull requests with no
    # issue, and commits pushed without a pull request.
    lines += section("Other changes", listed(lambda i: not i["breaking"] and i["type"] not in known)
                     + [f"- {clean(t)} ({pull_ref(n, authors)})" for n, t in lone_pulls]
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
                 f"An admin creates it with: git push origin '{fmt(last)}^{{commit}}:refs/heads/{support_branch}'")

    check_rulesets(repo, branch, version)
    issues, lone_pulls, direct, authors = changes(repo, branch, fmt(last), sha)
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
    # A breaking change must say what consumers have to change.
    missing = [f"#{n}" for n, i in sorted(issues.items()) if i["breaking"] and not i["migration"].strip()]
    if missing:
        fail(f"{', '.join(missing)} {'is' if len(missing) == 1 else 'are'} labelled breaking but "
             f"{'has' if len(missing) == 1 else 'have'} no \"## Migration\" section. Add one to the issue body, "
             "saying what consumers must change, and run again. Nothing was created.")

    # A support branch serves an older major, so its releases are never Latest,
    # even before the next major is out. This also keeps a support run and a main
    # run from both claiming Latest.
    latest = not support and (highest is None or target > highest)
    text = notes(repo, fmt(last), version, issues, lone_pulls, direct, authors)
    with open("notes.md", "w", encoding="utf-8") as handle:
        handle.write(text)
    print(f"This run releases {version} from {branch} (last release {fmt(last)}, Latest: {str(latest).lower()}).")
    append("GITHUB_OUTPUT", f"version={version}\nlatest={str(latest).lower()}\n")
    append("GITHUB_STEP_SUMMARY",
           f"## This run releases {version}\n\n"
           f"- Branch: `{branch}`\n- Last release on this line: `{fmt(last)}`\n"
           f"- Kind: `{bump}`\n- Marked Latest: {'yes' if latest else 'no'}\n\n"
           f"### Release notes\n\n{text}")
    # A dry run builds and checks the source archive too, and never uploads it.
    if os.environ.get("DRY_RUN") == "true":
        _, integrity = source_archive(repo, version, sha)
        archive_summary(repo, version, integrity, True, sha)


# publish ---------------------------------------------------------------------

def version_patterns(path):
    """What holds the version in a version file: a name, a pattern for every
    occurrence of it, and a pattern for its value. The plist has two keys, the
    version shown to people and the build number; both are the release version.
    A value never spans lines, so each version changes exactly one line."""
    if path.endswith(".plist"):
        return [(key, re.compile(rf"<key>{key}</key>"),
                 re.compile(rf"(<key>{key}</key>\s*<string>)[^<\n]*(</string>)"))
                for key in ("CFBundleShortVersionString", "CFBundleVersion")]
    fail(f"{path} is not a version file the release can change.")


def set_version(path, content, version):
    for name, occurrence, pattern in version_patterns(path):
        found = len(occurrence.findall(content))
        content, count = pattern.subn(lambda m: f"{m.group(1)}{version}{m.group(2)}", content)
        if found != 1 or count != 1:
            fail(f"Could not find exactly one {name} in {path}.")
    return content


def source_archive(repo, version, commit):
    """Build the release's source archive from `commit` with git archive, check
    it, and return its file name and integrity. Bazel registry entries pin its
    checksum, which GitHub's on-demand tag archives do not keep stable."""
    name = f"{repo.split('/')[1]}-{version}"
    path = f"{name}.tar.gz"
    # The version commit, if there is one, was made through the API.
    if not succeeds("git", "cat-file", "-e", f"{commit}^{{commit}}"):
        run("git", "fetch", "--no-tags", "--depth=1", "origin", commit)
    run("git", "archive", "--format=tar.gz", f"--prefix={name}/", "-o", path, commit)
    # git archive records the commit in the global pax header, as git get-tar-commit-id reads it.
    with tarfile.open(path, "r:gz") as archive:
        built_from = archive.pax_headers.get("comment")
        members = {member.name: member for member in archive.getmembers()}
    if built_from != commit:
        fail(f"{path} was not built from {commit}.")
    if any(n.split("/")[0] != name or ".." in n.split("/") for n in members):
        fail(f"{path} has files outside {name}/.")

    # A path ending in / must be a directory, any other a regular file. A symlink does not count.
    def usable(required):
        member = members.get(f"{name}/{required.rstrip('/')}")
        return member is not None and (member.isdir() if required.endswith("/") else member.isfile())

    missing = [p for p in os.environ.get("ARCHIVE_REQUIRES", "").split() if not usable(p)]
    if missing:
        fail(f"{path} is missing {', '.join(missing)}, or has them as another kind of file.")
    with open(path, "rb") as handle:
        digest = hashlib.sha256(handle.read()).digest()
    return path, f"sha256-{base64.b64encode(digest).decode()}"


def archive_summary(repo, version, integrity, dry_run, sha):
    """Show what the Bazel registry entry's source.json needs."""
    name = f"{repo.split('/')[1]}-{version}"
    path = f"{name}.tar.gz"
    text = (f"\n### Source archive\n\n- Name: `{path}`\n"
            f"- URL: https://github.com/{repo}/releases/download/{version}/{path}\n"
            f"- Integrity: `{integrity}`\n- Strip prefix: `{name}`\n")
    if dry_run:
        text += (f"\nDry run: built from `{sha}` and not uploaded. A release that makes a version commit "
                 "builds the archive from that commit, so its integrity differs.\n")
    append("GITHUB_STEP_SUMMARY", text)


def publish():
    """Safe to run again after a partial failure: it reuses the version commit and
    the tag that an earlier attempt of the same run created, and never replaces a
    release."""
    repo, sha, branch = checked_env()
    version, latest = os.environ["VERSION"], os.environ["LATEST"]
    if not SEMVER.match(version) or latest not in ("true", "false"):
        fail("Unexpected version.")
    message = f"chore: set version {version}"
    # The bot that makes the version commit: the release app's, passed in by the workflow.
    bot = os.environ.get("RELEASE_BOT") or "github-actions[bot]"

    # An earlier attempt may already have moved the branch to its version commit.
    commit = None
    head = api(f"repos/{repo}/git/ref/heads/{branch}")["object"]["sha"]
    if head != sha:
        found = api(f"repos/{repo}/git/commits/{head}")
        if ([p["sha"] for p in found["parents"]] == [sha] and found["message"] == message
                and found["author"]["name"] == bot):
            commit = head
            print(f"Reusing the version commit {head} from an earlier attempt.")

    if commit is None:
        changed = []
        for path in filter(None, (os.environ.get("PLIST"),)):
            found = api(f"repos/{repo}/contents/{path}?ref={sha}", allow=(404,))
            if found is None:
                continue
            content = base64.b64decode(found["content"]).decode("utf-8")
            updated = set_version(path, content, version)
            if updated == content:
                continue
            diff = [l for l in difflib.ndiff(content.splitlines(), updated.splitlines()) if l[:1] in "+-"]
            # At most one changed line per version: one removed and one added.
            if len(diff) > 2 * len(version_patterns(path)):
                fail(f"The version change in {path} would touch more than the version lines.")
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
                         {"message": message, "tree": tree, "parents": [sha]})["sha"]
            # 422: not a fast-forward, because someone pushed to the branch during the run.
            if api(f"repos/{repo}/git/refs/heads/{branch}", "PATCH",
                   {"sha": commit, "force": False}, allow=(422,)) is None:
                fail(f"{branch} moved during the run. Nothing was tagged or released. Start a new run.")

    # Built before the tag, so a bad archive leaves no tag behind.
    archive, integrity = source_archive(repo, version, commit)
    archive_summary(repo, version, integrity, False, commit)

    # The tag: reuse it only if it points to exactly this commit.
    ref = api(f"repos/{repo}/git/ref/tags/{version}", allow=(404,))
    if ref is None:
        tag = api(f"repos/{repo}/git/tags", "POST",
                  {"tag": version, "message": version, "object": commit, "type": "commit"})
        api(f"repos/{repo}/git/refs", "POST", {"ref": f"refs/tags/{version}", "sha": tag["sha"]})
    else:
        target = ref["object"]["sha"]
        if ref["object"]["type"] == "tag":
            target = api(f"repos/{repo}/git/tags/{target}")["object"]["sha"]
        if target != commit:
            fail(f"The tag {version} already exists and points to another commit.")
        print(f"Reusing the tag {version} from an earlier attempt.")

    # The release: create it once. An existing release is never replaced or edited.
    # The docs and the source archive are attached as it is created, so a release
    # never exists without them.
    if api(f"repos/{repo}/releases/tags/{version}", allow=(404,)) is None:
        subprocess.run(["gh", "release", "create", version, "--verify-tag", "--title", f"Release {version}",
                        "--notes-file", "notes.md", f"--latest={latest}",
                        "docs-major.zip", "docs-root.zip", archive], check=True)
    else:
        print(f"The release {version} already exists. Nothing to do.")
    append("GITHUB_STEP_SUMMARY", f"Released {version} at {commit}.\n")


if __name__ == "__main__":
    {"plan": plan, "publish": publish}.get(sys.argv[1] if len(sys.argv) > 1 else "", lambda: fail("usage"))()
