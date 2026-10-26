"""Dynamic Trading adopts the shared choice-provider contract."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualDynamicTradingP5Tests(unittest.TestCase):
    def test_enabled_trader_contributes_one_authoritative_provider_candidate(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("hello")
            snapshot = worker.snapshot()

        suggestions = result["observation"]["suggestions"]
        provider = next(
            row
            for row in suggestions["choiceRegistry"]["providers"]
            if row["id"] == "dynamictrading.trader"
        )
        candidate = next(
            row
            for row in suggestions["candidates"]
            if row["id"] == "dynamictrading.trade"
        )
        self.assertEqual(provider["sourceKind"], "dynamic_trading")
        self.assertEqual(candidate["providerID"], "dynamictrading.trader")
        self.assertEqual(candidate["source"]["providerID"], "dynamictrading.trader")
        self.assertEqual(
            candidate["frame"]["extensions"],
            {
                "categoryID": "projecthoomans:trade",
                "providerID": "dynamictrading.trader",
                "role": "trader",
                "route": "conversation_category",
                "topic": "trade",
            },
        )
        self.assertEqual(
            candidate["display"]["labelKey"],
            "UI_PNC_Conversation_Suggestion_Trade_Label",
        )
        self.assertEqual(
            candidate["display"]["utteranceKey"],
            "UI_PNC_Conversation_Suggestion_Trade_Utterance",
        )
        self.assertNotIn("budget", candidate)
        self.assertNotIn("stock", candidate)
        self.assertEqual(snapshot["dynamicTradingLoad"]["loaded"], True)

    def test_trade_click_uses_existing_category_authority_and_dt_block(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
        with LuaSemanticWorker(scenario) as worker:
            opened = worker.open_conversation()
            whats_up = next(
                row
                for row in opened["presentation"]["responseChannel"]["rows"]
                if row["id"] == "conversation.landing:whats_up"
            )
            result = worker.suggestion_click(whats_up["semanticFrame"])
            candidate = next(
                row
                for row in result["conversationPresentation"]["responseChannel"]["rows"]
                if row["id"] == "dynamictrading.trade"
            )
            clicked = worker.suggestion_click(candidate["semanticFrame"])

        self.assertTrue(clicked["accepted"])
        self.assertEqual(clicked["reason"], "accepted")
        self.assertEqual(clicked["result"]["ir"]["kind"], "semantic_click_frame")
        self.assertEqual(clicked["toolCalls"], [])
        self.assertEqual(clicked["transport"][0]["command"], "ConversationBlock")
        payload = clicked["transport"][0]["payload"]
        self.assertEqual(payload["blockID"], "dthoomans:trade_basic")
        self.assertEqual(payload["nodeID"], "opening_trade")

    def test_absent_or_disabled_dependency_leaves_ordinary_candidates_unchanged(self) -> None:
        baseline = deepcopy(DEFAULT_SCENARIO)
        cases = [
            ("absent", {}),
            ("disabled", {"DTHoomans": False}),
        ]
        with LuaSemanticWorker(baseline) as worker:
            expected = worker.input("hello")["observation"]["suggestions"]
        expected_ids = [row["id"] for row in expected["candidates"]]

        for label, available_mods in cases:
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["availableMods"] = available_mods
            with self.subTest(case=label), LuaSemanticWorker(scenario) as worker:
                result = worker.input("hello")
                suggestions = result["observation"]["suggestions"]
                provider_ids = {
                    row["id"] for row in suggestions["choiceRegistry"]["providers"]
                }
                candidate_ids = [row["id"] for row in suggestions["candidates"]]

            self.assertNotIn("dynamictrading.trader", provider_ids)
            self.assertNotIn("dynamictrading.trade", candidate_ids)
            self.assertEqual(candidate_ids, expected_ids)

    def test_en_and_tl_keep_semantic_identity_while_resolving_separate_text(self) -> None:
        rows = {}
        for language in ("EN", "TL"):
            scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                result = worker.input("hello")
                rows[language] = next(
                    row
                    for row in result["observation"]["suggestions"]["candidates"]
                    if row["id"] == "dynamictrading.trade"
                )

        self.assertEqual(rows["EN"]["id"], rows["TL"]["id"])
        self.assertEqual(
            rows["EN"]["frame"]["candidateID"],
            rows["TL"]["frame"]["candidateID"],
        )
        self.assertNotEqual(
            rows["EN"]["display"]["label"],
            rows["TL"]["display"]["label"],
        )
        self.assertNotEqual(
            rows["EN"]["display"]["utterance"],
            rows["TL"]["display"]["utterance"],
        )


if __name__ == "__main__":
    unittest.main()
