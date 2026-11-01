"""Unit tests for the fixture linter."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.testing.lint import lint_fixtures

FIXTURES_DIR = Path(__file__).resolve().parents[1] / "fixtures/v1"


class FixtureLinterTests(unittest.TestCase):
    def test_v1_fixtures_pass_lint(self) -> None:
        report = lint_fixtures(FIXTURES_DIR)
        self.assertTrue(report["ok"], f"Lint failures: {report}")
        self.assertGreater(int(report["cases_checked"]), 50)
        self.assertEqual(len(report["duplicate_ids"]), 0)
        self.assertEqual(len(report["schema_errors"]), 0)


if __name__ == "__main__":
    unittest.main()
