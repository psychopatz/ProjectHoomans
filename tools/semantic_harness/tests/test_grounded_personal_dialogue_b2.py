"""B2 real-worker coverage for authoritative offline NPC backstory facts."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class GroundedPersonalDialogueB2Tests(unittest.TestCase):
    def test_authoritative_facts_cover_immutable_personal_history(self) -> None:
        kinds = (
            "former_job",
            "hometown",
            "hobby",
            "family",
            "fear",
            "tragedy",
        )
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for kind in kinds:
                with self.subTest(kind=kind):
                    result = worker.backstory_fact(
                        90210, kind, language="EN", npc_id="npc-b2-facts"
                    )
                    self.assertTrue(result["ok"])
                    fact = result["fact"]
                    self.assertEqual(fact["status"], "known")
                    self.assertEqual(fact["kind"], {
                        "family": "family_background",
                    }.get(kind, kind))
                    self.assertTrue(fact["factID"].startswith("backstory."))
                    self.assertTrue(fact["content"])
                    self.assertTrue(fact["immutable"])
                    self.assertEqual(
                        fact["provenance"],
                        "PNC.Conversation.Memory.BackstoryDefinitions",
                    )

            english = worker.backstory_fact(
                90210, "former_job", language="EN", npc_id="npc-b2-facts"
            )["fact"]
            tagalog = worker.backstory_fact(
                90210, "former_job", language="TL", npc_id="npc-b2-facts"
            )["fact"]
            self.assertEqual(english["factID"], tagalog["factID"])
            self.assertNotEqual(english["content"], tagalog["content"])

            worker.restart()
            reloaded = worker.backstory_fact(
                90210, "hometown", language="EN", npc_id="npc-b2-facts"
            )["fact"]

        self.assertEqual(reloaded["status"], "known")
        self.assertTrue(reloaded["content"])


if __name__ == "__main__":
    unittest.main()
