"""P12F explicit offline engine-fixture provider tests."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.fixture_provider import OfflineEngineFixtureProvider
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class OfflineFixtureProviderTests(unittest.TestCase):
    def test_engine_values_are_explicit_editable_fixtures(self) -> None:
        projection = OfflineEngineFixtureProvider().catalog(DEFAULT_SCENARIO)
        self.assertEqual(projection["source"], "FIXTURE")
        fields = {field["id"]: field for field in projection["fields"]}
        for field_id in (
            "player.needs",
            "npc.needs",
            "world.timeOfDay",
            "world.weather",
        ):
            self.assertEqual(fields[field_id]["source"], "FIXTURE")
            self.assertTrue(fields[field_id]["editable"])

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
