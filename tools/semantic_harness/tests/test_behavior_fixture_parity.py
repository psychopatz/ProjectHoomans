"""Parity and execution validation for broad behavior fixture migration ."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.testing.executor import execute_cases
from tools.semantic_harness.testing.loader import load_cases_from_file

FIXTURES_ROOT = Path(__file__).resolve().parents[1] / "fixtures/v1/behavior"


class BehaviorParityTests(unittest.TestCase):
    def test_commands_fixtures(self) -> None:
        path = FIXTURES_ROOT / "commands.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 14)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_questions_fixtures(self) -> None:
        path = FIXTURES_ROOT / "questions.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 10)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_social_dialogue_fixtures(self) -> None:
        path = FIXTURES_ROOT / "social_dialogue.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 6)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")

    def test_inventory_dialogue_fixtures(self) -> None:
        path = FIXTURES_ROOT / "inventory_dialogue.json"
        cases = load_cases_from_file(path)
        self.assertEqual(len(cases), 1)
        results = execute_cases(cases)
        for r in results:
            self.assertTrue(r.passed, f"Failed: {r.summary()} - {r.failures}")


if __name__ == "__main__":
    unittest.main()
