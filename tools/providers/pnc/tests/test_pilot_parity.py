"""Old-versus-new parity verification for the pilot semantic test fixtures."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.testing.executor import execute_cases
from tools.semantic_harness.testing.loader import discover_cases, load_cases_from_file

FIXTURES_ROOT = Path(__file__).resolve().parents[1] / "fixtures/v1/pilot"


class PilotParityTests(unittest.TestCase):
    def test_whats_up_pilot_fixture_passes_with_full_parity(self) -> None:
        path = FIXTURES_ROOT / "whats_up.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 4)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_wellbeing_pilot_fixture_passes_with_full_parity(self) -> None:
        path = FIXTURES_ROOT / "wellbeing.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_identity_collision_pilot_fixture_passes_with_full_parity(self) -> None:
        path = FIXTURES_ROOT / "identity_collision.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 4)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_language_variants_pilot_fixture_passes_with_full_parity(self) -> None:
        path = FIXTURES_ROOT / "language_variants.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 4)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_negative_controls_pilot_fixture_passes_with_full_parity(self) -> None:
        path = FIXTURES_ROOT / "negative_controls.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")


if __name__ == "__main__":
    unittest.main()
