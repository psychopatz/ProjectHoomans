"""P11B Health wording-shard migration contracts."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
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
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyGuarded01":
            "I'm fine. Don't make a thing of it.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyNeutral01":
            "I'm doing okay.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyTerse01":
            "I'm okay.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyWarm01":
            "I'm doing okay. Thanks for checking in.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredGuarded01":
            "I'm hurt. Give me space.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredNeutral01":
            "I'm hurt, but I'm managing.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredTerse01":
            "I'm hurt.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredWarm01":
            "I'm hurt, but I'm managing. Thanks for asking.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownGuarded01":
            "I can't confirm that.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownNeutral01":
            "I can't confirm my health status right now.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownTerse01":
            "Can't confirm.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownWarm01":
            "I can't confirm it right now, but thanks for asking.",
    },
    "TL": {
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyGuarded01":
            "Mabuti ako. Huwag mo nang palakihin.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyNeutral01":
            "Ayos lang ako.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyTerse01":
            "Ayos lang.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyWarm01":
            "Ayos lang ako. Salamat sa pagsuri.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredGuarded01":
            "Nasaktan ako. Bigyan mo ako ng espasyo.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredNeutral01":
            "Nasaktan ako, pero kinakaya ko.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredTerse01":
            "Nasaktan ako.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredWarm01":
            "Nasaktan ako, pero kinakaya ko. Salamat sa pagtatanong.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownGuarded01":
            "Hindi ko makumpirma iyon.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownNeutral01":
            "Hindi ko makumpirma ang kalagayan ko ngayon.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownTerse01":
            "Hindi makumpirma.",
        "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownWarm01":
            "Hindi ko makumpirma ngayon, pero salamat sa pagtatanong.",
    },
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
            self.assertTrue(all(len(item["styles"][style]) == 1 for style in STYLES))

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
                self.assertEqual(generated, expected)
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
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredNeutral01",
                    "I'm hurt, but I'm managing.",
                ),
                "healthy": (
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyNeutral01",
                    "I'm doing okay.",
                ),
                "unknown": (
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownNeutral01",
                    "I can't confirm my health status right now.",
                ),
            },
            "TL": {
                "injured": (
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateInjuredNeutral01",
                    "Nasaktan ako, pero kinakaya ko.",
                ),
                "healthy": (
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateHealthyNeutral01",
                    "Ayos lang ako.",
                ),
                "unknown": (
                    "UI_PNC_Conversation_Content_SemanticQuestionHealthStateUnknownNeutral01",
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
                    self.assertEqual(turn["transport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
