"""Lifecycle and resource-boundary tests for the Python acceptance runner."""

from __future__ import annotations

import os
from pathlib import Path
import signal
import sys
import tempfile
import time
import unittest

from tools.semantic_harness.testing.python_runner import PythonAcceptanceRunner


class PythonAcceptanceRunnerTests(unittest.TestCase):
    def _package(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        package = root / "fake_tests"
        package.mkdir()
        (package / "__init__.py").write_text("", encoding="utf-8")
        return temporary, package

    @staticmethod
    def _write_test(package: Path, name: str, body: str) -> None:
        package.joinpath(f"{name}.py").write_text(body, encoding="utf-8")

    @staticmethod
    def _runner(
        root: Path,
        modules: list[str],
        *,
        jobs: int = 2,
        timeout: float = 5.0,
        exclusive: set[str] | None = None,
        environment: dict[str, str] | None = None,
    ) -> PythonAcceptanceRunner:
        return PythonAcceptanceRunner(
            root,
            python=sys.executable,
            jobs=jobs,
            timeout=timeout,
            tests_root=root / "fake_tests",
            modules=modules,
            module_prefix="fake_tests",
            exclusive_modules=exclusive or set(),
            environment=environment,
        )

    def test_parallelism_is_bounded_by_jobs(self) -> None:
        temporary, package = self._package()
        self.addCleanup(temporary.cleanup)
        body = """
import time
import unittest

class TestModule(unittest.TestCase):
    def test_sleep(self):
        time.sleep(0.15)
"""
        for name in ("a", "b", "c", "d"):
            self._write_test(package, name, body)

        report = self._runner(
            Path(temporary.name),
            [f"fake_tests.{name}" for name in ("a", "b", "c", "d")],
            jobs=2,
        ).run()

        self.assertTrue(report["ok"])
        self.assertEqual(report["summary"], {"PASS": 4, "FAIL": 0, "SKIP": 0, "total": 4})
        self.assertLessEqual(report["maxActiveProcesses"], 2)
        self.assertGreaterEqual(report["maxActiveProcesses"], 1)
        self.assertTrue(all(item["returncode"] == 0 for item in report["modules"]))

    def test_failure_propagates_with_module_result(self) -> None:
        temporary, package = self._package()
        self.addCleanup(temporary.cleanup)
        self._write_test(
            package,
            "failure",
            """
import unittest

class TestModule(unittest.TestCase):
    def test_failure(self):
        self.fail('intentional runner test failure')
""",
        )
        self._write_test(
            package,
            "success",
            """
import unittest

class TestModule(unittest.TestCase):
    def test_success(self):
        pass
""",
        )

        report = self._runner(
            Path(temporary.name),
            ["fake_tests.failure", "fake_tests.success"],
            jobs=1,
        ).run()

        self.assertFalse(report["ok"])
        self.assertEqual(report["summary"]["FAIL"], 1)
        failed = next(item for item in report["modules"] if item["module"].endswith("failure"))
        self.assertEqual(failed["status"], "FAIL")
        self.assertNotEqual(failed["returncode"], 0)
        self.assertIn("intentional runner test failure", failed["output"])

    def test_exclusive_modules_run_after_parallel_lane(self) -> None:
        temporary, package = self._package()
        self.addCleanup(temporary.cleanup)
        body = """
import time
import unittest

class TestModule(unittest.TestCase):
    def test_work(self):
        time.sleep(0.08)
"""
        for name in ("parallel_a", "parallel_b", "exclusive"):
            self._write_test(package, name, body)

        runner = self._runner(
            Path(temporary.name),
            ["fake_tests.parallel_a", "fake_tests.parallel_b", "fake_tests.exclusive"],
            jobs=2,
            exclusive={"exclusive"},
        )
        report = runner.run()

        self.assertTrue(report["ok"])
        self.assertEqual(
            {item["classification"] for item in report["modules"]},
            {"parallel", "exclusive"},
        )
        parallel_finished = [
            event["time"]
            for event in report["events"]
            if event["event"] == "module.finished"
            and event["classification"] == "parallel"
        ]
        exclusive_started = next(
            event["time"]
            for event in report["events"]
            if event["event"] == "module.started"
            and event["classification"] == "exclusive"
        )
        self.assertTrue(parallel_finished)
        self.assertLessEqual(max(parallel_finished), exclusive_started)

    def test_fail_fast_cleans_active_child_process_group(self) -> None:
        temporary, package = self._package()
        self.addCleanup(temporary.cleanup)
        child_pid_file = Path(temporary.name) / "child.pid"
        self._write_test(
            package,
            "failure",
            """
import unittest

class TestModule(unittest.TestCase):
    def test_failure(self):
        self.fail('fail-fast sentinel')
""",
        )
        self._write_test(
            package,
            "long_running",
            """
import os
import subprocess
import sys
import time
import unittest

class TestModule(unittest.TestCase):
    def test_long_running(self):
        child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'])
        with open(os.environ['RUNNER_CHILD_PID_FILE'], 'w', encoding='ascii') as stream:
            stream.write(str(child.pid))
        time.sleep(30)
""",
        )

        runner = self._runner(
            Path(temporary.name),
            ["fake_tests.failure", "fake_tests.long_running"],
            jobs=2,
            timeout=5.0,
            environment={"RUNNER_CHILD_PID_FILE": str(child_pid_file)},
        )
        report = runner.run(fail_fast=True)

        self.assertFalse(report["ok"])
        self.assertTrue(child_pid_file.exists())
        child_pid = int(child_pid_file.read_text(encoding="ascii"))
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline and self._pid_is_live(child_pid):
            time.sleep(0.05)
        self.assertFalse(self._pid_is_live(child_pid), f"child process {child_pid} survived cleanup")

    @staticmethod
    def _pid_is_live(pid: int) -> bool:
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        if sys.platform.startswith("linux"):
            try:
                state = Path(f"/proc/{pid}/stat").read_text(encoding="ascii").split()[2]
            except (FileNotFoundError, OSError, IndexError):
                return False
            return state != "Z"
        return True

    def test_timing_report_contains_slowest_module_and_timeout_fields(self) -> None:
        temporary, package = self._package()
        self.addCleanup(temporary.cleanup)
        self._write_test(
            package,
            "timed",
            """
import time
import unittest

class TestModule(unittest.TestCase):
    def test_timed(self):
        time.sleep(0.12)
""",
        )

        report = self._runner(
            Path(temporary.name),
            ["fake_tests.timed"],
            jobs=1,
        ).run()

        self.assertTrue(report["ok"])
        self.assertEqual(report["slowest"][0]["module"], "fake_tests.timed")
        result = report["modules"][0]
        self.assertGreater(result["elapsed"], 0.0)
        self.assertIn("returncode", result)
        self.assertIn("timedOut", result)
        self.assertFalse(result["timedOut"])


if __name__ == "__main__":
    unittest.main()
