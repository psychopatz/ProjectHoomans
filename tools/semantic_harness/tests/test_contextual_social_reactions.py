"""Phase 3 bounded social-reaction probes on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualSocialReactionTests(unittest.TestCase):
    @staticmethod
    def scenario(npc: dict) -> dict:
        return merge(DEFAULT_SCENARIO, {"npc": npc})

    def assert_apology_turn(
        self,
        turn: dict,
        *,
        template: str,
        translation_key: str,
        social_style: str,
    ) -> None:
        self.assertTrue(turn["accepted"], turn.get("reason"))
        self.assertEqual(turn["result"]["ir"]["intent"], "APOLOGIZE")
        self.assertEqual(turn["result"]["ir"]["speechAct"], "APOLOGIZE")
        self.assertEqual(
            turn["result"]["decision"]["branch"],
            "SOCIAL_ACKNOWLEDGED",
        )
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assertEqual(
            turn["result"]["decision"]["response"]["templateID"],
            template,
        )
        self.assertEqual(
            turn["messages"][0]["payload"]["translationKey"],
            translation_key,
        )
        self.assertEqual(turn["routedSituation"]["social"]["style"], social_style)
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertIsNone(turn["result"].get("actionResult"))
        self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])

    def test_apology_uses_relationship_emotion_and_explicit_precedence(self) -> None:
        cases = (
            (
                "neutral",
                {
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.apology.default",
                "UI_PNC_Conversation_Semantic_ApologyDefault",
                "neutral",
            ),
            (
                "friendly",
                {
                    "traits": {"friendly": True},
                    "relationshipState": "Friend",
                },
                "semantic.social.apology.friendly",
                "UI_PNC_Conversation_Semantic_ApologyFriendly",
                "friendly",
            ),
            (
                "trusted",
                {
                    "traits": {"reserved": True},
                    "relationshipState": "Member",
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.apology.trusted",
                "UI_PNC_Conversation_Semantic_ApologyTrusted",
                "neutral",
            ),
            (
                "stressed",
                {
                    "traits": {"reserved": True},
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.apology.stressed",
                "UI_PNC_Conversation_Semantic_ApologyStressed",
                "neutral",
            ),
            (
                "stress_precedes_friendly",
                {
                    "traits": {"friendly": True},
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "friendly"},
                },
                "semantic.social.apology.stressed",
                "UI_PNC_Conversation_Semantic_ApologyStressed",
                "friendly",
            ),
        )
        for label, npc, template, translation_key, social_style in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input("sorry")
                self.assert_apology_turn(
                    result,
                    template=template,
                    translation_key=translation_key,
                    social_style=social_style,
                )

    def test_existing_social_reactions_remain_local_and_contextual(self) -> None:
        cases = (
            (
                "compliment",
                {"traits": {"friendly": True}, "relationshipState": "Friend"},
                "you look cute",
                "COMPLIMENT_RECEIVED",
                "semantic.social.compliment.friendly",
            ),
            (
                "threat_busy",
                {"activeBehavior": "combat"},
                "I will kill you",
                "THREAT_RECEIVED",
                "semantic.social.threat_busy",
            ),
            (
                "self_reflection_stressed",
                {
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "I'm an idiot",
                "SELF_REFLECTION_RECEIVED",
                "semantic.social.self_reflection.stressed",
            ),
        )
        for label, npc, text, branch, template in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input(text)
                self.assertTrue(result["accepted"], result.get("reason"))
                self.assertEqual(result["result"]["decision"]["branch"], branch)
                self.assertEqual(
                    result["result"]["decision"]["response"]["templateID"],
                    template,
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["transport"], [])
                self.assertEqual(result["toolCalls"], [])
                self.assertEqual(
                    result["relationshipBefore"], result["relationshipAfter"]
                )

    def test_insults_use_the_authoritative_social_boundary_and_visible_response(self) -> None:
        for text in ("fuck you", "you are useless"):
            with self.subTest(text=text):
                with LuaSemanticWorker(self.scenario({})) as worker:
                    result = worker.input(text)
                self.assertTrue(result["accepted"], result.get("reason"))
                self.assertEqual(result["result"]["ir"]["intent"], "INSULT")
                self.assertEqual(
                    result["result"]["decision"]["branch"],
                    "HOSTILE_REMARK_RECEIVED",
                )
                action = result["result"]["actionResult"]
                self.assertTrue(action["accepted"], action)
                self.assertEqual(action["status"], "applied")
                self.assertEqual(action["eventType"], "player_dialogue_insult")
                self.assertLess(action["relationshipDelta"]["approval"], 0)
                self.assertLess(action["relationshipDelta"]["respect"], 0)
                self.assertEqual(
                    result["result"]["decision"]["response"]["templateID"],
                    "semantic.social.hostile_withdrawn",
                )
                self.assertEqual(len(result["messages"]), 1)
                self.assertEqual(
                    result["messages"][0]["payload"]["key"],
                    "semantic.social.hostile_withdrawn",
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["toolCalls"], [])

    def test_threat_uses_guarded_emotion_relationship_and_precedence(self) -> None:
        cases = (
            (
                "trusted",
                {
                    "traits": {"reserved": True},
                    "relationshipState": "Member",
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.threat_trusted",
                "neutral",
            ),
            (
                "withdrawn",
                {"personality": {"socialStyle": "withdrawn"}},
                "semantic.social.threat_withdrawn",
                "withdrawn",
            ),
            (
                "stressed",
                {
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.threat_stressed",
                "neutral",
            ),
            (
                "stress_precedes_withdrawn_and_busy",
                {
                    "activeBehavior": "combat",
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "withdrawn"},
                },
                "semantic.social.threat_stressed",
                "withdrawn",
            ),
        )
        for label, npc, template, social_style in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input("I will kill you")
                self.assertTrue(result["accepted"], result.get("reason"))
                self.assertEqual(result["result"]["ir"]["intent"], "THREATEN")
                self.assertEqual(
                    result["result"]["decision"]["branch"],
                    "THREAT_RECEIVED",
                )
                self.assertEqual(
                    result["result"]["decision"]["route"], "deterministic"
                )
                self.assertEqual(
                    result["result"]["decision"]["response"]["templateID"],
                    template,
                )
                self.assertEqual(len(result["messages"]), 1)
                self.assertEqual(
                    result["messages"][0]["payload"]["key"],
                    template,
                )
                self.assertEqual(
                    result["routedSituation"]["social"]["style"], social_style
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["transport"], [])
                self.assertEqual(result["toolCalls"], [])
                action = result["result"]["actionResult"]
                self.assertTrue(action["accepted"], action)
                self.assertEqual(action["status"], "applied")
                self.assertEqual(action["eventType"], "player_dialogue_threat")
                self.assertLess(action["relationshipDelta"]["approval"], 0)
                self.assertLess(action["relationshipDelta"]["respect"], 0)

    def test_offer_uses_emotion_hunger_and_social_context(self) -> None:
        cases = (
            (
                "friendly",
                {"personality": {"socialStyle": "friendly"}},
                "semantic.social.offer_friendly",
                "UI_PNC_Conversation_Semantic_OfferFriendly",
                "friendly",
            ),
            (
                "trusted",
                {
                    "relationshipState": "Member",
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.offer_trusted",
                "UI_PNC_Conversation_Semantic_OfferTrusted",
                "neutral",
            ),
            (
                "withdrawn",
                {"personality": {"socialStyle": "withdrawn"}},
                "semantic.social.offer_withdrawn",
                "UI_PNC_Conversation_Semantic_OfferWithdrawn",
                "withdrawn",
            ),
            (
                "hungry_preserves_existing_pool",
                {
                    "needs": {"hunger": 0.9},
                    "personality": {"socialStyle": "neutral"},
                },
                {
                    "semantic.offer.hungry",
                    "semantic.offer.dataset.hungry_share",
                    "semantic.offer.dataset.hungry_appreciate",
                },
                None,
                "neutral",
            ),
            (
                "stress_precedes_hunger",
                {
                    "needs": {"hunger": 0.9},
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "friendly"},
                },
                "semantic.social.offer_stressed",
                "UI_PNC_Conversation_Semantic_OfferStressed",
                "friendly",
            ),
        )
        for label, npc, expected_template, translation_key, social_style in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input("want some food")
                self.assertTrue(result["accepted"], result.get("reason"))
                self.assertEqual(result["result"]["ir"]["intent"], "OFFER")
                self.assertEqual(result["result"]["ir"]["speechAct"], "OFFER")
                self.assertEqual(
                    result["result"]["decision"]["branch"], "OFFER_RECEIVED"
                )
                self.assertEqual(
                    result["result"]["decision"]["route"], "deterministic"
                )
                actual_template = result["result"]["decision"]["response"]["templateID"]
                if isinstance(expected_template, set):
                    self.assertIn(actual_template, expected_template)
                else:
                    self.assertEqual(actual_template, expected_template)
                if translation_key is not None:
                    self.assertEqual(
                        result["messages"][0]["payload"]["translationKey"],
                        translation_key,
                    )
                self.assertEqual(
                    result["routedSituation"]["social"]["style"], social_style
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["transport"], [])
                self.assertEqual(result["toolCalls"], [])
                self.assertIsNone(result["result"].get("actionResult"))
                self.assertEqual(
                    result["relationshipBefore"], result["relationshipAfter"]
                )

    def test_dispute_uses_guarded_context_and_preserves_pending_authority(self) -> None:
        cases = (
            (
                "friendly",
                {"personality": {"socialStyle": "friendly"}},
                "semantic.social.dispute_friendly",
                "UI_PNC_Conversation_Semantic_DisputeFriendly",
                "friendly",
            ),
            (
                "trusted",
                {
                    "relationshipState": "Member",
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.dispute_trusted",
                "UI_PNC_Conversation_Semantic_DisputeTrusted",
                "neutral",
            ),
            (
                "withdrawn",
                {"personality": {"socialStyle": "withdrawn"}},
                "semantic.social.dispute_withdrawn",
                "UI_PNC_Conversation_Semantic_DisputeWithdrawn",
                "withdrawn",
            ),
            (
                "stressed",
                {
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.dispute_stressed",
                "UI_PNC_Conversation_Semantic_DisputeStressed",
                "neutral",
            ),
        )
        for label, npc, template, translation_key, social_style in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input("I disagree")
                self.assertTrue(result["accepted"], result.get("reason"))
                self.assertEqual(result["result"]["ir"]["intent"], "DISAGREE")
                self.assertEqual(
                    result["result"]["decision"]["branch"],
                    "SOCIAL_ACKNOWLEDGED",
                )
                self.assertEqual(
                    result["result"]["decision"]["route"], "deterministic"
                )
                self.assertEqual(
                    result["result"]["decision"]["response"]["templateID"],
                    template,
                )
                self.assertEqual(
                    result["messages"][0]["payload"]["translationKey"],
                    translation_key,
                )
                self.assertEqual(
                    result["routedSituation"]["social"]["style"], social_style
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["transport"], [])
                self.assertEqual(result["toolCalls"], [])
                self.assertIsNone(result["result"].get("actionResult"))
                self.assertEqual(
                    result["relationshipBefore"], result["relationshipAfter"]
                )

        with LuaSemanticWorker(
            self.scenario({"personality": {"socialStyle": "friendly"}})
        ) as worker:
            command = worker.input("follow me")
            pending_dispute = worker.input("I disagree")
        self.assertTrue(command["result"]["actionResult"]["accepted"])
        self.assertEqual(
            pending_dispute["result"]["decision"]["response"]["templateID"],
            "semantic.social.refuse_request",
        )
        self.assertEqual(
            pending_dispute["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_RefuseRequest",
        )
        self.assertEqual(pending_dispute["transport"], [])
        self.assertEqual(pending_dispute["toolCalls"], [])
        self.assertEqual(pending_dispute["llmCalls"], 0)
        self.assertEqual(
            pending_dispute["relationshipBefore"],
            pending_dispute["relationshipAfter"],
        )

    def test_apology_preview_is_idempotent_without_relationship_effect(self) -> None:
        scenario = self.scenario({
            "traits": {"friendly": True},
            "relationshipState": "Friend",
        })
        with LuaSemanticWorker(scenario) as worker:
            worker.input("hello")
            before = worker.snapshot()
            preview_one = worker.preview("sorry")
            preview_two = worker.preview("sorry")
            after = worker.snapshot()
        self.assertTrue(preview_one["accepted"], preview_one.get("reason"))
        self.assertTrue(preview_two["accepted"], preview_two.get("reason"))
        self.assertEqual(preview_one["result"], preview_two["result"])
        self.assertEqual(preview_one["contextBefore"], preview_one["contextAfter"])
        self.assertEqual(preview_one["messages"], [])
        self.assertEqual(preview_one["transport"], [])
        self.assertEqual(preview_one["toolCalls"], [])
        self.assertEqual(preview_one["llmCalls"], 0)
        self.assertEqual(
            {key: value for key, value in before.items() if key != "id"},
            {key: value for key, value in after.items() if key != "id"},
        )


if __name__ == "__main__":
    unittest.main()
