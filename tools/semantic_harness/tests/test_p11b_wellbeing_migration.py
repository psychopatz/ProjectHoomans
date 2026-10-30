"""P11B Wellbeing wording-shard migration contracts."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
MANIFEST = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
WELLBEING_IDS = (
    "semantic.question.wellbeing.default",
    "semantic.question.wellbeing.injured",
    "semantic.question.wellbeing.panic",
    "semantic.question.wellbeing.stress",
    "semantic.question.wellbeing.thirst",
    "semantic.question.wellbeing.thirst_alt",
    "semantic.question.wellbeing.hunger",
    "semantic.question.wellbeing.hunger_alt",
    "semantic.question.wellbeing.fatigue",
    "semantic.question.wellbeing.fatigue_alt",
)
EXPECTED = {
    "EN": {
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByGuarded01": "I'm getting by. Leave it there.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByNeutral01": "I'm getting by, one day at a time. How about you?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByTerse01": "Getting by.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByWarm01": "I'm getting by. Thanks for asking.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultGuarded01": "I'm managing. Don't press me.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultNeutral01": "I'm okay. How about you?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultTerse01": "I'm okay.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultWarm01": "I'm doing okay. Thanks for asking.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingFatigueAltNeutral01": "I'm tired. A little rest would help.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingFatigueNeutral01": "I'm worn out, but I can still manage.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingHungerAltNeutral01": "I'm getting hungry. Could you spare something to eat?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingHungerNeutral01": "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredGuarded01": "I'm hurt. That's all I can say.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredNeutral01": "A little banged up, but I'll manage.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredTerse01": "I'm hurt. I can manage.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredWarm01": "I took a hit, but I'm steady enough to keep going.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingPanicNeutral01": "I'm pretty shaken up right now.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingStressNeutral01": "I'm tense, but I can keep going.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingThirstAltNeutral01": "I could really use a drink. Do you have any water?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingThirstNeutral01": "I'm pretty thirsty. Could you spare some water?"
    },
    "TL": {
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByGuarded01": "Kinakaya ko. Tama na iyon.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByNeutral01": "Kinakaya ko, isang araw bawat pagkakataon. Ikaw?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByTerse01": "Kinakaya.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDatasetGettingByWarm01": "Kinakaya ko. Salamat sa pagtatanong.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultGuarded01": "Kinakaya ko. Huwag mo nang ipilit.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultNeutral01": "Okay naman ako. Ikaw, kumusta?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultTerse01": "Ayos lang ako.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultWarm01": "Ayos lang ako. Salamat sa pagtatanong.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingFatigueAltNeutral01": "Pagod ako. Makakatulong ang kaunting pahinga.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingFatigueNeutral01": "Pagod na pagod ako, pero kaya ko pa.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingHungerAltNeutral01": "Nagugutom na ako. Maaari ba akong makahingi ng makakain?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingHungerNeutral01": "Medyo gutom ako, kung tutuusin. May makakain ka ba?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredGuarded01": "Nasaktan ako. Iyon lang ang masasabi ko.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredNeutral01": "Medyo may tama ako, pero kakayanin ko.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredTerse01": "Nasaktan ako. Kaya ko.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredWarm01": "Nasaktan ako, pero kaya ko pang magpatuloy.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingPanicNeutral01": "Nanginginig pa rin ako ngayon.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingStressNeutral01": "Tensiyonado ako, pero kaya ko pa.",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingThirstAltNeutral01": "Kailangan ko talaga ng maiinom. May tubig ka ba?",
        "UI_PNC_Conversation_Content_SemanticQuestionWellbeingThirstNeutral01": "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?"
    }
}
LEGACY_KEYS = {
    "UI_PNC_Conversation_Semantic_QuestionWellbeingDefault",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingInjured",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingPanic",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingStress",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingThirst",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingThirstAlt",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingHunger",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingHungerAlt",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigue",
    "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigueAlt",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingNeutral",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingWarm",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingTerse",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingGuarded",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingInjuredNeutral",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingInjuredWarm",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingInjuredTerse",
    "UI_PNC_Conversation_Semantic_RealizationWellbeingInjuredGuarded",
}


class WellbeingWordingShardTests(unittest.TestCase):
    def test_compiler_owns_wellbeing_families_by_wellbeing_shard(self) -> None:
        model = compile_conversation_sources(
            REPOSITORY, manifest_path=MANIFEST,
        )
        entry = next(
            shard for shard in model["shards"]
            if shard["path"] == "content/wellbeing.json"
        )
        self.assertEqual(entry["domain"], "wellbeing")
        self.assertEqual(
            {
                model["locations"]["phrase." + template_id]["sourceShard"]
                for template_id in WELLBEING_IDS
            },
            {"content/wellbeing.json"},
        )
        self.assertEqual(
            [
                family["semanticTemplateID"]
                for family in model["content"]["phraseFamilies"]
                if family["semanticTemplateID"] in WELLBEING_IDS
            ],
            sorted(WELLBEING_IDS),
        )

    def test_generated_wellbeing_translation_is_complete_and_legacy_keys_are_retired(
        self,
    ) -> None:
        for language, expected in EXPECTED.items():
            with self.subTest(language=language):
                generated = json.loads(
                    (
                        REPOSITORY
                        / f"Contents/mods/ProjectHoomans/common/media/translation/"
                        f"{language}/Conversation/Wellbeing.json"
                    ).read_text(encoding="utf-8")
                )
                self.assertEqual(generated, expected)
                for catalog_name in ("Responses", "Realizations"):
                    catalog = json.loads(
                        (
                            REPOSITORY
                            / f"Contents/mods/ProjectHoomans/common/media/translation/"
                            f"{language}/Conversation/Semantic/{catalog_name}.json"
                        ).read_text(encoding="utf-8")
                    )
                    self.assertTrue(LEGACY_KEYS.isdisjoint(catalog))

        wellbeing_source = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
            "SpeechRealization/Families/Status.lua"
        ).read_text(encoding="utf-8")
        self.assertNotIn("UI_PNC_Conversation_Semantic_RealizationWellbeing", wellbeing_source)
        key_map = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Semantics/"
            "PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Wellbeing.lua"
        ).read_text(encoding="utf-8")
        for template_id in WELLBEING_IDS:
            self.assertNotIn(template_id, key_map)

    def test_real_worker_preserves_wellbeing_identity_and_no_effects_in_en_tl(
        self,
    ) -> None:
        expected = {
            ("EN", "normal"): (
                "semantic.question.wellbeing.default",
                "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultNeutral01",
                "I'm okay. How about you?",
            ),
            ("TL", "normal"): (
                "semantic.question.wellbeing.default",
                "UI_PNC_Conversation_Content_SemanticQuestionWellbeingDefaultNeutral01",
                "Okay naman ako. Ikaw, kumusta?",
            ),
            ("EN", "injured"): (
                "semantic.question.wellbeing.injured",
                "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredNeutral01",
                "A little banged up, but I'll manage.",
            ),
            ("TL", "injured"): (
                "semantic.question.wellbeing.injured",
                "UI_PNC_Conversation_Content_SemanticQuestionWellbeingInjuredNeutral01",
                "Medyo may tama ako, pero kakayanin ko.",
            ),
        }
        for (language, health), contract in expected.items():
            with self.subTest(language=language, health=health):
                scenario = deepcopy(DEFAULT_SCENARIO)
                scenario["runtime"]["language"] = language
                scenario["npc"]["healthState"] = health
                scenario["npc"]["needs"] = {
                    "hunger": 0.05, "thirst": 0.05, "fatigue": 0.05,
                }
                scenario["npc"]["conditionStats"] = {
                    "stress": 0.0, "panic": 0.0, "boredom": 0.0,
                }
                with LuaSemanticWorker(scenario) as worker:
                    turn = worker.input("Are you okay?")
                self.assertTrue(turn["accepted"], turn.get("reason"))
                payload = turn["messages"][0]["payload"]
                self.assertEqual(payload["semanticTemplateID"], contract[0])
                self.assertEqual(payload["translationKey"], contract[1])
                self.assertEqual(payload["text"], contract[2])
                self.assertEqual(turn["dispatchTransport"], [])
                self.assertEqual(turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
