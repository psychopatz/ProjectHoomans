"""Health wording-shard migration contracts."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[4]
MANIFEST = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
HEALTH_IDS = (
    "semantic.question.health_state.injured",
    "semantic.question.health_state.healthy",
    "semantic.question.health_state.unknown",
)
STYLES = ("neutral", "warm", "terse", "guarded")
LEGACY_KEYS = {
    "UI_PNC_Conversation_Semantic_QuestionHealthStateInjured",
    "UI_PNC_Conversation_Semantic_QuestionHealthStateHealthy",
    "UI_PNC_Conversation_Semantic_QuestionHealthStateUnknown",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateInjuredNeutral",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateInjuredWarm",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateInjuredTerse",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateInjuredGuarded",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateHealthyNeutral",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateHealthyWarm",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateHealthyTerse",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateHealthyGuarded",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateUnknownNeutral",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateUnknownWarm",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateUnknownTerse",
    "UI_PNC_Conversation_Semantic_RealizationHealthStateUnknownGuarded",
}
EXPECTED = {
    "EN": {
        "conversation.content.semantic.question.health_state.healthy.guarded.01": "I'm fine. Don't make a thing of it.",
        "conversation.content.semantic.question.health_state.healthy.neutral.01": "I'm doing okay.",
        "conversation.content.semantic.question.health_state.healthy.terse.01": "I'm okay.",
        "conversation.content.semantic.question.health_state.healthy.warm.01": "I'm doing okay. Thanks for checking in.",
        "conversation.content.semantic.question.health_state.injured.guarded.01": "I'm hurt. Give me space.",
        "conversation.content.semantic.question.health_state.injured.neutral.01": "I'm hurt, but I'm managing.",
        "conversation.content.semantic.question.health_state.injured.terse.01": "I'm hurt.",
        "conversation.content.semantic.question.health_state.injured.warm.01": "I'm hurt, but I'm managing. Thanks for asking.",
        "conversation.content.semantic.question.health_state.unknown.guarded.01": "I can't confirm that.",
        "conversation.content.semantic.question.health_state.unknown.neutral.01": "I can't confirm my health status right now.",
        "conversation.content.semantic.question.health_state.unknown.terse.01": "Can't confirm.",
        "conversation.content.semantic.question.health_state.unknown.warm.01": "I can't confirm it right now, but thanks for asking.",
        "conversation.content.semantic.question.medical_bite.negative.guarded.01": "No bite. Leave it there.",
        "conversation.content.semantic.question.medical_bite.negative.neutral.01": "No, I don't have a recorded bite.",
        "conversation.content.semantic.question.medical_bite.negative.terse.01": "No bite.",
        "conversation.content.semantic.question.medical_bite.negative.warm.01": "No, I don't have a recorded bite. Thanks for checking.",
        "conversation.content.semantic.question.medical_bite.positive.guarded.01": "Yes. I've been bitten. That's all.",
        "conversation.content.semantic.question.medical_bite.positive.neutral.01": "Yes, I've been bitten.",
        "conversation.content.semantic.question.medical_bite.positive.terse.01": "Yes. I've been bitten.",
        "conversation.content.semantic.question.medical_bite.positive.warm.01": "Yes. I've been bitten, and I appreciate you checking.",
        "conversation.content.semantic.question.medical_bite.unknown.guarded.01": "I can't confirm that. Don't press me.",
        "conversation.content.semantic.question.medical_bite.unknown.neutral.01": "I can't confirm whether I've been bitten.",
        "conversation.content.semantic.question.medical_bite.unknown.terse.01": "Can't confirm.",
        "conversation.content.semantic.question.medical_bite.unknown.warm.01": "I can't confirm it, but thanks for checking."
    },
    "TL": {
        "conversation.content.semantic.question.health_state.healthy.guarded.01": "Mabuti ako. Huwag mo nang palakihin.",
        "conversation.content.semantic.question.health_state.healthy.neutral.01": "Ayos lang ako.",
        "conversation.content.semantic.question.health_state.healthy.terse.01": "Ayos lang.",
        "conversation.content.semantic.question.health_state.healthy.warm.01": "Ayos lang ako. Salamat sa pagsuri.",
        "conversation.content.semantic.question.health_state.injured.guarded.01": "Nasaktan ako. Bigyan mo ako ng espasyo.",
        "conversation.content.semantic.question.health_state.injured.neutral.01": "Nasaktan ako, pero kinakaya ko.",
        "conversation.content.semantic.question.health_state.injured.terse.01": "Nasaktan ako.",
        "conversation.content.semantic.question.health_state.injured.warm.01": "Nasaktan ako, pero kinakaya ko. Salamat sa pagtatanong.",
        "conversation.content.semantic.question.health_state.unknown.guarded.01": "Hindi ko makumpirma iyon.",
        "conversation.content.semantic.question.health_state.unknown.neutral.01": "Hindi ko makumpirma ang kalagayan ko ngayon.",
        "conversation.content.semantic.question.health_state.unknown.terse.01": "Hindi makumpirma.",
        "conversation.content.semantic.question.health_state.unknown.warm.01": "Hindi ko makumpirma ngayon, pero salamat sa pagtatanong.",
        "conversation.content.semantic.question.medical_bite.negative.guarded.01": "Walang kagat. Tama na.",
        "conversation.content.semantic.question.medical_bite.negative.neutral.01": "Hindi, wala akong naitalang kagat.",
        "conversation.content.semantic.question.medical_bite.negative.terse.01": "Walang kagat.",
        "conversation.content.semantic.question.medical_bite.negative.warm.01": "Hindi, wala akong naitalang kagat. Salamat sa pagsuri.",
        "conversation.content.semantic.question.medical_bite.positive.guarded.01": "Oo. Nakagat ako. Tama na.",
        "conversation.content.semantic.question.medical_bite.positive.neutral.01": "Oo, nakagat ako.",
        "conversation.content.semantic.question.medical_bite.positive.terse.01": "Oo. Nakagat ako.",
        "conversation.content.semantic.question.medical_bite.positive.warm.01": "Oo. Nakagat ako, at salamat sa pagsuri.",
        "conversation.content.semantic.question.medical_bite.unknown.guarded.01": "Hindi ko makumpirma. Huwag mo nang ipilit.",
        "conversation.content.semantic.question.medical_bite.unknown.neutral.01": "Hindi ko makumpirma kung nakagat ako.",
        "conversation.content.semantic.question.medical_bite.unknown.terse.01": "Hindi makumpirma.",
        "conversation.content.semantic.question.medical_bite.unknown.warm.01": "Hindi ko makumpirma, pero salamat sa pagsuri."
    }
}


class HealthWordingShardTests(unittest.TestCase):
    def test_compiler_owns_health_families_by_health_shard(self) -> None:
        model = compile_conversation_sources(
            REPOSITORY,
            manifest_path=MANIFEST,
        )
        owned = {
            item["semanticTemplateID"]: item
            for item in model["content"]["phraseFamilies"]
            if item["semanticTemplateID"] in HEALTH_IDS
        }
        self.assertEqual(set(owned), set(HEALTH_IDS))
        for item in owned.values():
            self.assertEqual(item["conversationDomain"], "health")
            self.assertEqual(item["sourceShard"], "content/health.json")
            self.assertEqual(item["group"], "facts")
            self.assertEqual(set(item["styles"]), set(STYLES))
            self.assertTrue(all(10 <= len(item["styles"][style]) <= 16 for style in STYLES))

    def test_generated_health_translation_is_complete_and_legacy_keys_are_retired(
        self,
    ) -> None:
        for language, expected in EXPECTED.items():
            with self.subTest(language=language):
                generated = json.loads(
                    (
                        REPOSITORY
                        / "Contents/mods/ProjectHoomans/common/media/translation/"
                        f"{language}/Conversation/Health.json"
                    ).read_text(encoding="utf-8")
                )
                for key, val in expected.items():
                    self.assertEqual(generated.get(key), val)
                for catalog_name in ("Responses", "Realizations"):
                    catalog = json.loads(
                        (
                            REPOSITORY
                            / "Contents/mods/ProjectHoomans/common/media/translation/"
                            f"{language}/Conversation/Semantic/{catalog_name}.json"
                        ).read_text(encoding="utf-8")
                    )
                    self.assertTrue(LEGACY_KEYS.isdisjoint(catalog))

        static_map = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
            "Semantics/PNC_SemanticDialogueInput_Presentation_Responses_"
            "Translation_Keys_Question_Health_State.lua"
        ).read_text(encoding="utf-8")
        status = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/SpeechRealization/Families/Status.lua"
        ).read_text(encoding="utf-8")
        self.assertTrue(LEGACY_KEYS.isdisjoint(static_map))
        self.assertNotIn("HealthStateInjured", status)
        self.assertNotIn("HealthStateHealthy", status)
        self.assertNotIn("HealthStateUnknown", status)

    def test_real_worker_preserves_health_identity_and_no_effects_in_en_tl(
        self,
    ) -> None:
        expected = {
            "EN": {
                "injured": (
                    "conversation.content.semantic.question.health_state.injured.neutral.01",
                    "I'm hurt, but I'm managing.",
                ),
                "healthy": (
                    "conversation.content.semantic.question.health_state.healthy.neutral.01",
                    "I'm doing okay.",
                ),
                "unknown": (
                    "conversation.content.semantic.question.health_state.unknown.neutral.01",
                    "I can't confirm my health status right now.",
                ),
            },
            "TL": {
                "injured": (
                    "conversation.content.semantic.question.health_state.injured.neutral.01",
                    "Nasaktan ako, pero kinakaya ko.",
                ),
                "healthy": (
                    "conversation.content.semantic.question.health_state.healthy.neutral.01",
                    "Ayos lang ako.",
                ),
                "unknown": (
                    "conversation.content.semantic.question.health_state.unknown.neutral.01",
                    "Hindi ko makumpirma ang kalagayan ko ngayon.",
                ),
            },
        }
        for language, states in expected.items():
            for health_state, (key, text) in states.items():
                with self.subTest(language=language, health_state=health_state):
                    scenario = merge(
                        DEFAULT_SCENARIO,
                        {
                            "runtime": {"language": language},
                            "npc": {
                                "healthState": health_state,
                                "needs": {},
                                "conditionStats": {},
                            },
                        },
                    )
                    with LuaSemanticWorker(scenario) as worker:
                        turn = worker.input("Are you hurt?")
                    response = turn["result"]["decision"]["response"]
                    payload = turn["messages"][0]["payload"]
                    self.assertTrue(turn["accepted"], turn.get("reason"))
                    self.assertEqual(turn["result"]["ir"]["subject"], "NPC_HEALTH_STATE")
                    self.assertEqual(
                        response["templateID"],
                        f"semantic.question.health_state.{health_state}",
                    )
                    self.assertEqual(response["sourcePoolID"], "semantic.question.health_state")
                    self.assertEqual(response["dialogueAct"], "FACT_ANSWER")
                    self.assertEqual(
                        response["groundedFactRefs"],
                        [] if health_state == "unknown" else ["npc.healthState"],
                    )
                    self.assertEqual(payload["translationKey"], key)
                    self.assertEqual(payload["text"], text)
                    self.assertEqual(turn["dispatchTransport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["noGameplayEffects"])


if __name__ == "__main__":
    unittest.main()
