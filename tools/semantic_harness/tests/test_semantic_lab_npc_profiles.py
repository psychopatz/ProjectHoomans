"""Semantic Lab profile presets exercise the production worker seam."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SemanticLabNpcProfileTests(unittest.TestCase):
    def test_presets_replace_capability_specific_state_without_losing_inventory(self) -> None:
        trader = apply_npc_profile(DEFAULT_SCENARIO, "trader")
        self.assertEqual(trader["runtime"]["availableMods"], {"DTHoomans": True})
        self.assertEqual(trader["npc"]["role"], "trader")
        self.assertEqual(
            trader["npc"]["inventory"], DEFAULT_SCENARIO["npc"]["inventory"]
        )

        neutral = apply_npc_profile(trader, "neutral")
        self.assertNotIn("role", neutral["npc"])
        self.assertEqual(neutral["runtime"]["availableMods"], {})

    def test_profiles_change_real_suggestions_and_trade_preflight(self) -> None:
        for profile in ("companion", "neutral", "enemy", "trader"):
            worker = LuaSemanticWorker(
                apply_npc_profile(deepcopy(DEFAULT_SCENARIO), profile)
            )
            try:
                response = worker.input("whats up")
                suggestions = response["observation"]["suggestions"]
                ids = {item["id"] for item in suggestions.get("candidates", [])}
                action_ids = {
                    item["action"]
                    for item in suggestions.get("candidates", [])
                    if item.get("action")
                }
                action_ids.update(
                    item["action"]
                    for item in suggestions.get("permittedCapabilities", [])
                    if item.get("action")
                    and item.get("status") != "requires_destination"
                )
                trade = next(
                    item
                    for item in worker.snapshot()["context"]["categoryDiagnostics"]
                    if item.get("id") == "projecthoomans:trade"
                )
                self.assertEqual("conversation.whats_up" in ids, profile != "enemy")
                self.assertEqual("FOLLOW" in action_ids, profile == "companion")
                self.assertEqual(trade["visible"], profile == "trader")
                self.assertEqual(
                    trade["reason"], "visible" if profile == "trader" else "integration_unavailable"
                )
            finally:
                worker.close()


if __name__ == "__main__":
    unittest.main()
