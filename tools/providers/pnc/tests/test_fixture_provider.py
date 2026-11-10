"""explicit offline engine-fixture provider tests."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.fixture_provider import OfflineEngineFixtureProvider
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


class OfflineFixtureProviderTests(unittest.TestCase):
    def test_fixture_payload_and_provenance_survive_working_world_mutation(self) -> None:
        scenario = merge({}, DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            initial = worker.snapshot()
            source_before = deepcopy(worker.source_snapshot.to_dict())
            payload = initial["sourceSnapshot"]["providerPayloads"][
                "offline_engine_fixtures"
            ]
            self.assertEqual(payload["source"], "FIXTURE")
            self.assertEqual(
                initial["sourceSnapshot"]["provenance"]["paths"][
                    "world.weather"
                ]["source"],
                "FIXTURE",
            )

            edited = deepcopy(worker.scenario)
            edited["world"]["weather"] = "rain"
            worker.configure(edited)
            changed = worker.snapshot()
            self.assertEqual(changed["scenario"]["world"]["weather"], "rain")
            weather_patch = next(
                patch
                for patch in changed["workingWorld"]["patches"]
                if patch["path"] == "world.weather"
            )
            self.assertEqual(weather_patch["source"], "HARNESS_MUTATION")
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

            worker.reset_working_world()
            reset = worker.snapshot()
            self.assertEqual(reset["scenario"]["world"]["weather"], "clear")
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)


if __name__ == "__main__":
    unittest.main()
