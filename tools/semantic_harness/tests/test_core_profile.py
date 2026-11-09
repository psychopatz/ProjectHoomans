from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from semantic_harness.activity import ActivityLog
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class CoreProfileTests(unittest.TestCase):
    def test_hoomans_launcher_can_select_core_worker_explicitly(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            activity = ActivityLog(
                path=Path(directory) / "activity.jsonl",
                client="core-profile-test",
            )
            with LuaSemanticWorker(
                merge({}, DEFAULT_SCENARIO),
                profile="core",
                lua_bin="lua",
                activity_log=activity,
            ) as worker:
                self.assertEqual(worker.config.profile, "core")
                self.assertEqual(worker.status()["profile"], "core")
                self.assertEqual(worker.ping()["type"], "pong")
                capabilities = worker.capabilities()
                self.assertEqual(capabilities["profile"], "core")
                self.assertEqual(capabilities["providers"], ["PsychopatzCore"])


if __name__ == "__main__":
    unittest.main()
