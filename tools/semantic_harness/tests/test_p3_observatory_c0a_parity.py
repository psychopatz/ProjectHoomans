"""Parity and execution validation for migrated Observatory and C0A fixture families (P3)."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.testing.executor import execute_cases
from tools.semantic_harness.testing.loader import load_cases_from_file

FIXTURES_ROOT = Path(__file__).resolve().parents[1] / "fixtures/v1"


class ObservatoryC0AParityTests(unittest.TestCase):
    def test_c0a_multi_turn_fixtures(self) -> None:
        path = FIXTURES_ROOT / "c0a/multi_turn.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 5)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_c0a_suggestions_fixtures(self) -> None:
        path = FIXTURES_ROOT / "c0a/suggestions.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 3)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_c0a_reply_realization_fixtures(self) -> None:
        path = FIXTURES_ROOT / "c0a/reply_realization.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_observatory_lifecycle_fixtures(self) -> None:
        path = FIXTURES_ROOT / "observatory/lifecycle.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_observatory_health_authority_fixtures(self) -> None:
        path = FIXTURES_ROOT / "observatory/health_authority.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 8)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_observatory_permission_rejections_fixtures(self) -> None:
        path = FIXTURES_ROOT / "observatory/permission_rejections.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 4)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_observatory_core_fixtures(self) -> None:
        path = FIXTURES_ROOT / "observatory/core.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")


if __name__ == "__main__":
    unittest.main()
