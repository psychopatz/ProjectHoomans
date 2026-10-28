from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Sandbox/"
    "2026-10-22_15-18-56/global_mod_data.bin"
)
DANA_NPC_ID = "npcDanapatz_Y5KK"
GENERATED_IDS = {
    "generated.apologize",
    "generated.challenge",
    "generated.dismiss",
    "generated.ask_why",
}


def response_channel(turn: dict) -> dict:
    return turn["conversationPresentation"]["responseChannel"]


class LiveRegressionL1Tests(unittest.TestCase):
    def test_direct_responses_are_the_native_visible_surface(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            turn = worker.input("fuckyouuuu")

        suggestions = turn["observation"]["suggestions"]
        generated = {
            row["id"]
            for row in suggestions["candidates"]
            if row.get("providerID")
            == "projecthoomans.generated_affordances"
        }
        self.assertTrue(GENERATED_IDS.issubset(generated))
        self.assertEqual(suggestions["currentGroupID"], "conversation_branch")

        channel = response_channel(turn)
        self.assertEqual(channel["groupID"], "conversation_branch")
        self.assertEqual(
            channel["choiceSurface"]["source"],
            "semantic_suggestions",
        )
        visible = {row["id"] for row in channel["rows"]}
        self.assertTrue(GENERATED_IDS.issubset(visible))
        self.assertNotIn("conversation.root:menu:goodbye", visible)

        for row in channel["rows"]:
            if row["id"] not in GENERATED_IDS:
                continue
            frame = row["frame"]
            self.assertEqual(frame["kind"], "semantic_click_frame")
            self.assertEqual(
                frame["providerID"],
                "projecthoomans.generated_affordances",
            )

    def test_back_navigation_restores_authored_landing_surface(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            hostile = worker.input("fuckyouuuu")
            channel = response_channel(hostile)
            back = next(
                row for row in channel["rows"]
                if row["frame"]["kind"] == "semantic_back_click_frame"
            )
            returned = worker.suggestion_click(back["frame"])

        root = response_channel(returned)
        self.assertEqual(root["groupID"], "conversation_landing")
        visible = {row["id"] for row in root["rows"]}
        self.assertIn("conversation.root:menu:goodbye", visible)
        self.assertIn("conversation.landing:whats_up", visible)
        self.assertNotIn("generated.challenge", visible)

    @unittest.skipUnless(REAL_SAVE.is_file(), "local Dana save unavailable")
    def test_exact_dana_save_exposes_direct_responses(self) -> None:
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
            turn = worker.input("fuckyouuuu")

        self.assertEqual(
            turn["result"]["ir"]["intent"],
            "INSULT",
        )
        self.assertEqual(
            turn["result"]["ir"]["provenance"]["surfaceRecovery"][
                "recoveredSurface"
            ],
            "fuck you",
        )
        channel = response_channel(turn)
        self.assertEqual(channel["groupID"], "conversation_branch")
        self.assertTrue(
            GENERATED_IDS.issubset(
                {row["id"] for row in channel["rows"]}
            )
        )


if __name__ == "__main__":
    unittest.main()
