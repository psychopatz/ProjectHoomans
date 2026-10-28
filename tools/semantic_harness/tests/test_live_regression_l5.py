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
class LiveRegressionL5Tests(unittest.TestCase):
    def test_dana_live_regression_full_visible_chain(self) -> None:
        source_hash = hashlib.sha256(REAL_SAVE.read_bytes()).digest()

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                REAL_SAVE,
                npc_id=DANA_NPC_ID,
            )
            self.assertEqual(
                imported["scenario"]["npc"]["displayName"],
                "Dana patz",
            )
            worker.open_conversation()

            hostile = worker.input("fuckyouuuu")

            ir = hostile["result"]["ir"]
            self.assertEqual(ir["intent"], "INSULT")
            self.assertEqual(ir["speechAct"], "INSULT")
            self.assertEqual(ir["subject"], "RECIPIENT")
            self.assertGreaterEqual(ir["confidence"], 0.85)
            self.assertEqual(
                ir["provenance"]["surfaceRecovery"]["recoveredSurface"],
                "fuck you",
            )

            interaction = hostile["observation"]["interactionPlan"]
            self.assertEqual(
                interaction["behaviorID"],
                "behavior.warn",
            )
            self.assertEqual(
                interaction["dialogueAct"],
                "BOUNDARY_WARNING",
            )

            npc_payload = hostile["messages"][0]["payload"]
            self.assertEqual(
                npc_payload["realizationFamily"],
                "utterance_plan",
            )
            self.assertEqual(
                npc_payload["utterancePlan"]["strategy"],
                "WARN",
            )
            self.assertTrue(
                npc_payload["realizationVariant"].startswith(
                    "construction.en.social.warn_"
                )
            )
            self.assertNotIn(
                "couldn't apply that social reaction",
                npc_payload["text"].lower(),
            )

            action = hostile["result"]["actionResult"]
            self.assertTrue(action["accepted"])
            self.assertEqual(action["status"], "applied")
            self.assertEqual(action["reason"], "relationship_clamped")
            self.assertFalse(action["memoryRecorded"])
            self.assertEqual(
                action["relationshipMemoryOutcome"]["status"],
                "pruned",
            )
            self.assertEqual(
                action["conductEvidenceOutcome"]["status"],
                "bounded",
            )

            channel = hostile["conversationPresentation"][
                "responseChannel"
            ]
            self.assertEqual(channel["groupID"], "conversation_branch")
            visible = {row["id"]: row for row in channel["rows"]}
            for required in (
                "generated.apologize",
                "generated.claim_joke",
                "generated.double_down",
                "generated.challenge",
                "generated.dismiss",
                "generated.ask_why",
            ):
                self.assertIn(required, visible)

            claim_joke = visible["generated.claim_joke"]
            self.assertEqual(
                claim_joke["text"],
                "I was joking.",
            )
            self.assertEqual(
                claim_joke["frame"]["kind"],
                "semantic_click_frame",
            )
            repaired = worker.suggestion_click(claim_joke["frame"])

            repair_ir = repaired["result"]["ir"]
            self.assertEqual(
                repair_ir["provenance"]["parser"],
                "semantic_click_frame",
            )
            self.assertEqual(
                (repair_ir["intent"], repair_ir["speechAct"]),
                ("APOLOGIZE", "APOLOGIZE"),
            )
            director = repaired["observation"]["director"]
            self.assertEqual(
                director["entered"]["id"],
                "beat.reconciliation",
            )
            self.assertEqual(
                repaired["observation"]["interactionPlan"]["behaviorID"],
                "behavior.reconcile",
            )

        self.assertEqual(
            hashlib.sha256(REAL_SAVE.read_bytes()).digest(),
            source_hash,
        )

    def test_en_tl_warn_and_dynamic_choice_semantics_are_locale_independent(
        self,
    ) -> None:
        semantic_rows: dict[str, dict[str, tuple[str, str, str]]] = {}
        npc_realization: dict[str, tuple[str, str]] = {}

        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                worker.open_conversation()
                turn = worker.input("fuckyouuuu")

            npc = turn["messages"][0]["payload"]
            npc_realization[language] = (
                npc["utterancePlan"]["strategy"],
                npc["realizationVariant"],
            )
            semantic_rows[language] = {
                row["id"]: (
                    row["frame"]["intent"],
                    row["frame"]["speechAct"],
                    row["strategy"],
                )
                for row in turn["observation"]["suggestions"]["candidates"]
                if row.get("providerID")
                == "projecthoomans.generated_affordances"
            }

        self.assertEqual(
            semantic_rows["EN"],
            semantic_rows["TL"],
        )
        self.assertEqual(
            npc_realization["EN"][0],
            "WARN",
        )
        self.assertEqual(
            npc_realization["TL"][0],
            "WARN",
        )
        self.assertTrue(
            npc_realization["EN"][1].startswith(
                "construction.en.social.warn_"
            )
        )
        self.assertTrue(
            npc_realization["TL"][1].startswith(
                "construction.tl.social.warn_"
            )
        )


if __name__ == "__main__":
    unittest.main()
