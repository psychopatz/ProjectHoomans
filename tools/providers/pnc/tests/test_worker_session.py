"""Hoomans-specific GUI callback behavior for the Core worker session."""

from __future__ import annotations

from concurrent.futures import Future
from pathlib import Path
import unittest
from unittest.mock import Mock

from tools.semantic_harness.testing.executor import execute_cases
from tools.semantic_harness.testing.loader import load_cases_from_file
from tools.semantic_harness.ui.shell import SemanticHarnessApp


FIXTURES_ROOT = Path(__file__).resolve().parents[1] / "fixtures" / "v1"


class WorkerSessionUITests(unittest.TestCase):
    def test_closed_gui_ignores_late_future_callback(self) -> None:
        app = SemanticHarnessApp.__new__(SemanticHarnessApp)
        app.closed = True
        app.root = Mock()
        future = Mock(spec=Future)
        callback = Mock()

        SemanticHarnessApp._poll_future(app, future, callback)

        future.done.assert_not_called()
        future.result.assert_not_called()
        app.root.after.assert_not_called()
        callback.assert_not_called()


class HermeticWarmWorkerReuseTests(unittest.TestCase):
    def test_warm_worker_reuse_preserves_conduct_antirepeat_and_hub_suppression(self) -> None:
        cases = [
            *load_cases_from_file(FIXTURES_ROOT / "realization" / "health_wording_authority.json"),
            *load_cases_from_file(FIXTURES_ROOT / "suggestions" / "semantic_hub_and_suggestions.json"),
        ]
        results = execute_cases(
            cases,
            repository=Path(__file__).resolve().parents[4],
        )
        self.assertEqual(len(results), len(cases))
        failures = [res.summary() for res in results if not res.passed]
        self.assertEqual(failures, [])


if __name__ == "__main__":
    unittest.main()
