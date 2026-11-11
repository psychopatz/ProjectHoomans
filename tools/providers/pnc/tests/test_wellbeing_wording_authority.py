"""Wellbeing wording-shard migration contracts."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[4]
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
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.guarded.01": "I'm getting by. Leave it there.",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.neutral.01": "I'm getting by, one day at a time. How about you?",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.terse.01": "Getting by.",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.warm.01": "I'm getting by. Thanks for asking.",
        "conversation.content.semantic.question.wellbeing.default.guarded.01": "I'm managing. Don't press me.",
        "conversation.content.semantic.question.wellbeing.default.neutral.01": "I'm okay. How about you?",
        "conversation.content.semantic.question.wellbeing.default.terse.01": "I'm okay.",
        "conversation.content.semantic.question.wellbeing.default.warm.01": "I'm doing okay. Thanks for asking.",
        "conversation.content.semantic.question.wellbeing.fatigue_alt.neutral.01": "I'm tired. A little rest would help.",
        "conversation.content.semantic.question.wellbeing.fatigue.neutral.01": "I'm worn out, but I can still manage.",
        "conversation.content.semantic.question.wellbeing.hunger_alt.neutral.01": "I'm getting hungry. Could you spare something to eat?",
        "conversation.content.semantic.question.wellbeing.hunger.neutral.01": "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
        "conversation.content.semantic.question.wellbeing.injured.guarded.01": "I'm hurt. That's all I can say.",
        "conversation.content.semantic.question.wellbeing.injured.neutral.01": "A little banged up, but I'll manage.",
        "conversation.content.semantic.question.wellbeing.injured.terse.01": "I'm hurt. I can manage.",
        "conversation.content.semantic.question.wellbeing.injured.warm.01": "I took a hit, but I'm steady enough to keep going.",
        "conversation.content.semantic.question.wellbeing.panic.neutral.01": "I'm pretty shaken up right now.",
        "conversation.content.semantic.question.wellbeing.stress.neutral.01": "I'm tense, but I can keep going.",
        "conversation.content.semantic.question.wellbeing.thirst_alt.neutral.01": "I could really use a drink. Do you have any water?",
        "conversation.content.semantic.question.wellbeing.thirst.neutral.01": "I'm pretty thirsty. Could you spare some water?"
    },
    "TL": {
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.guarded.01": "Kinakaya ko. Tama na iyon.",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.neutral.01": "Kinakaya ko, isang araw bawat pagkakataon. Ikaw?",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.terse.01": "Kinakaya.",
        "conversation.content.semantic.question.wellbeing.dataset.getting_by.warm.01": "Kinakaya ko. Salamat sa pagtatanong.",
        "conversation.content.semantic.question.wellbeing.default.guarded.01": "Kinakaya ko. Huwag mo nang ipilit.",
        "conversation.content.semantic.question.wellbeing.default.neutral.01": "Okay naman ako. Ikaw, kumusta?",
        "conversation.content.semantic.question.wellbeing.default.terse.01": "Ayos lang ako.",
        "conversation.content.semantic.question.wellbeing.default.warm.01": "Ayos lang ako. Salamat sa pagtatanong.",
        "conversation.content.semantic.question.wellbeing.fatigue_alt.neutral.01": "Pagod ako. Makakatulong ang kaunting pahinga.",
        "conversation.content.semantic.question.wellbeing.fatigue.neutral.01": "Pagod na pagod ako, pero kaya ko pa.",
        "conversation.content.semantic.question.wellbeing.hunger_alt.neutral.01": "Nagugutom na ako. Maaari ba akong makahingi ng makakain?",
        "conversation.content.semantic.question.wellbeing.hunger.neutral.01": "Medyo gutom ako, kung tutuusin. May makakain ka ba?",
        "conversation.content.semantic.question.wellbeing.injured.guarded.01": "Nasaktan ako. Iyon lang ang masasabi ko.",
        "conversation.content.semantic.question.wellbeing.injured.neutral.01": "Medyo may tama ako, pero kakayanin ko.",
        "conversation.content.semantic.question.wellbeing.injured.terse.01": "Nasaktan ako. Kaya ko.",
        "conversation.content.semantic.question.wellbeing.injured.warm.01": "Nasaktan ako, pero kaya ko pang magpatuloy.",
        "conversation.content.semantic.question.wellbeing.panic.neutral.01": "Nanginginig pa rin ako ngayon.",
        "conversation.content.semantic.question.wellbeing.stress.neutral.01": "Tensiyonado ako, pero kaya ko pa.",
        "conversation.content.semantic.question.wellbeing.thirst_alt.neutral.01": "Kailangan ko talaga ng maiinom. May tubig ka ba?",
        "conversation.content.semantic.question.wellbeing.thirst.neutral.01": "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?"
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
                for key, val in expected.items():
                    self.assertEqual(generated.get(key), val)
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
                "conversation.content.semantic.question.wellbeing.default.neutral.01",
                "I'm okay. How about you?",
            ),
            ("TL", "normal"): (
                "semantic.question.wellbeing.default",
                "conversation.content.semantic.question.wellbeing.default.neutral.01",
                "Okay naman ako. Ikaw, kumusta?",
            ),
            ("EN", "injured"): (
                "semantic.question.wellbeing.injured",
                "conversation.content.semantic.question.wellbeing.injured.neutral.01",
                "A little banged up, but I'll manage.",
            ),
            ("TL", "injured"): (
                "semantic.question.wellbeing.injured",
                "conversation.content.semantic.question.wellbeing.injured.neutral.01",
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
