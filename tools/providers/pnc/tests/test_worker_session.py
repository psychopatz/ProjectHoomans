"""Hoomans-specific GUI callback behavior for the Core worker session."""

from __future__ import annotations

from concurrent.futures import Future
from copy import deepcopy
import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import Mock

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.providers.pnc.tests.worker_reuse import (
    WarmWorkerTestMixin,
    close_all_warm_workers,
)
from tools.semantic_harness.testing.executor import execute_cases
from tools.semantic_harness.testing.loader import load_cases_from_file
from tools.semantic_harness.ui.shell import SemanticHarnessApp


FIXTURES_ROOT = Path(__file__).resolve().parents[1] / "fixtures" / "v1"


def _child_lua_worker_pids() -> list[int]:
    result = subprocess.run(
        ["ps", "-o", "pid=,args=", "--ppid", str(os.getpid())],
        capture_output=True,
        text=True,
        check=False,
    )
    pids: list[int] = []
    for line in result.stdout.splitlines():
        stripped = line.strip()
        if not stripped or "worker.lua" not in stripped:
            continue
        pid_text = stripped.split(None, 1)[0]
        if pid_text.isdigit():
            pids.append(int(pid_text))
    return pids


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


class WorkerLifecycleHermeticityTests(unittest.TestCase):
    def test_repeated_start_close_cycles_do_not_accumulate_children(self) -> None:
        baseline = _child_lua_worker_pids()
        for _ in range(3):
            with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
                turn = worker.input("hello")
                self.assertTrue(turn["accepted"])
                self.assertEqual(len(_child_lua_worker_pids()), len(baseline) + 1)
            self.assertEqual(_child_lua_worker_pids(), baseline)

    def test_warm_worker_reuse_returns_to_starting_worker_count(self) -> None:
        close_all_warm_workers()
        baseline = _child_lua_worker_pids()
        try:
            for _ in range(2):
                with WarmWorkerTestMixin.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
                    turn = worker.input("hello")
                    self.assertTrue(turn["accepted"])
                self.assertLessEqual(len(_child_lua_worker_pids()), len(baseline) + 1)
        finally:
            close_all_warm_workers()
        self.assertEqual(_child_lua_worker_pids(), baseline)


if __name__ == "__main__":
    unittest.main()
