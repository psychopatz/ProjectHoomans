"""source-snapshot and isolated working-world acceptance tests."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.state import (
    Provenance,
)
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


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
