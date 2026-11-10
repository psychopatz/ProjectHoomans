"""Semantic Lab profile presets exercise the production worker seam."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


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
                snapshot = worker.snapshot()
                diagnostics = snapshot["context"]["categoryDiagnostics"]
                category_ids = {item.get("id") for item in diagnostics}
                dynamic_load = snapshot["dynamicTradingLoad"]
                self.assertEqual(
                    suggestions.get("activeHub"),
                    {"id": "whats_up", "route": "semantic_hub"},
                )
                self.assertNotIn("semantic_hub.whats_up", ids)
                self.assertEqual("FOLLOW" in action_ids, profile == "companion")
                self.assertEqual(dynamic_load["loaded"], profile == "trader")
                self.assertEqual(dynamic_load["requested"], profile == "trader")
                self.assertNotIn("projecthoomans:trade", category_ids)
                self.assertEqual(
                    "dthoomans:caravan_referral" in category_ids,
                    profile == "trader",
                )
            finally:
                worker.close()


if __name__ == "__main__":
    unittest.main()
