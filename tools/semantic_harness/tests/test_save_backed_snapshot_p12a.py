"""P12A source-snapshot and isolated working-world acceptance tests."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.state import (
    HarnessWorkingWorld,
    ImportedSourceSnapshot,
    Provenance,
)
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SnapshotModelTests(unittest.TestCase):
    def test_imported_source_is_immutable_and_working_reset_restores_baseline(self) -> None:
        scenario = merge({}, DEFAULT_SCENARIO)
        source = ImportedSourceSnapshot.from_scenario(
            scenario,
            source=Provenance.SAVE,
            source_id="save:slot-1",
            mode="offline_save",
        )
        baseline = deepcopy(source.to_dict()["data"])
        working = HarnessWorkingWorld(source)

        with self.assertRaises(TypeError):
            source.data["npc"]["relationship"]["approval"] = 90

        working.data["npc"]["relationship"]["approval"] = 90
        patches = working.patches
        self.assertTrue(any(patch["path"].endswith("approval") for patch in patches))
        self.assertTrue(all(
            patch["source"] == Provenance.HARNESS_MUTATION.value
            and patch["baseSource"] == Provenance.SAVE.value
            for patch in patches
        ))
        self.assertEqual(source.to_dict()["data"], baseline)

        working.reset()
        self.assertEqual(working.data, baseline)
        self.assertEqual(working.patches, [])
        self.assertEqual(source.to_dict()["data"], baseline)


class LuaSnapshotAcceptanceTests(unittest.TestCase):
    def test_worker_keeps_source_while_configuring_mutating_and_resetting(self) -> None:
        scenario = merge({}, DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            source_before = deepcopy(worker.source_snapshot.to_dict())
            initial = worker.snapshot()
            self.assertEqual(
                initial["sourceSnapshot"]["metadata"]["sourceKind"],
                Provenance.FIXTURE.value,
            )
            self.assertEqual(
                initial["sourceSnapshot"]["metadata"]["mode"],
                "developer_test",
            )
            self.assertEqual(initial["workingWorld"]["patches"], [])

            configured = merge({}, worker.scenario)
            configured["world"]["weather"] = "rain"
            worker.configure(configured)
            configured_snapshot = worker.snapshot()
            self.assertEqual(
                configured_snapshot["sourceSnapshot"]["metadata"]["sourceKind"],
                Provenance.FIXTURE.value,
            )
            self.assertTrue(any(
                patch["path"] == "world.weather"
                and patch["source"] == Provenance.HARNESS_MUTATION.value
                for patch in configured_snapshot["workingWorld"]["patches"]
            ))

            result = worker.input("here's an apple for you")
            self.assertEqual(
                result["result"]["decision"]["branch"],
                "GIFT_OFFER_DISPATCHED",
            )
            changed = worker.snapshot()
            self.assertTrue(any(
                patch["path"].startswith("npc.inventory")
                or patch["path"].startswith("player.inventory")
                for patch in changed["workingWorld"]["patches"]
            ))
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

            conversation_reset = worker.reset_conversation()
            self.assertTrue(conversation_reset["workingWorld"]["patches"])
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

            reset = worker.reset_working_world()
            self.assertEqual(reset["workingWorld"]["patches"], [])
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)
            self.assertEqual(
                reset["sourceSnapshot"]["metadata"]["sourceKind"],
                Provenance.FIXTURE.value,
            )


if __name__ == "__main__":
    unittest.main()
