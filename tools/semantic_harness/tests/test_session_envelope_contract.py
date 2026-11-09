from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SessionEnvelopeContractTests(unittest.TestCase):
    def test_inspector_and_mutation_envelope_boundaries(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            response = worker.snapshot()
            snapshot = response["sessionEnvelope"]
            self.assertEqual(
                snapshot["schema"],
                "semantic.harness_session_envelope.v1",
            )
            self.assertIsNotNone(snapshot["source"].get("data"))
            self.assertIn("working", snapshot)
            self.assertEqual(
                response["sourceSnapshot"]["data"],
                snapshot["source"]["data"],
            )
            self.assertEqual(
                response["sourceSnapshot"]["providerPayloads"],
                snapshot["providerPayloads"],
            )
            self.assertEqual(
                response["workingWorld"]["effective"],
                snapshot["working"]["effective"],
            )
            self.assertEqual(
                response["workingWorld"]["sourceSnapshotID"],
                snapshot["working"]["sourceID"],
            )
            self.assertEqual(
                response["workingWorld"]["revision"],
                snapshot["working"]["revision"],
            )

            draft = deepcopy(DEFAULT_SCENARIO)
            draft["world"]["timeOfDay"] = 22.0
            configured = worker.configure(draft)
            self.assertTrue(any(
                patch["path"] == "world.timeOfDay"
                and patch["source"] == "HARNESS_MUTATION"
                and patch["baseSource"] == "FIXTURE"
                for patch in configured["workingWorld"]["patches"]
            ))
            compact = configured["sessionEnvelope"]
            self.assertEqual(compact["schema"], snapshot["schema"])
            self.assertIsNone(compact["source"].get("data"))
            self.assertIsNone(compact.get("providerPayloads"))
            self.assertIsNone(compact["working"].get("baseline"))


if __name__ == "__main__":
    unittest.main()
