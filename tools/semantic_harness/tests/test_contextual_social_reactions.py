"""Phase 3 bounded social-reaction probes on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


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
                "UI_PNC_Conversation_Content_SemanticSocialApologyDefaultNeutral01",
                "neutral",
            ),
            (
                "friendly",
                {
                    "traits": {"friendly": True},
                },
                "semantic.social.apology.friendly",
                "UI_PNC_Conversation_Content_SemanticSocialApologyFriendlyWarm01",
                "friendly",
            ),
            (
                "manual_state_is_not_authority",
                {
                    "traits": {"reserved": True},
                    "relationshipState": "Member",
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.apology.default",
                "UI_PNC_Conversation_Content_SemanticSocialApologyDefaultNeutral01",
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
                "UI_PNC_Conversation_Content_SemanticSocialApologyStressedNeutral01",
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
                "UI_PNC_Conversation_Content_SemanticSocialApologyStressedWarm01",
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
                {"traits": {"friendly": True}},
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
                    "semantic.social.hostile_boundary",
                )
                self.assertEqual(len(result["messages"]), 1)
                self.assertEqual(
                    result["messages"][0]["payload"]["realizationFamily"],
                    "semantic.social.hostile_boundary",
                )
                self.assertEqual(result["llmCalls"], 0)
                self.assertEqual(result["toolCalls"], [])

    def test_typoed_hostility_keeps_recognized_social_route(self) -> None:
        with LuaSemanticWorker(self.scenario({})) as worker:
            result = worker.input("fuck ypuuuu")
        self.assertTrue(result["accepted"], result.get("reason"))
        ir = result["result"]["ir"]
        self.assertEqual(ir["intent"], "HOSTILE_REMARK")
        self.assertEqual(ir["speechAct"], "HOSTILE_REMARK")
        self.assertEqual(ir["provenance"]["pattern"], "pnc.social.profanity")
        self.assertTrue(ir["diagnostics"]["unresolvedEntity"])
        self.assertGreaterEqual(ir["confidence"], 0.85)
        self.assertEqual(
            result["result"]["decision"]["branch"],
            "HOSTILE_REMARK_RECEIVED",
        )
        self.assertNotEqual(
            result["result"]["decision"]["response"]["templateID"],
            "semantic.ask_clarification",
        )
        self.assertNotEqual(
            result["messages"][0]["payload"]["text"],
            "I'm not sure what you mean.",
        )
        action = result["result"]["actionResult"]
        self.assertTrue(action["accepted"], action)
        self.assertEqual(action["status"], "applied")
        self.assertEqual(action["speechAct"], "HOSTILE_REMARK")
        self.assertLess(action["relationshipDelta"]["approval"], 0)

    def test_rejected_and_unavailable_insults_are_truthful_and_social_specific(self) -> None:
        denied_scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "runtime": {
                        "conversationLease": {"token": "authority-token"},
                    },
                },
                "conversation": {"token": "client-token"},
            },
        )
        with LuaSemanticWorker(denied_scenario) as worker:
            denied = worker.input("fuck you")
        denied_action = denied["result"]["actionResult"]
        self.assertFalse(denied_action["accepted"])
        self.assertEqual(denied_action["status"], "rejected")
        self.assertEqual(denied_action["reason"], "invalid_lease")
        self.assertEqual(denied_action["authority"], "server")
        self.assertEqual(
            denied["messages"][0]["payload"]["key"],
            "semantic.social.interaction.rejected",
        )
        self.assertNotEqual(
            denied["messages"][0]["payload"]["text"],
            "I couldn't do that right now.",
        )
        self.assertEqual(denied["relationshipBefore"], denied["relationshipAfter"])

        unavailable = self.scenario({})
        unavailable["runtime"]["socialTransportAvailable"] = False
        with LuaSemanticWorker(unavailable) as worker:
            missing_transport = worker.input("fuck you")
        unavailable_action = missing_transport["result"]["actionResult"]
        self.assertFalse(unavailable_action["accepted"])
        self.assertEqual(
            unavailable_action["status"],
            "semantic_social_dispatch_unavailable",
        )
        self.assertEqual(
            unavailable_action["reason"],
            "semantic_social_transport_unavailable",
        )
        self.assertEqual(
            missing_transport["messages"][0]["payload"]["key"],
            "semantic.social.interaction.unavailable",
        )
        self.assertEqual(missing_transport["transport"], [])
        self.assertEqual(missing_transport["relationshipBefore"],
                         missing_transport["relationshipAfter"])

    def test_self_directed_insult_does_not_dispatch_social_authority(self) -> None:
        with LuaSemanticWorker(self.scenario({})) as worker:
            result = worker.input("I'm an idiot")
        self.assertEqual(result["result"]["ir"]["intent"], "SELF_REFLECTION")
        self.assertEqual(
            result["result"]["decision"]["branch"],
            "SELF_REFLECTION_RECEIVED",
        )
        self.assertIsNone(result["result"].get("actionResult"))
        self.assertEqual(result["transport"], [])

    def test_social_rejection_translation_is_available_in_tl(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "runtime": {"language": "TL", "socialTransportAvailable": False},
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("fuck you")
        self.assertEqual(
            result["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_SocialInteractionUnavailable",
        )
        self.assertNotEqual(
            result["messages"][0]["payload"]["text"],
            result["messages"][0]["payload"]["fallback"],
        )

    def test_threat_uses_guarded_emotion_relationship_and_precedence(self) -> None:
        cases = (
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
                None,
                "friendly",
            ),
            (
                "withdrawn",
                {"personality": {"socialStyle": "withdrawn"}},
                "semantic.social.offer_withdrawn",
                None,
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
                None,
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
                payload = result["messages"][0]["payload"]
                self.assertEqual(
                    payload.get("semanticTemplateID"),
                    actual_template,
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
                None,
                "friendly",
            ),
            (
                "withdrawn",
                {"personality": {"socialStyle": "withdrawn"}},
                "semantic.social.dispute_withdrawn",
                None,
                "withdrawn",
            ),
            (
                "stressed",
                {
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "semantic.social.dispute_stressed",
                None,
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
                    result["messages"][0]["payload"].get("semanticTemplateID"),
                    template,
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

    def test_insult_preview_is_pure_and_does_not_emit_social_effects(self) -> None:
        with LuaSemanticWorker(self.scenario({})) as worker:
            before = worker.snapshot()
            preview = worker.preview("fuck you")
            after = worker.snapshot()
        self.assertTrue(preview["accepted"], preview.get("reason"))
        self.assertEqual(preview["result"]["ir"]["intent"], "INSULT")
        self.assertEqual(
            preview["result"]["decision"]["branch"],
            "HOSTILE_REMARK_RECEIVED",
        )
        self.assertIsNone(preview["result"].get("actionResult"))
        self.assertEqual(preview["messages"], [])
        self.assertEqual(preview["transport"], [])
        self.assertEqual(preview["toolCalls"], [])
        self.assertEqual(preview["llmCalls"], 0)
        self.assertEqual(preview["contextBefore"], preview["contextAfter"])
        self.assertEqual(
            {
                key: value
                for key, value in before.items()
                if key not in {"id", "context"}
            },
            {
                key: value
                for key, value in after.items()
                if key not in {"id", "context"}
            },
        )


if __name__ == "__main__":
    unittest.main()
