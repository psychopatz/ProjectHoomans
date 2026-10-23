"""P12G optional live-profiler provider tests."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.live_profiler_provider import (
    LiveProfilerProvider,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


def _write_live_files(root: Path) -> tuple[Path, Path, bytes]:
    snapshot_path = root / "PsychopatzCore_Profiler_latest.json"
    config_path = root / "PsychopatzCore_Profiler.txt"
    snapshot = {
        "profilerVersion": 1,
        "timestamp": 1234,
        "mode": "DETAILED",
        "source": "ProjectZomboid",
        "runtime": {
            "id": "test-live-runtime",
            "configFingerprint": "test-fingerprint",
            "capture": {"performance": True, "moddata": False, "npc": False},
        },
        "world": {
            "weather": "rain",
            "temperature": 12,
            "timeOfDay": 18.5,
            "ignoredLargeList": list(range(100)),
        },
    }
    snapshot_path.write_text(json.dumps(snapshot), encoding="utf-8")
    config_path.write_text(
        "config_version=2\nmode=DETAILED\ncapture=performance\n",
        encoding="utf-8",
    )
    return snapshot_path, config_path, snapshot_path.read_bytes()


class LiveProfilerProviderTests(unittest.TestCase):
    def test_provider_is_disabled_by_default_and_has_no_write_surface(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            snapshot_path, config_path, _ = _write_live_files(Path(temporary))
            provider = LiveProfilerProvider(
                core_repository=CORE_REPOSITORY,
                snapshot_path=snapshot_path,
                config_path=config_path,
            )
            disabled = provider.catalog()
            self.assertFalse(disabled["enabled"])
            self.assertFalse(disabled["available"])
            self.assertEqual(disabled["reason"], "disabled_by_default")
            self.assertIn("GET_SNAPSHOT", disabled["allowedOperations"])
            self.assertIn("SET_WEATHER", disabled["forbiddenOperations"])
            self.assertFalse(hasattr(provider, "send_command"))
            self.assertFalse(hasattr(provider, "mutate"))

            forbidden = provider.project(operation="SET_WEATHER")
            self.assertEqual(forbidden["reason"], "forbidden_operation")

    def test_explicit_live_enrichment_is_bounded_and_does_not_write_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            snapshot_path, config_path, snapshot_bytes = _write_live_files(
                Path(temporary)
            )
            provider = LiveProfilerProvider(
                core_repository=CORE_REPOSITORY,
                snapshot_path=snapshot_path,
                config_path=config_path,
                enabled=True,
            )
            projection = provider.project()
            self.assertTrue(projection["available"])
            self.assertEqual(projection["source"], "LIVE")
            self.assertEqual(projection["values"]["world"]["weather"], "rain")
            self.assertLessEqual(
                len(projection["values"]["world"]["ignoredLargeList"]), 33
            )

            with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
                response = worker.enrich_from_live_profiler(
                    enabled=True,
                    snapshot_path=snapshot_path,
                    config_path=config_path,
                )
                self.assertTrue(response["imported"])
                self.assertIn("world.weather", response["enrichedPaths"])
                self.assertEqual(worker.scenario["world"]["weather"], "rain")
                self.assertEqual(
                    worker.source_snapshot.to_dict()["provenance"]["paths"][
                        "world.weather"
                    ]["source"],
                    "LIVE",
                )
                worker.reset_working_world()
                self.assertEqual(worker.scenario["world"]["weather"], "rain")
            self.assertEqual(snapshot_path.read_bytes(), snapshot_bytes)


if __name__ == "__main__":
    unittest.main()
