#!/usr/bin/env python3
"""Risk-tier check: a PR that changes a risk file must carry evidence in its body.

A test cannot see a diff, so this job does. When the PR changes a file listed in
`.github/risk-files.txt` (globs), the PR body must contain the six-item checklist in ITEMS. Each item is
ticked and carries content, or says `n/a: <reason>`. The known-answer and planted-defect items must name a
`tests/testthat/` file that is part of the PR's diff. Standard library only: no R install, a few seconds.

Exempt: no risk file changed, or a body line `Risk-tier: exempt: <reason>`. A release PR (head `release/*`, or
`dev` into `main`) skips the checklist but must carry a body line `Ships: #N, #M, ...` naming the PRs it ships.
Fail closed: a missing or unreadable body fails when a risk file changed.

Usage: python3 scripts/risk_tier.py --changed FILE --body FILE --head-ref REF --base-ref REF \
           [--risk-files .github/risk-files.txt]
Exit status 1 on any problem. Tests: python3 scripts/test_risk_tier.py
"""
import argparse
import fnmatch
import re
import sys

ITEMS = [
    "Independent oracle",
    "Known answer",
    "Planted defect",
    "Invariance or boundary",
    "Dependency or optimizer coverage",
    "Evidence transcript",
]
TEST_ITEMS = ("Known answer", "Planted defect")
MIN_REASON = 8
TEST_PATH = re.compile(r"tests/testthat/[A-Za-z0-9_./-]+\.[Rr]\b")
CHECKBOX = re.compile(r"^\s*[-*]\s*\[([ xX])\]\s*(.+?)\s*$")
SHIPS = re.compile(r"^\s*Ships\s*:.*#\d+")
EXEMPT = re.compile(r"^\s*Risk-tier:\s*exempt(?::\s*(.*?))?\s*$", re.IGNORECASE)


def risk_files(changed, globs):
    return [f for f in changed if any(fnmatch.fnmatch(f, g) for g in globs)]


def template():
    lines = ["Add this block to the PR body (tick each item; `n/a: <reason>` needs a reason of "
             f"at least {MIN_REASON} characters):"]
    for item in ITEMS:
        cite = " tests/testthat/<file in this diff>.R, and what it shows" if item in TEST_ITEMS else " <evidence>"
        lines.append(f"- [x] {item}:{cite}")
    lines.append("Or, for a change with no logic effect (for example a rename), one line: "
                 "`Risk-tier: exempt: <reason>`.")
    return "\n".join(lines)


def _split_item(text):
    """Return (item, content) when `text` starts with a known item name, else (None, None)."""
    lowered = text.lower()
    for item in ITEMS:
        if lowered.startswith(item.lower()):
            rest = text[len(item):].strip()
            return item, re.sub(r"^[:\-–—]\s*", "", rest).strip()
    return None, None


def _na_problem(item, content):
    """Return a problem string when `content` is n/a without a usable reason, '' when n/a is fine, None if not n/a."""
    if not re.match(r"(?i)^n/?a\b", content):
        return None
    reason = re.sub(r"(?i)^n/?a\b\s*[:\-]?\s*", "", content).strip()
    if len(reason) < MIN_REASON:
        return f"'{item}': n/a needs a reason of at least {MIN_REASON} characters (write `n/a: <reason>`)"
    return ""


def check(changed, body, head_ref, base_ref, globs):
    changed = [c.strip() for c in changed if c.strip()]
    touched = risk_files(changed, globs)
    if not touched:
        return []
    header = "Risk files changed: " + ", ".join(touched)
    if head_ref.startswith("release/") or (head_ref == "dev" and base_ref in ("main", "master")):
        # Each constituent PR already carried the checklist on dev; the release PR must say which PRs it ships.
        if body and any(SHIPS.match(l.rstrip("\r")) for l in body.splitlines()):
            return []
        return [header,
                "A release PR must list the PRs it ships, so a risk-file change cannot arrive unchecked. "
                "Add a body line `Ships: #101, #102, ...` (at least one PR number)."]
    if body is None or not body.strip():
        return [header, "The PR body is empty or unreadable; risk-file changes need evidence.", template()]

    lines = [l.rstrip("\r") for l in body.splitlines()]
    for line in lines:
        m = EXEMPT.match(line)
        if m:
            reason = (m.group(1) or "").strip()
            if len(reason) >= MIN_REASON:
                return []
            return [header,
                    f"'Risk-tier: exempt' needs a reason of at least {MIN_REASON} characters "
                    "(write `Risk-tier: exempt: <reason>`).", template()]

    found = {}
    for line in lines:
        m = CHECKBOX.match(line)
        if not m:
            continue
        item, content = _split_item(m.group(2))
        if item and item not in found:
            found[item] = (m.group(1).lower() == "x", content)

    problems = []
    changed_set = set(changed)
    for item in ITEMS:
        if item not in found:
            problems.append(f"'{item}': missing from the PR body")
            continue
        ticked, content = found[item]
        if not ticked:
            problems.append(f"'{item}': not ticked")
            continue
        if not content:
            problems.append(f"'{item}': no content (write the evidence, or `n/a: <reason>`)")
            continue
        na = _na_problem(item, content)
        if na:
            problems.append(na)
            continue
        if na == "":
            continue
        if item in TEST_ITEMS:
            cited = TEST_PATH.findall(content)
            if not cited:
                problems.append(f"'{item}': name a tests/testthat/ file that is part of this PR's diff")
            elif not any(c in changed_set for c in cited):
                problems.append(f"'{item}': {', '.join(cited)} is not part of this PR's diff")
    if problems:
        return [header] + problems + [template()]
    return []


def _read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--changed", required=True, help="file with one changed path per line")
    ap.add_argument("--body", required=True, help="file with the PR body")
    ap.add_argument("--head-ref", default="")
    ap.add_argument("--base-ref", default="")
    ap.add_argument("--risk-files", default=".github/risk-files.txt")
    a = ap.parse_args(argv)

    raw_globs = _read(a.risk_files)
    if raw_globs is None:
        print(f"risk-tier: FAIL: cannot read {a.risk_files}", file=sys.stderr)
        return 1
    globs = [g.strip() for g in raw_globs.splitlines() if g.strip() and not g.strip().startswith("#")]
    if not globs:
        print(f"risk-tier: FAIL: {a.risk_files} lists no risk files", file=sys.stderr)
        return 1
    changed_raw = _read(a.changed)
    if changed_raw is None:
        print(f"risk-tier: FAIL: cannot read {a.changed}", file=sys.stderr)
        return 1

    problems = check(changed_raw.splitlines(), _read(a.body), a.head_ref, a.base_ref, globs)
    if problems:
        print("risk-tier: FAIL")
        print("\n".join(problems))
        return 1
    touched = risk_files(changed_raw.splitlines(), globs)
    print("risk-tier: PASS" + (f" ({len(touched)} risk file(s) with evidence)" if touched else " (no risk file changed)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
