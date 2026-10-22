"""P0 freeze tests for the current production suggestion path.

These assertions intentionally describe the existing contract.  They are the
behavioral fence for the later registry/persona refactor, not a new policy
surface.
"""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualDialoguePersonaChoicesP0Tests(unittest.TestCase):
    def test_whats_up_utterance_activates_semantic_hub(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            entered = worker.input("What's up?")

            self.assertTrue(entered["accepted"])
            self.assertEqual(
                entered["result"]["ir"]["extensions"]["route"],
                "semantic_hub",
            )
            self.assertEqual(
                entered["result"]["ir"]["extensions"]["hubID"],
                "whats_up",
            )
            self.assertEqual(
                entered["observation"]["suggestions"]["activeHub"]["id"],
                "whats_up",
            )
            self.assertIsNone(
                entered["observation"].get("conversationBlock")
            )

    def test_active_flow_response_plan_and_capability_rows_keep_one_frame_contract(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello")

        suggestions = result["observation"]["suggestions"]
        candidates = {
            candidate["id"]: candidate
            for candidate in suggestions["candidates"]
        }
        self.assertEqual(candidates["greeting.thanks"]["source"]["kind"], "active_flow")
        self.assertEqual(
            candidates["greeting.check_in.report_wellbeing"]["source"]["kind"],
            "npc_response_plan",
        )
        self.assertEqual(
            candidates["greeting.thanks"]["frame"]["kind"],
            "semantic_click_frame",
        )
        self.assertEqual(
            candidates["greeting.check_in.report_wellbeing"]["frame"]["kind"],
            "semantic_click_frame",
        )

        capabilities = {
            row["action"]: row
            for row in suggestions["permittedCapabilities"]
        }
        self.assertEqual(capabilities["FOLLOW"]["status"], "eligible")
        self.assertEqual(capabilities["FOLLOW"]["frame"]["kind"], "semantic_click_frame")
        self.assertEqual(capabilities["WAIT_AT"]["status"], "requires_destination")

    def test_label_and_utterance_keys_are_distinct_and_language_does_not_change_id(
        self,
    ) -> None:
        observations = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                result = worker.input("Are you okay?")
            row = next(
                candidate
                for candidate in result["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.wellbeing"
            )
            observations[language] = (result, row)

        en_result, en_row = observations["EN"]
        tl_result, tl_row = observations["TL"]
        self.assertEqual(en_row["id"], tl_row["id"])
        self.assertEqual(
            en_row["frame"]["candidateID"],
            tl_row["frame"]["candidateID"],
        )
        self.assertNotEqual(
            en_row["display"]["labelKey"],
            en_row["display"]["utteranceKey"],
        )
        self.assertNotEqual(
            en_row["display"]["label"],
            tl_row["display"]["label"],
        )
        self.assertEqual(en_result["translation"]["language"], "EN")
        self.assertEqual(tl_result["translation"]["language"], "TL")

    def test_stale_duplicate_and_authority_rejection_are_side_effect_free(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("Are you okay?")
            frame = next(
                candidate["frame"]
                for candidate in first["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.needs"
            )
            worker.input("What happened?")
            before_stale = worker.snapshot()
            stale = worker.suggestion_click(frame)
            after_stale = worker.snapshot()

        self.assertFalse(stale["accepted"])
        self.assertEqual(stale["reason"], "stale_suggestion")
        self.assertEqual(before_stale["transcript"], after_stale["transcript"])
        self.assertEqual(before_stale["transport"], after_stale["transport"])

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("Are you okay?")
            follow = next(
                row
                for row in result["observation"]["suggestions"][
                    "permittedCapabilities"
                ]
                if row["action"] == "FOLLOW"
            )
            accepted = worker.suggestion_click(follow["frame"])
            duplicate = worker.suggestion_click(follow["frame"])

        self.assertTrue(accepted["accepted"])
        self.assertEqual(
            accepted["result"]["actionResult"]["capabilityID"],
            "pnc:companion.follow",
        )
        self.assertEqual(len(accepted["transport"]), 1)
        self.assertFalse(duplicate["accepted"])
        self.assertEqual(duplicate["reason"], "duplicate_suggestion")

        non_companion = deepcopy(DEFAULT_SCENARIO)
        non_companion["npc"]["actorAuthority"] = {
            "companion": False,
            "owned": False,
            "eligible": False,
            "status": "not_companion",
        }
        with LuaSemanticWorker(non_companion) as worker:
            result = worker.input("Are you okay?")
        self.assertFalse(
            any(
                row["action"] == "FOLLOW"
                for row in result["observation"]["suggestions"][
                    "permittedCapabilities"
                ]
            )
        )


if __name__ == "__main__":
    unittest.main()
