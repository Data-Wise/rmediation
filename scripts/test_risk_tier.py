"""Tests for scripts/risk_tier.py (the PR-body evidence check for risk files).

Run from the package root:  python3 scripts/test_risk_tier.py
Standard library only, so the check needs no R install and stays cheap on PRs to dev.
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import risk_tier  # noqa: E402

RISK = ["R/mbco*.R", "R/prod3_core.R", "R/dop*.R", "R/pprodnormal*.R", "R/ci*.R"]
TEST = "tests/testthat/test-mbco-bounded-replicates.R"
CHANGED = ["R/mbco-compare.R", TEST, "NEWS.md"]

GOOD_BODY = f"""## Summary
x

## Risk-tier evidence
- [x] Independent oracle: OpenMx mxCompare, checked in the source
- [x] Known answer: {TEST} pins 24/96
- [x] Planted defect: {TEST} fails when the denominator is R
- [x] Invariance or boundary: exactly 5% dropped is allowed
- [x] Dependency or optimizer coverage: CSOLNP and SLSQP via scripts/verify-constraint-not-enforced.R
- [x] Evidence transcript: quoted in the PR body below
"""


def check(changed=CHANGED, body=GOOD_BODY, head="feature/x", base="dev"):
    return risk_tier.check(changed, body, head, base, RISK)


class TriggerTests(unittest.TestCase):
    def test_no_risk_file_changed_needs_no_body(self):
        self.assertEqual(check(changed=["NEWS.md", "scripts/check-local.sh"], body=""), [])

    def test_risk_file_with_empty_body_fails(self):
        problems = check(body="")
        self.assertTrue(problems)
        self.assertIn("R/mbco-compare.R", " ".join(problems))

    def test_none_body_fails_closed(self):
        self.assertTrue(check(body=None))

    def test_glob_matches_all_five_patterns(self):
        for f in ["R/mbco.R", "R/prod3_core.R", "R/pprodnormalMC.R", "R/ci_medfit.R", "R/ci.R"]:
            self.assertEqual(risk_tier.risk_files([f], RISK), [f], f)
        for f in ["R/medci.R", "NEWS.md", "tests/testthat/test-ci.R"]:
            self.assertEqual(risk_tier.risk_files([f], RISK), [], f)


class BodyTests(unittest.TestCase):
    def test_complete_body_passes(self):
        self.assertEqual(check(), [])

    def test_crlf_body_passes(self):
        self.assertEqual(check(body=GOOD_BODY.replace("\n", "\r\n")), [])

    def test_missing_item_fails(self):
        body = "\n".join(l for l in GOOD_BODY.splitlines() if "Planted defect" not in l)
        self.assertIn("Planted defect", " ".join(check(body=body)))

    def test_unticked_item_fails(self):
        body = GOOD_BODY.replace("- [x] Independent oracle", "- [ ] Independent oracle")
        self.assertIn("Independent oracle", " ".join(check(body=body)))

    def test_item_with_no_content_fails(self):
        body = GOOD_BODY.replace("- [x] Invariance or boundary: exactly 5% dropped is allowed",
                                 "- [x] Invariance or boundary:")
        self.assertIn("Invariance or boundary", " ".join(check(body=body)))

    def test_na_without_reason_fails(self):
        body = GOOD_BODY.replace("- [x] Invariance or boundary: exactly 5% dropped is allowed",
                                 "- [x] Invariance or boundary: n/a")
        self.assertIn("Invariance or boundary", " ".join(check(body=body)))

    def test_na_with_reason_passes(self):
        body = GOOD_BODY.replace("- [x] Invariance or boundary: exactly 5% dropped is allowed",
                                 "- [x] Invariance or boundary: n/a: no boundary in this change")
        self.assertEqual(check(body=body), [])

    def test_short_na_reason_fails(self):
        body = GOOD_BODY.replace("- [x] Invariance or boundary: exactly 5% dropped is allowed",
                                 "- [x] Invariance or boundary: n/a: no")
        self.assertIn("Invariance or boundary", " ".join(check(body=body)))


class CitedTestFileTests(unittest.TestCase):
    def test_known_answer_citing_a_file_not_in_the_diff_fails(self):
        body = GOOD_BODY.replace(f"Known answer: {TEST}", "Known answer: tests/testthat/test-elsewhere.R")
        problems = check(body=body)
        self.assertIn("Known answer", " ".join(problems))
        self.assertIn("test-elsewhere.R", " ".join(problems))

    def test_planted_defect_citing_no_test_file_fails(self):
        body = GOOD_BODY.replace(f"Planted defect: {TEST} fails", "Planted defect: I tried it, it fails")
        self.assertIn("Planted defect", " ".join(check(body=body)))

    def test_citation_with_na_and_reason_passes(self):
        body = GOOD_BODY.replace(f"Known answer: {TEST} pins 24/96", "Known answer: n/a: refactor, no numeric change")
        self.assertEqual(check(body=body), [])

    def test_cited_file_must_be_a_test_file_even_if_in_the_diff(self):
        body = GOOD_BODY.replace(f"Known answer: {TEST}", "Known answer: NEWS.md")
        self.assertIn("Known answer", " ".join(check(body=body)))


class ExemptionTests(unittest.TestCase):
    def test_release_branch_is_exempt(self):
        self.assertEqual(check(body="", head="release/1.7.1", base="main"), [])

    def test_dev_to_main_is_exempt(self):
        self.assertEqual(check(body="", head="dev", base="main"), [])

    def test_exempt_line_with_reason_passes(self):
        body = "Risk-tier: exempt: rename of R/mbco.R, no logic change"
        self.assertEqual(check(body=body), [])

    def test_exempt_line_without_reason_fails(self):
        self.assertTrue(check(body="Risk-tier: exempt"))
        self.assertTrue(check(body="Risk-tier: exempt: ok"))

    def test_feature_branch_to_dev_is_not_exempt(self):
        self.assertTrue(check(body="", head="feature/x", base="dev"))


class FailureMessageTests(unittest.TestCase):
    def test_failure_lists_the_template(self):
        text = "\n".join(check(body=""))
        for item in risk_tier.ITEMS:
            self.assertIn(item, text)


if __name__ == "__main__":
    unittest.main(verbosity=1)
