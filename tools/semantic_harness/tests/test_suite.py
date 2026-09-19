"""Regression tests for the bounded Lua smoke-suite runner."""

from __future__ import annotations

import sys
import tempfile
import textwrap
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import unittest

from tools.semantic_harness.suite import BoundedLuaTestRunner, run_lua_suite


class BoundedLuaSuiteTests(unittest.TestCase):
    def make_script(self, directory: Path, name: str, body: str) -> Path:
        path = directory / name
        path.write_text(textwrap.dedent(body), encoding="utf-8")
        return path

    def test_output_is_bounded_and_reported(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            script = self.make_script(
                directory,
                "output.lua",
                """
                import sys
                sys.stdout.write("x" * 10000)
                """,
            )
            runner = BoundedLuaTestRunner(directory, executable=sys.executable, max_output_bytes=256)
            result = runner.run_one(script, {}, timeout=2.0)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.status, "passed")
        self.assertLessEqual(len(result.output.encode("utf-8")), 256)
        self.assertTrue(result.output_truncated)

    def test_timeout_is_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            script = self.make_script(
                directory,
                "sleep.lua",
                """
                import time
                time.sleep(1.0)
                """,
            )
            runner = BoundedLuaTestRunner(directory, executable=sys.executable)
            result = runner.run_one(script, {}, timeout=0.05)
        self.assertEqual(result.returncode, 124)
        self.assertEqual(result.status, "timeout")
        self.assertTrue(result.timed_out)

    def test_duplicate_active_test_is_recorded_as_a_conflict(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            script = self.make_script(
                directory,
                "race.lua",
                """
                import time
                time.sleep(0.2)
                """,
            )
            runner = BoundedLuaTestRunner(directory, executable=sys.executable)
            with ThreadPoolExecutor(max_workers=2) as executor:
                futures = [
                    executor.submit(runner.run_one, script, {}, 2.0)
                    for _ in range(2)
                ]
                results = [future.result() for future in futures]
            report = runner.report(results)
        self.assertEqual(len(results), 2)
        self.assertTrue(any(item["kind"] == "concurrent_duplicate_test" for item in report["conflicts"]))

    def test_suite_function_returns_structured_report(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            first = self.make_script(directory, "first.lua", "print('first')")
            second = self.make_script(directory, "second.lua", "print('second')")
            results, report = run_lua_suite(
                [first, second],
                root=directory,
                environment={},
                executable=sys.executable,
                jobs=2,
            )
        self.assertEqual(len(results), 2)
        self.assertTrue(report["ok"])
        self.assertEqual(len(report["results"]), 2)
        self.assertGreaterEqual(len(report["events"]), 4)

    def test_fail_fast_terminates_other_active_processes(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            started = directory / "slow-started"
            slow = self.make_script(
                directory,
                "slow.lua",
                f"""
                from pathlib import Path
                import time
                Path({str(started)!r}).write_text("started")
                time.sleep(4.0)
                """,
            )
            failure = self.make_script(
                directory,
                "failure.lua",
                f"""
                from pathlib import Path
                import time
                started = Path({str(started)!r})
                deadline = time.monotonic() + 2.0
                while not started.exists() and time.monotonic() < deadline:
                    time.sleep(0.01)
                raise SystemExit(1)
                """,
            )

            before = time.monotonic()
            results, report = run_lua_suite(
                [failure, slow],
                root=directory,
                environment={},
                executable=sys.executable,
                timeout=5.0,
                jobs=2,
                fail_fast=True,
            )
            elapsed = time.monotonic() - before
            slow_process_started = started.exists()

        self.assertTrue(slow_process_started)
        self.assertLess(elapsed, 2.0)
        self.assertTrue(any(result.returncode != 0 for result in results))
        self.assertFalse(report["ok"])


if __name__ == "__main__":
    unittest.main()
