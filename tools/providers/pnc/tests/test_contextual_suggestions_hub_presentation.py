"""Stale-frame protocol safety for What's Up hub suggestion clicks."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin


class ContextualSuggestionsHubPresentationTests(WarmWorkerTestMixin, unittest.TestCase):
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

    def test_stale_click_rejected_by_frame_generation(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            initial = self._whats_up(worker)
            stale_frame = deepcopy(initial["question.wellbeing"]["frame"])

            changed = worker.input("hello")
            self.assertTrue(changed["accepted"], changed.get("reason"))
            rejected = worker.suggestion_click(stale_frame)
            self.assertFalse(rejected["accepted"])
            self.assertEqual(rejected["reason"], "stale_suggestion")


if __name__ == "__main__":
    unittest.main()
