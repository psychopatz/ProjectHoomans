"""Stale-frame protocol safety for What's Up hub suggestion clicks."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


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
