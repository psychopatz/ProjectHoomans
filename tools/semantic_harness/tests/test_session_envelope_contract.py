from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SessionEnvelopeContractTests(unittest.TestCase):
    def test_inspector_and_mutation_envelope_boundaries(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            snapshot = worker.snapshot()["sessionEnvelope"]
            self.assertEqual(
                snapshot["schema"],
                "semantic.harness_session_envelope.v1",
            )
            self.assertIsNotNone(snapshot["source"].get("data"))
            self.assertIn("working", snapshot)

            compact = worker.configure(deepcopy(DEFAULT_SCENARIO))[
                "sessionEnvelope"
            ]
            self.assertEqual(compact["schema"], snapshot["schema"])
            self.assertIsNone(compact["source"].get("data"))
            self.assertIsNone(compact.get("providerPayloads"))
            self.assertIsNone(compact["working"].get("baseline"))


if __name__ == "__main__":
    unittest.main()
