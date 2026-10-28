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


def candidate(turn: dict, strategy: str) -> dict:
    return next(
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("providerID")
        == "projecthoomans.generated_affordances"
        and row.get("strategy") == strategy
    )


class LiveRegressionL3Tests(unittest.TestCase):
    def test_claim_joke_is_typed_repair_not_display_text_reparse(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            hostile = worker.input("fuckyouuuu")
            joke = candidate(hostile, "CLAIM_JOKE")
            resolved = worker.suggestion_click(joke["frame"])

        self.assertEqual(joke["display"]["utterance"], "I was joking.")
        self.assertEqual(joke["stance"], "POSITIVE")
        self.assertTrue(joke["frame"]["modifiers"]["joking"])
        self.assertEqual(
            resolved["result"]["ir"]["provenance"]["parser"],
            "semantic_click_frame",
        )
        self.assertEqual(
            (
                resolved["result"]["ir"]["intent"],
                resolved["result"]["ir"]["speechAct"],
            ),
            ("APOLOGIZE", "APOLOGIZE"),
        )
        self.assertEqual(
            resolved["observation"]["director"]["entered"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            resolved["observation"]["interactionPlan"]["behaviorID"],
            "behavior.reconcile",
        )

    def test_double_down_is_typed_hostility_and_keeps_argument_beat(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            hostile = worker.input("fuckyouuuu")
            double_down = candidate(hostile, "DOUBLE_DOWN")
            resolved = worker.suggestion_click(double_down["frame"])

        self.assertEqual(
            double_down["display"]["utterance"],
            "Yeah, I meant it.",
        )
        self.assertEqual(double_down["stance"], "NEGATIVE")
        self.assertTrue(double_down["frame"]["modifiers"]["doubledDown"])
        self.assertEqual(
            (
                resolved["result"]["ir"]["intent"],
                resolved["result"]["ir"]["speechAct"],
            ),
            ("HOSTILE_REMARK", "HOSTILE_REMARK"),
        )
        active = resolved["observation"]["director"]["contextAfter"]["active"]
        self.assertEqual(active["id"], "beat.argument_escalation")

    @unittest.skipUnless(REAL_SAVE.is_file(), "local Dana save unavailable")
    def test_exact_dana_surface_has_repair_escalation_and_neutral_choices(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.import_saved_selection(REAL_SAVE, npc_id=DANA_NPC_ID)
            worker.open_conversation()
            turn = worker.input("fuckyouuuu")

        channel = turn["conversationPresentation"]["responseChannel"]
        self.assertEqual(channel["groupID"], "conversation_branch")
        visible = {row["id"]: row["text"] for row in channel["rows"]}
        self.assertEqual(
            visible["generated.claim_joke"],
            "I was joking.",
        )
        self.assertEqual(
            visible["generated.double_down"],
            "Yeah, I meant it.",
        )
        self.assertEqual(
            visible["generated.apologize"],
            "I'm sorry.",
        )
        self.assertEqual(
            visible["generated.dismiss"],
            "Whatever.",
        )

    def test_en_tl_new_strategies_are_locale_owned(self) -> None:
        expected = {
            "EN": {
                "CLAIM_JOKE": "I was joking.",
                "DOUBLE_DOWN": "Yeah, I meant it.",
            },
            "TL": {
                "CLAIM_JOKE": "Nagbibiro lang ako.",
                "DOUBLE_DOWN": "Oo, sinadya ko 'yon.",
            },
        }
        for language, values in expected.items():
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                turn = worker.input("fuckyouuuu")
            for strategy, text in values.items():
                self.assertEqual(
                    candidate(turn, strategy)["display"]["utterance"],
                    text,
                )


if __name__ == "__main__":
    unittest.main()
