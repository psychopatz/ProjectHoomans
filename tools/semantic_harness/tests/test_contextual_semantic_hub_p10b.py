"""Contextual What's Up hub projection through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_grounded_world_knowledge_gossip import (
    scenario_for as world_gossip_scenario,
)


class ContextualSemanticHubP10BTests(unittest.TestCase):
    @staticmethod
    def _candidate_map(suggestions: dict) -> dict[str, dict]:
        return {
            row["id"]: row
            for row in suggestions.get("candidates", [])
            if isinstance(row, dict) and row.get("id")
        }

    @staticmethod
    def _hub_turn(scenario: dict) -> tuple[dict, dict]:
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            response = worker.input("What's up?")
        suggestions = response["observation"]["suggestions"]
        return response, suggestions

    def test_neutral_survivor_gets_safe_semantic_avenues_and_clicks_on_one_lane(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "neutral")
        with LuaSemanticWorker(scenario) as worker:
            response = worker.input("What's up?")
            suggestions = response["observation"]["suggestions"]
            candidates = self._candidate_map(suggestions)

            self.assertTrue(response["accepted"])
            self.assertEqual(suggestions["activeHub"]["id"], "whats_up")
            self.assertEqual(
                suggestions["currentGroupID"], "semantic_hub.whats_up"
            )
            group = next(
                row for row in suggestions["groups"]
                if row["id"] == "semantic_hub.whats_up"
            )
            self.assertEqual(group["label"], "What's up")
            self.assertIsNone(response["observation"].get("conversationBlock"))
            self.assertEqual(
                response["observation"]["conversationGraph"]["graphKind"],
                "semantic_hub",
            )
            self.assertTrue(
                {"question.wellbeing", "question.activity", "question.weather"}
                <= set(candidates)
            )
            self.assertTrue(
                {
                    "question.needs",
                    "question.health",
                    "question.gossip",
                    "social.personal_check_in",
                }.isdisjoint(candidates)
            )

            activity = candidates["question.activity"]
            self.assertEqual(activity["groupID"], "semantic_hub.whats_up")
            self.assertEqual(
                activity["providerID"], "projecthoomans.static_questions"
            )
            self.assertEqual(
                activity["semanticOwner"], "projecthoomans.semantic.activity"
            )
            self.assertEqual(activity["eligibility"]["status"], "allowed")
            self.assertEqual(
                activity["frame"]["extensions"]["hubAvenue"], True
            )

            clicked = worker.suggestion_click(activity["frame"])

        self.assertTrue(clicked["accepted"], clicked.get("reason"))
        self.assertEqual(clicked["result"]["ir"]["subject"], "ACTIVITY")
        self.assertEqual(
            clicked["result"]["ir"]["provenance"]["parser"],
            "semantic_click_frame",
        )
        self.assertEqual(clicked["transport"], [])

    def test_owned_companion_and_contextual_health_or_needs_ranking(self) -> None:
        companion = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "companion")
        with LuaSemanticWorker(companion) as worker:
            response = worker.input("What's up?")
            candidates = self._candidate_map(
                response["observation"]["suggestions"]
            )
            self.assertTrue(
                {
                    "question.needs",
                    "question.health",
                    "social.personal_check_in",
                }
                <= set(candidates)
            )
            self.assertNotIn("question.gossip", candidates)

            injured = deepcopy(companion)
            injured["npc"]["healthState"] = "injured"
            injured["world"].update(
                {"hunger": 0.9, "thirst": 0.2, "fatigue": 0.1}
            )
            worker.configure(injured)
            injured_suggestions = worker.input("What's up?")["observation"][
                "suggestions"
            ]
            injured_candidates = self._candidate_map(injured_suggestions)
            self.assertEqual(injured_candidates["question.health"]["rank"], 1)

            needs_severe = deepcopy(companion)
            needs_severe["npc"]["needs"].update(
                {"hunger": 0.95, "thirst": 0.9, "fatigue": 0.1}
            )
            worker.configure(needs_severe)
            needs_suggestions = worker.input("What's up?")["observation"][
                "suggestions"
            ]
            needs_candidates = self._candidate_map(needs_suggestions)
            self.assertEqual(needs_candidates["question.needs"]["rank"], 1)

    def test_hub_avenues_resolve_through_english_and_tagalog_catalogs(self) -> None:
        rows = {}
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                scenario = apply_npc_profile(
                    deepcopy(DEFAULT_SCENARIO), "neutral"
                )
                scenario["runtime"]["language"] = language
                _, suggestions = self._hub_turn(scenario)
                candidate = self._candidate_map(suggestions)[
                    "question.activity"
                ]
                rows[language] = candidate["display"]

        self.assertEqual(
            rows["EN"]["labelKey"],
                "UI_PNC_Conversation_Content_ConversationChoiceQuestionActivity_Label",
        )
        self.assertEqual(
            rows["TL"]["labelKey"],
                "UI_PNC_Conversation_Content_ConversationChoiceQuestionActivity_Label",
        )
        self.assertNotEqual(rows["EN"]["label"], rows["TL"]["label"])
        self.assertNotEqual(
            rows["EN"]["utterance"], rows["TL"]["utterance"]
        )

    def test_friend_family_and_lover_depth_requires_current_trust(self) -> None:
        for kind in ("friend", "mother", "lover"):
            with self.subTest(kind=kind):
                scenario = deepcopy(DEFAULT_SCENARIO)
                scenario["npc"]["startingRelationship"] = {
                    "kind": kind,
                    "source": "starting_companion_trait",
                }
                scenario["npc"]["relationship"].update(
                    {"approval": 80, "respect": 70, "familiarity": 80}
                )
                _, suggestions = self._hub_turn(scenario)
                candidates = self._candidate_map(suggestions)
                self.assertIn("social.personal_check_in", candidates)
                self.assertEqual(
                    candidates["social.personal_check_in"]["semanticOwner"],
                    "projecthoomans.semantic.wellbeing",
                )

        guarded = deepcopy(DEFAULT_SCENARIO)
        guarded["npc"]["startingRelationship"] = {
            "kind": "mother",
            "source": "starting_companion_trait",
        }
        guarded["npc"]["relationship"].update(
            {"approval": -80, "respect": -50, "familiarity": 80}
        )
        _, suggestions = self._hub_turn(guarded)
        self.assertNotIn(
            "social.personal_check_in", self._candidate_map(suggestions)
        )

    def test_enemy_hub_keeps_only_public_context_avenue(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "enemy")
        scenario["npc"]["startingRelationship"] = {
            "kind": "lover",
            "source": "starting_companion_trait",
        }
        scenario["npc"]["relationship"].update(
            {"approval": 90, "respect": 80, "familiarity": 100}
        )
        _, suggestions = self._hub_turn(scenario)
        current_group = next(
            group
            for group in suggestions["groups"]
            if group["id"] == suggestions["currentGroupID"]
        )
        self.assertEqual(
            {candidate["id"] for candidate in current_group["candidates"]},
            {"question.weather"},
        )
        self.assertEqual(
            [row["id"] for row in current_group["navigation"]],
            ["semantic.back_to_root:semantic_hub.whats_up"],
        )

    def test_safe_gossip_is_context_gated_and_owned_by_world_knowledge(self) -> None:
        scenario = world_gossip_scenario(
            "alice",
            "EN",
            [
                {
                    "actorID": "actor:alice",
                    "factIndex": 1,
                    "provenance": "witnessed",
                    "confidence": 0.95,
                    "source": "scenario_authority",
                    "acquisitionPath": "scenario_authority",
                }
            ],
        )
        with LuaSemanticWorker(scenario) as worker:
            worker.input("Any gossip?")
            response = worker.input("What's up?")
            suggestions = response["observation"]["suggestions"]
            candidates = self._candidate_map(suggestions)
            gossip = candidates["question.gossip"]
            self.assertEqual(
                gossip["contextReason"], "player_safe_gossip_available"
            )
            self.assertEqual(gossip["semanticOwner"], "projecthoomans.semantic.gossip")
            clicked = worker.suggestion_click(gossip["frame"])

        self.assertTrue(clicked["accepted"], clicked.get("reason"))
        self.assertEqual(clicked["result"]["ir"]["subject"], "GOSSIP")

    def test_dynamic_trading_joins_the_hub_only_through_its_registered_provider(self) -> None:
        trader = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
        with LuaSemanticWorker(trader) as worker:
            response = worker.input("What's up?")
            suggestions = response["observation"]["suggestions"]
            candidates = self._candidate_map(suggestions)
            trade = candidates["dynamictrading.trade"]
            self.assertEqual(trade["providerID"], "dynamictrading.trader")
            self.assertEqual(trade["semanticOwner"], "dynamictrading.trader")
            self.assertEqual(trade["groupID"], "semantic_hub.whats_up")
            self.assertEqual(
                trade["eligibility"]["reason"], "enabled_trader_provider"
            )
            self.assertEqual(
                suggestions["currentGroupID"], "semantic_hub.whats_up"
            )
            clicked = worker.suggestion_click(trade["frame"])

        disabled = deepcopy(DEFAULT_SCENARIO)
        disabled["runtime"]["availableMods"] = {"DTHoomans": False}
        _, suggestions = self._hub_turn(disabled)
        self.assertNotIn("dynamictrading.trade", self._candidate_map(suggestions))

        self.assertTrue(clicked["accepted"], clicked.get("reason"))
        self.assertEqual(clicked["transport"][0]["command"], "ConversationBlock")
        self.assertEqual(
            clicked["transport"][0]["payload"]["blockID"],
            "dthoomans:trade_basic",
        )


if __name__ == "__main__":
    unittest.main()
