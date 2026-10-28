from __future__ import annotations

from copy import deepcopy
import hashlib
from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Sandbox/"
    "2026-10-22_15-18-56/global_mod_data.bin"
)
DANA_NPC_ID = "npcDanapatz_Y5KK"


@unittest.skipUnless(REAL_SAVE.is_file(), "local Dana save unavailable")
class LiveRegressionL2Tests(unittest.TestCase):
    def test_pruned_relationship_memory_does_not_reject_social_reaction(self) -> None:
        source_hash = hashlib.sha256(REAL_SAVE.read_bytes()).digest()
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.import_saved_selection(
                REAL_SAVE,
                npc_id=DANA_NPC_ID,
            )
            worker.open_conversation()
            turn = worker.input("fuckyouuuu")

        action = turn["result"]["actionResult"]
        self.assertTrue(action["accepted"])
        self.assertEqual(action["status"], "applied")
        self.assertEqual(action["reason"], "relationship_clamped")
        self.assertFalse(action["memoryRecorded"])
        self.assertEqual(
            action["relationshipMemoryOutcome"]["status"],
            "pruned",
        )
        self.assertEqual(
            action["relationshipMemoryOutcome"]["reason"],
            "memory_pruned_by_limit",
        )
        self.assertFalse(
            action["relationshipMemoryOutcome"]["durable"]
        )
        self.assertEqual(
            action["conductEvidenceOutcome"]["status"],
            "bounded",
        )

        response = turn["observation"]["response"]
        self.assertNotEqual(
            response.get("semanticTemplateID"),
            "semantic.social.interaction.rejected",
        )
        self.assertNotIn(
            "couldn't apply that social reaction",
            (response.get("text") or "").lower(),
        )
        self.assertEqual(
            turn["conversationPresentation"]["responseChannel"]["groupID"],
            "conversation_branch",
        )
        self.assertEqual(
            hashlib.sha256(REAL_SAVE.read_bytes()).digest(),
            source_hash,
        )


if __name__ == "__main__":
    unittest.main()
