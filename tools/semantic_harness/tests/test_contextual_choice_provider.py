"""generic provider discovery and existing authority-lane contracts."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualChoiceProviderTests(unittest.TestCase):
    def test_generic_social_provider_is_discovered_and_clickable(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("hello")
            suggestions = turn["observation"]["suggestions"]
            candidate = next(
                row for row in suggestions["candidates"]
                if row["id"] == "social.check_in"
            )
            self.assertEqual(candidate["providerID"], "projecthoomans.social_context")
            self.assertEqual(candidate["source"]["kind"], "social_context")
            self.assertEqual(candidate["ranking"]["class"], "CONTEXTUAL_SOCIAL")
            self.assertEqual(
                candidate["display"]["labelKey"],
                "UI_PNC_Conversation_Suggestion_CheckIn_Label",
            )
            self.assertEqual(
                candidate["display"]["utteranceKey"],
                "UI_PNC_Conversation_Suggestion_CheckIn_Utterance",
            )
            self.assertNotIn("approval", candidate)
            self.assertNotIn("respect", candidate)
            self.assertNotIn("familiarity", candidate)
            self.assertTrue(
                any(
                    row["id"] == "projecthoomans.social_context"
                    for row in suggestions["choiceRegistry"]["providers"]
                )
            )

            clicked = worker.suggestion_click(candidate["frame"])
            self.assertTrue(clicked["accepted"], clicked.get("reason"))
            self.assertEqual(clicked["result"]["ir"]["intent"], "QUESTION")
            self.assertEqual(clicked["result"]["ir"]["subject"], "WELLBEING")
            self.assertEqual(clicked["dispatchTransport"], [])

    def test_provider_frame_is_stale_safe_and_replay_safe(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("hello")
            candidate = next(
                row for row in first["observation"]["suggestions"]["candidates"]
                if row["id"] == "social.check_in"
            )
            frame = deepcopy(candidate["frame"])
            worker.input("what is your name?")
            stale = worker.suggestion_click(frame)
            self.assertFalse(stale["accepted"])
            self.assertIn("stale", stale["reason"])

            fresh = worker.input("hello")
            fresh_candidate = next(
                row for row in fresh["observation"]["suggestions"]["candidates"]
                if row["id"] == "social.check_in"
            )
            accepted = worker.suggestion_click(fresh_candidate["frame"])
            self.assertTrue(accepted["accepted"])
            replay = worker.suggestion_click(fresh_candidate["frame"])
            self.assertFalse(replay["accepted"])
            self.assertIn(
                replay["reason"], {"suggestion_click_replayed", "duplicate_suggestion"}
            )


if __name__ == "__main__":
    unittest.main()
