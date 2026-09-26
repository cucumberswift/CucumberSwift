# Security Policy

## Supported Versions

CucumberSwift is a test-only dependency: it is consumed by test targets and is not shipped
inside production app binaries. Security fixes are applied to the current minor release line
only. Older major versions are not patched — please upgrade.

| Version | Supported          | Notes                                              |
| ------- | ------------------ | -------------------------------------------------- |
| 5.0.x   | :white_check_mark: | Current release line.                               |
| 4.x     | :x:                | Last release 4.3.2 (June 2023). Please upgrade.     |
| 3.x     | :x:                | Last release 3.3.26 (February 2023).                |
| 2.x     | :x:                | Last release 2.2.37 (July 2020).                    |
| 1.x     | :x:                | Last release 1.0.64 (August 2018).                  |

## Reporting a Vulnerability

**Please do not open a public issue for a security vulnerability.**

Report it privately through GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/cucumberswift/CucumberSwift/security).
2. Click **Report a vulnerability**.
3. Fill in the advisory form.

This creates a private draft advisory visible only to you and the maintainers. See
[Privately reporting a security vulnerability](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
for details.

If private reporting is unavailable to you, open a regular issue that says only that you have a
security report and asks a maintainer to contact you — do not include details of the
vulnerability in it.

### What to include

- The affected version(s).
- A description of the issue and its impact.
- Steps to reproduce, ideally a minimal `.feature` file plus step definitions.
- Any suggested fix.

### What to expect

- **Acknowledgement** within 7 days.
- **An initial assessment** — whether we consider it a vulnerability, and its severity — within
  14 days.
- **Fix and disclosure**: we aim to release a fix before publishing the advisory. We will credit
  you in the advisory unless you ask us not to.

This is a volunteer-maintained open source project; these are targets, not contractual
guarantees.

## Scope

In scope:

- Code execution or privilege escalation triggered by parsing an untrusted `.feature` file.
- Path traversal or arbitrary file write through feature-file discovery, stub generation, or
  report output.
- Injection of untrusted data into generated step-definition stubs or JSON reports.
- Supply-chain issues in this repository's own release and CI pipeline.

Out of scope:

- Vulnerabilities in a consuming application's own step definitions.
- Issues that require the attacker to already control the test target's source code.
- Findings against unsupported versions (see the table above).
