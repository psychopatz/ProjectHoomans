"""Daily What's Up presentation suppression through the production worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualSuggestionsHubPresentationTests(unittest.TestCase):
    @staticmethod
    def _hub_candidates(suggestions: dict) -> dict[str, dict]:
        group = next(
            group
            for group in suggestions.get("groups", [])
            if group.get("id") == "semantic_hub.whats_up"
        )
        return {
            row["id"]: row
            for row in group.get("candidates", [])
            if isinstance(row, dict) and row.get("id")
        }

    def _whats_up(self, worker: LuaSemanticWorker) -> dict[str, dict]:
        response = worker.input("What's up?")
        self.assertTrue(response["accepted"], response.get("reason"))
        suggestions = response["observation"]["suggestions"]
        self.assertEqual(suggestions["currentGroupID"], "semantic_hub.whats_up")
        return self._hub_candidates(suggestions)

    def test_accepted_hub_choice_is_hidden_for_one_npc_until_next_day(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            initial = self._whats_up(worker)
            self.assertIn("question.wellbeing", initial)

            clicked = worker.suggestion_click(
                initial["question.wellbeing"]["frame"]
            )
            self.assertTrue(clicked["accepted"], clicked.get("reason"))

            same_day = self._whats_up(worker)
            self.assertNotIn("question.wellbeing", same_day)
            self.assertIn("question.activity", same_day)

            # Conversation reset/reopen must preserve the presentation cache.
            worker.reset_conversation()
            reopened = self._whats_up(worker)
            self.assertNotIn("question.wellbeing", reopened)

            # The semantic input route remains available despite the hidden
            # button because suppression is not parser or policy state.
            typed = worker.input("How are you feeling?")
            self.assertTrue(typed["accepted"], typed.get("reason"))
            self.assertEqual(typed["result"]["ir"]["subject"], "WELLBEING")

            next_day = deepcopy(DEFAULT_SCENARIO)
            next_day["world"]["worldAgeHours"] += 24
            worker.configure(next_day)
            restored = self._whats_up(worker)
            self.assertIn("question.wellbeing", restored)
        finally:
            worker.close()

    def test_suppression_is_scoped_to_the_npc(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            initial = self._whats_up(worker)
            clicked = worker.suggestion_click(
                initial["question.wellbeing"]["frame"]
            )
            self.assertTrue(clicked["accepted"], clicked.get("reason"))

            other_npc = deepcopy(DEFAULT_SCENARIO)
            other_npc["npc"]["npcID"] = "npc_other"
            worker.configure(other_npc)
            other_choices = self._whats_up(worker)
            self.assertIn("question.wellbeing", other_choices)
        finally:
            worker.close()

    def test_rejected_stale_click_does_not_suppress_hub_choice(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            initial = self._whats_up(worker)
            stale_frame = deepcopy(initial["question.wellbeing"]["frame"])

            changed = worker.input("hello")
            self.assertTrue(changed["accepted"], changed.get("reason"))
            rejected = worker.suggestion_click(stale_frame)
            self.assertFalse(rejected["accepted"])
            self.assertEqual(rejected["reason"], "stale_suggestion")

            current = self._whats_up(worker)
            self.assertIn("question.wellbeing", current)
        finally:
            worker.close()


if __name__ == "__main__":
    unittest.main()
